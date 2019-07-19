library framework;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gbera_framework/src/gbera_app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import 'src/app_installer.dart';
import 'src/display_context.dart';
import 'src/i_service.dart';
import 'src/system_dir.dart';
import 'src/display_container.dart';
import 'package:gbera_framework/util.dart';

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
  bool _clearCaches;

  String get remoteMicroappHost => _remoteMicroappHost;

  String get remoteMicroappToken => _remoteMicroappToken;

  Framework({
    String remoteMicroappHost,
    String remoteMicroappToken,
    bool clearCaches,
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
    _clearCaches = clearCaches ? false : clearCaches;

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
        return displayGetter(displayContext);
      },
    );
  }

  Route onUnknownRoute(RouteSettings settings) {
    //如果页仍不存在，或者是对应的显示器不存在，则弹出404界面
    print("...不存在页：" + settings.name);
    return null;
  }

  clearCaches() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String apphomeDir = '${appDocDir.path}/apps';
    Directory dir = Directory(apphomeDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
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

    await _oninit(
      welcome: welcome,
    );

    await _runApp(
      onAfterRun: onAfterRun,
      onBeforeRun: onBeforeRun,
      welcome: welcome,
      taskbarTitle: taskbarTitle,
    );

    return this;
  }

  _oninit({String welcome}) async {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    if (_clearCaches) {
      await clearCaches();
    }
    await _installer.init();
    int pos = welcome.indexOf("://");
    String appname = welcome.substring(0, pos);
    await _installer.installApp(appname);
    await _systemDir.init();
  }

  _runApp({
    String welcome,
    String taskbarTitle,
    onBeforeRun(Widget app),
    onAfterRun(Widget app),
  }) async {
//    YamlMap defaultStyleInfo = await _loadDefaultStyle(welcome);
//    ThemeData themeData = _parseRootThemeData(defaultStyleInfo);
    //启动app
    NetosApp netosApp = NetosApp(
      taskbarTitle: taskbarTitle,
      welcome: welcome,
      framework: this,
//      themeData: themeData,
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

  ThemeData _parseRootThemeData(YamlMap defaultStyleInfo) {
    YamlMap theme = defaultStyleInfo['theme'];
    if (theme == null) return null;

    getColorByHex(String styleItem, String text) {
      if (StringUtil.isEmpty(text)) {
        return null;
      }
      if (!text.startsWith("#") && !text.startsWith("0x")) {
        debugPrint('主题：$styleItem 的定义即不是以#开头也不是以0x开头，请求单引号包括');
        return null;
      }
      while (text.startsWith("#")) {
        text = text.substring(1, text.length);
      }
      while (text.startsWith("0x")) {
        text = text.substring(2, text.length);
      }
      var intcolor = int.parse(text, radix: 16);
      return Color(intcolor);
    }

    getMaterialColor(String styleItem, YamlMap map) {
      if (map == null) return null;
      dynamic py = map['primary'];
      py = py == null ? null : '$py';
      var primary = getColorByHex(styleItem, py);
      YamlList swatchs = map['swatchs'];
      Map<int, Color> mc = Map();
      swatchs.forEach((item) {
        YamlMap obj = item as YamlMap;
        obj.forEach((key, v) {
          String text = v == null ? null : '$v';
          var c = getColorByHex(styleItem, text);
          if (c != null) {
            mc[key] = c;
          }
        });
      });

      return MaterialColor(primary.value, mc);
    }

    getIconThemeData(String styleItem, YamlMap map) {
      if (map == null) return null;
      return IconThemeData(
        color: getColorByHex(styleItem, map['color']),
        opacity: map['opacity'],
        size: map['size'],
      );
    }

    return ThemeData(
      backgroundColor:
          getColorByHex('backgroundColor', theme['backgroundColor']),
      accentColor: getColorByHex('accentColor', theme['accentColor']),
      accentColorBrightness: theme['accentColorBrightness'] == null
          ? null
          : () {
              switch (theme['accentColorBrightness']) {
                case 'dark':
                  return Brightness.dark;
                case 'light':
                  return Brightness.light;
              }
              return null;
            }(),
      accentIconTheme:
          getIconThemeData('accentIconTheme', theme['accentIconTheme']),
      bottomAppBarColor:
          getColorByHex('bottomAppBarColor', theme['bottomAppBarColor']),
      brightness: theme['brightness'] == null
          ? null
          : () {
              switch (theme['brightness']) {
                case 'dark':
                  return Brightness.dark;
                case 'light':
                  return Brightness.light;
              }
              return null;
            }(),
      buttonColor: getColorByHex('buttonColor', theme['buttonColor']),
      canvasColor: getColorByHex('canvasColor', theme['canvasColor']),
      cardColor: getColorByHex('cardColor', theme['cardColor']),
      cursorColor: getColorByHex('cursorColor', theme['cursorColor']),
      dialogBackgroundColor: getColorByHex(
          'dialogBackgroundColor', theme['dialogBackgroundColor']),
      disabledColor: getColorByHex('disabledColor', theme['disabledColor']),
      dividerColor: getColorByHex('dividerColor', theme['dividerColor']),
      errorColor: getColorByHex('errorColor', theme['errorColor']),
      focusColor: getColorByHex('focusColor', theme['focusColor']),
      fontFamily: theme['fontFamily'],
      highlightColor: getColorByHex('highlightColor', theme['highlightColor']),
      hintColor: getColorByHex('hintColor', theme['hintColor']),
      hoverColor: getColorByHex('hoverColor', theme['hoverColor']),
      indicatorColor: getColorByHex('indicatorColor', theme['indicatorColor']),
      platform: theme['platform'] == null
          ? null
          : () {
              switch (theme['platform']) {
                case 'android':
                  return TargetPlatform.android;
                case 'ios':
                  return TargetPlatform.iOS;
                case 'fuchsia':
                  return TargetPlatform.fuchsia;
              }
              return null;
            }(),
      primaryColor: getColorByHex('primaryColor', theme['primaryColor']),
      primaryColorBrightness: theme['primaryColorBrightness'] == null
          ? null
          : () {
              switch (theme['primaryColorBrightness']) {
                case 'dark':
                  return Brightness.dark;
                case 'light':
                  return Brightness.light;
              }
              return null;
            }(),
      primaryColorDark:
          getColorByHex('primaryColorDark', theme['primaryColorDark']),
      primaryColorLight:
          getColorByHex('primaryColorLight', theme['primaryColorLight']),
      primarySwatch: getMaterialColor('primarySwatch', theme['primarySwatch']),
      scaffoldBackgroundColor: getColorByHex(
          'scaffoldBackgroundColor', theme['scaffoldBackgroundColor']),
      secondaryHeaderColor:
          getColorByHex('secondaryHeaderColor', theme['secondaryHeaderColor']),
      selectedRowColor:
          getColorByHex('selectedRowColor', theme['selectedRowColor']),
      splashColor: getColorByHex('splashColor', theme['splashColor']),
      textSelectionColor:
          getColorByHex('textSelectionColor', theme['textSelectionColor']),
      textSelectionHandleColor: getColorByHex(
          'textSelectionHandleColor', theme['textSelectionHandleColor']),
      textTheme: theme['textTheme'],
      toggleableActiveColor: getColorByHex(
          'toggleableActiveColor', theme['toggleableActiveColor']),
      unselectedWidgetColor: getColorByHex(
          'unselectedWidgetColor', theme['unselectedWidgetColor']),
    );
  }
}
