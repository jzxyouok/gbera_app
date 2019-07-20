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

export 'src/display_context.dart';
export 'src/i_service.dart';

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
    _errorPage=errorPage;
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
    PageInfo pageInfo = _systemDir.getPageInfo(
      pagePath: settings.name,
    );
    if (pageInfo == null) {
      return null;
    }
    var displayGetter = _displayContainer.getDisplayGetter(pageInfo);
    if (displayGetter == null) {
      return null;
    }
    return MaterialPageRoute(
      settings: settings,
      builder: (BuildContext context) {
        DisplayContext displayContext = DisplayContext(
          site: this,
          context: context,
          pageInfo: pageInfo,
        );
        var display=displayGetter(displayContext);
        if(display==null)return null;
        return display;
      },
    );
  }

  Route onUnknownRoute(RouteSettings settings) {
    //如果页仍不存在，或者是对应的显示器不存在，则弹出404界面
    return MaterialPageRoute(
        settings: settings,
        builder: (BuildContext context) {
          return DefaultErrorPage(
            message: '404 请求的页不存在：${settings.name}',
          );
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
    await runZoned<Future<Null>>(() async {
      await _init(
        welcome: welcome,
      );

      await _runApp(
        onAfterRun: onAfterRun,
        onBeforeRun: onBeforeRun,
        welcome: welcome,
        taskbarTitle: taskbarTitle,
      );
    }, onError: (error, stackTrace) async {//它能拦截到启动app之前的错误
      print(error.toString());
      int pos=welcome.indexOf("://");
      String appname=welcome.substring(0,pos);
      runApp(ErrorPortal(
        taskbarTitle: appname,
        themeData: ThemeData.light(),
        errorPage: DefaultErrorPage(
          message: '${error.toString()}',
        ),
      ));
    });

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
    ThemeData themeData = _loadThemeData(welcome);
    //启动app
    NetosApp netosApp = NetosApp(
      taskbarTitle: taskbarTitle,
      welcome: welcome,
      framework: this,
      themeData: themeData,
      errorPage: errorPage==null?DefaultErrorPage():errorPage,
    );
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
    String portal = appinfo['portal'];
    pos = portal.indexOf("/");
    String name = portal.substring(0, pos);
    String version = portal.substring(pos + 1, portal.length);
    String style = appinfo['style'];
    if (StringUtil.isEmpty(style)) {
      var portalinfo = _systemDir.getPortalInfo(name, version);
      style = portalinfo['useStyle'];
    }
    var styleinfo = _systemDir.getStyleInfo(name, version, style);
    return MyThemeData.parseStyle(styleinfo);
  }


}
