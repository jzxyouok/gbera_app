library framework;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gbera_framework/src/netos_app.dart';
import 'package:path_provider/path_provider.dart';
import 'src/app_installer.dart';
import 'src/display_context.dart';
import 'src/error_page.dart';
import 'src/i_service.dart';
import 'src/system_dir.dart';
import 'src/display_container.dart';
import 'package:gbera_framework/util.dart';

import 'src/theme_data.dart';

export 'util.dart';
export 'src/display_context.dart';
export 'src/i_service.dart';
export 'src/error_page.dart';

class Framework implements IServiceProvider {
  IAppInstaller _installer;
  ISystemDir _systemDir;
  IDisplayContainer _displayContainer;
  String _remoteMicroappHost; //远程微应用配置服务器地址
  String _remoteMicroappToken;
  Dio _dio;
  IServiceProvider _parent;
  bool _isEmptySystemDir;
  Widget _errorPage;
  BeforeErrorState _beforeErrorState; //启动app前发生错误，该错误会留到加载完主页后显示。

  Widget get errorPage => _errorPage;

  String get remoteMicroappHost => _remoteMicroappHost;

  String get remoteMicroappToken => _remoteMicroappToken;

  Framework({
    String remoteMicroappHost,
    String remoteMicroappToken,
    Widget errorPage,
    bool isEmptySystemDir,
    void bindPortals(Framework framework),
  }) {
    if (StringUtil.isEmpty(remoteMicroappHost)) {
      throw '404 remoteMicroappHost Is Empty';
    }
    if (bindPortals == null) {
      throw '404 bindThemes Not Used.';
    }
    _remoteMicroappHost = remoteMicroappHost;
    _remoteMicroappToken = remoteMicroappToken;
    _isEmptySystemDir = isEmptySystemDir == null ? false : isEmptySystemDir;
    _errorPage = errorPage;
    _installer = AppInstaller(this);
    _systemDir = SystemDir(this);
    _displayContainer = DisplayContainer(this);
    BaseOptions options = BaseOptions(headers: {
      'Content-Type': "text/html; charset=utf-8",
    });
    _dio = Dio(options); //使用base配置可以通用，包括共享token
    bindPortals(this); //执行绑定
  }

  @override
  getService(String name) {
    if ("@remote.searcher" == name) {
      return '${this._remoteMicroappHost}/microapp/searcher.service';
    }
    if ('@http' == name) {
      return _dio;
    }
    if ('@rootBundle' == name) {
      return rootBundle;
    }
    if ('@systemDir' == name) {
      return _systemDir;
    }
    return _parent ?? _parent.getService(name);
  }

  void portalBinder({String portal, DisplayBinder displays}) {
    if (portal.indexOf("/") < 0) {
      throw '微主题未带版本号，表示为：myportal/1.0';
    }

    _displayContainer.addBinder(portal, displays);
  }

//return new MaterialPageRoute(builder: builder, settings: settings);
  Route onGenerateMicroappRouters(RouteSettings settings) {
    if (_beforeErrorState != null) {
      //如果在启动前有错误，则显示错误页
      RouteSettings errorsettings = RouteSettings(
        name: settings.name,
        isInitialRoute: false,
        arguments: {'error': _beforeErrorState.exception.toString()},
      );
      _beforeErrorState = null;
      return MaterialPageRoute(
        settings: errorsettings,
        builder: (BuildContext context) {
          return errorPage != null ? errorPage : DefaultErrorPage();
        },
      );
    }
    try {
      PageInfo pageInfo = _systemDir.getPageInfo(
        pagePath: settings.name,
      );
      if (pageInfo == null) {
        throw '404 未发现页';
      }
      dynamic displayGetter = _displayContainer.getDisplayGetter(pageInfo);
      if (displayGetter == null) {
        throw '404 未发现显示获取器';
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (BuildContext context) {
          DisplayContext displayContext = DisplayContext(
            site: this,
            context: context,
            pageInfo: pageInfo,
          );
          var display = displayGetter(displayContext);
          if (display == null) {
            throw '500 获取显示器实例失败';
          }
          return display;
        },
      );
    } catch (e, stack) {
      var error = FlutterErrorDetails(exception: e, stack: stack);
      FlutterError.reportError(error);
      //注释掉原因是让错误页直接接收的就是From页的RouteSettings即可
      RouteSettings errorsettings = RouteSettings(
        name: settings.name,
        isInitialRoute: false,
        arguments: {'error': e.toString()},
      );
      return MaterialPageRoute(
        settings: errorsettings,
        builder: (BuildContext context) {
          Widget _errorPage;
          String microapp =
              settings.name.substring(0, settings.name.indexOf("://"));
          var appinfo = _systemDir.getAppInfo(microapp);
          if (appinfo != null) {
            String errorConfPage = appinfo.error;
            if (!StringUtil.isEmpty(errorConfPage)) {
              try {
                PageInfo pageInfo = _systemDir.getPageInfo(
                  pagePath: '$microapp:/$errorConfPage',
                );
                DisplayContext displayContext = DisplayContext(
                  site: this,
                  context: context,
                  pageInfo: pageInfo,
                );
                dynamic displayGetter = _displayContainer.getDisplayGetter(
                    pageInfo);
                _errorPage = displayGetter(displayContext);
              }catch(e,stack){
                var error = FlutterErrorDetails(exception: e, stack: stack);
                FlutterError.reportError(error);
                _errorPage = DefaultErrorPage();
              }
            }
          }
          if (_errorPage == null) {
            _errorPage = errorPage;
          }
          if (_errorPage == null) {
            _errorPage = DefaultErrorPage();
          }
          return _errorPage;
        },
      );
    }
  }

  Route onUnknownRoute(RouteSettings settings) {
    //如果页仍不存在，或者是对应的显示器不存在，则弹出404界面
    RouteSettings errorsettings = RouteSettings(
      name: settings.name,
      isInitialRoute: false,
      arguments: {'error': '404 请求的页不存在'},
    );
    var details = FlutterErrorDetails(exception: '404 请求的页不存在');
    FlutterError.reportError(details);
    return MaterialPageRoute(
        settings: errorsettings,
        builder: (BuildContext context) {
          return DefaultErrorPage();
        });
  }

  ///初始化环境
  runMicroAppOn({
    String taskbarTitle,
    String welcome,
    onBeforeRun(Widget app),
    onAfterRun(Widget app),
  }) async {
    if (welcome.lastIndexOf("://") < 0) {
      throw '500 Welcome Not a Full Path.';
    }
    try {
      await _init(
        welcome: welcome,
      );
    } catch (e, stack) {
      FlutterErrorDetails details =
          FlutterErrorDetails(exception: e, stack: stack);
      FlutterError.reportError(details);
      _beforeErrorState = BeforeErrorState(exception: e, stackTrace: stack);
    }
    await _runApp(
      onAfterRun: onAfterRun,
      onBeforeRun: onBeforeRun,
      welcome: welcome,
      taskbarTitle: taskbarTitle,
    );

    return this;
  }

  _init({String welcome}) async {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }

    await _systemDir.init();
    if (_isEmptySystemDir) {
      _systemDir.emptySystemDir();
    }
    await _installer.init();
    int pos = welcome.indexOf("://");
    String appname = welcome.substring(0, pos);
    if (!_systemDir.isInstalledApp(appname)) {
      await _installer.installApp(appname);
    }
  }

  _runApp({
    String welcome,
    String taskbarTitle,
    onBeforeRun(Widget app),
    onAfterRun(Widget app),
  }) async {
    NetosApp netosApp = null;
    if (_beforeErrorState == null) {
      ThemeData themeData = _loadThemeData(welcome);
      //启动app
      netosApp = NetosApp(
        taskbarTitle: taskbarTitle,
        welcome: welcome,
        framework: this,
        themeData: themeData,
      );
    } else {
      //启动app
      netosApp = NetosApp(
        taskbarTitle: taskbarTitle,
        welcome: welcome,
        framework: this,
      );
    }
    this._parent = netosApp;
    if (onBeforeRun != null) {
      onBeforeRun(netosApp);
    }
    runApp(netosApp);
    if (onAfterRun != null) {
      onAfterRun(netosApp);
    }
  }

  ThemeData _loadThemeData(String welcome) {
    int pos = welcome.indexOf("://");
    String microapp = welcome.substring(0, pos);
    var appinfo = _systemDir.getAppInfo(microapp);
    if (appinfo == null) {
      throw '404 应用不存在：$microapp';
    }
    String portal = appinfo.portal;
    pos = portal.indexOf("/");
    String name = portal.substring(0, pos);
    String version = portal.substring(pos + 1, portal.length);
    String style = appinfo.style;
    if (StringUtil.isEmpty(style)) {
      var portalinfo = _systemDir.getPortalInfo(name, version);
      style = portalinfo.useStyle;
    }
    var styleinfo = _systemDir.getStyleInfo(name, version, style);
    return MyThemeData.parseStyle(styleinfo);
  }
}
