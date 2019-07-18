library framework;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:gbera_framework/gbera_app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import 'src/error_page.dart';
import 'src/i_service.dart';
import 'package:gbera_framework/src/updater_manager.dart';
import 'src/theme_cacher.dart';
import 'src/util.dart';

typedef RouteElementGetter = Widget Function(BuildContext context);
typedef DisplayGetter = Widget Function(DisplayContext context);
typedef DisplayBinder = Map<String, DisplayGetter> Function(
  YamlMap theme,
);
typedef OnFrameworkInit = Future Function(
    Framework framework, BuildContext context);
typedef OnFrameworkExit = Future Function(Framework framework);

class Framework implements IServiceProvider {
  IUpdateManager _updater;
  IThemeCacher _themeCacher;
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
    void bindThemes(Framework framework),
  }) {
    if (StringUtil.isEmpty(remoteMicroappHost)) {
      throw '404 remoteMicroappHost Is Empty';
    }
    if (bindThemes == null) {
      throw '404 bindThemes Not Used.';
    }
    _remoteMicroappHost = remoteMicroappHost;
    _remoteMicroappToken = remoteMicroappToken;
    _clearCaches = clearCaches ? false : clearCaches;

    _updater = UpdateManager(this);
    _themeCacher = ThemeCacher(this);

    BaseOptions options = BaseOptions(headers: {
      'Content-Type': "text/html; charset=utf-8",
    });
    _dio = Dio(options); //使用base配置可以通用，包括共享token
    bindThemes(this); //执行绑定
  }

  @override
  getService(String name) {
    if ("@remote.updater" == name) {
      return '${this._remoteMicroappHost}/microapp/updateManager.service';
    }
    if ('@http' == name) {
      return _dio;
    }
    if ('@rootBundle' == name) {
      return rootBundle;
    }
    return _parent ?? _parent.getService(name);
  }

  void themeBinder({String theme, DisplayBinder displays}) {
    if (theme.indexOf("/") < 0) {
      throw '微主题未带版本号，表示为：mytheme/1.0';
    }

    _themeCacher.cacheBinder(theme, displays);
  }

//return new MaterialPageRoute(builder: builder, settings: settings);
  Route onGenerateMicroappRouters(RouteSettings settings) {
    //如果不存在则到网上查找页，如果网上仍没有则返回null，如果网上有则检查是否有display，如果没有display则返回null
    //懒加载模式，每次查找一个显示器绑定之
    var route = MaterialPageRoute(
      settings: settings,
      builder: (BuildContext context) {
        return FutureBuilder(
//          initialData: ,
          future: _getMicroDisplayLazy(context),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                //如果出错则显示错误页
                if (snapshot.hasError) {
                  return DefaultErrorPage(snapshot.error);
                }
                return snapshot.data;
              case ConnectionState.active:
              case ConnectionState.waiting:
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                          child: Text(
                              'Waiting ${ModalRoute.of(context).settings.name}'),
                        ),
                        CircularProgressIndicator(),
                      ],
                    ),
                  ),
                );
              case ConnectionState.none:
                //如果出错则显示错误页
                if (snapshot.hasError) {
                  return DefaultErrorPage(snapshot.error);
                }
                return Container(
                  child: Text('${snapshot.data}'),
                );
            }
            return null;
          },
        );
      },
    );

    return route;
  }

  _getMicroDisplayLazy(BuildContext context) async {
    var settings = ModalRoute.of(context).settings;
    var path = settings.name;
    int pos = path.indexOf("://");
    dynamic microapp;
    if (pos < 0) {
      microapp = path;
    } else {
      microapp = path.substring(0, pos);
    }
    dynamic _app;
    await _updater.getMicroApp(microapp, onsuccess: (app) {
      _app = app;
    }, onerror: (e) {
      throw '500 $e.';
    });
    if (_app == null) {
      throw '404 Not Microapp Found.';
    }
    _app['name'] = microapp;
    dynamic display;
    try {
      display = await _themeCacher.getDisplay(context, _app, path);
    } catch (e) {
      throw '$e';
    }
    if (display == null) {
      throw '404 Display Not Found.';
    }
    return display;
  }

  Route onUnknownRoute(RouteSettings settings) {
    //如果页仍不存在，或者是对应的显示器不存在，则弹出404界面
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

  onRenderTheme(BuildContext context) {
    var td = ThemeData(
      primarySwatch: Colors.green,
    );

    return td;
  }

  ///初始化环境
  runMicroAppOn(
      {String taskbarTitle,
      String welcome,
      onBeforeRun(Widget app),
      onAfterRun(Widget app)}) async {
    if (welcome.lastIndexOf("://") < 0) {
      throw '500 Welcome Not a Full Path.';
    }
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    if (_clearCaches) {
      await clearCaches();
    }
    YamlMap defaultStyleInfo = await _loadDefaultStyle(welcome);
    ThemeData themeData = _parseRootThemeData(defaultStyleInfo);
    //启动app
    NetosApp netosApp = NetosApp(
      taskbarTitle: taskbarTitle,
      welcome: welcome,
      framework: this,
      themeData: themeData,
    );
    this._parent = netosApp;
    if (onBeforeRun != null) {
      onBeforeRun(netosApp);
    }
    runApp(netosApp);
    if (onAfterRun != null) {
      onAfterRun(netosApp);
    }
    return this;
  }

  _loadDefaultStyle(String welcome) async {
    int pos = welcome.lastIndexOf("://");
    String appname = welcome.substring(0, pos);
    dynamic _app;
    await _updater.getMicroApp(appname, onsuccess: (app) {
      _app = app;
    }, onerror: (e) {
      throw '500 $e.';
    });
    if (_app == null) {
      throw '404 Not Microapp Found.';
    }
    String themefull = _app['theme'];
    String style = _app['style'];
    String theme;
    String version;
    pos = themefull.lastIndexOf("/");
    if (pos < 0) {
      theme = themefull;
      version = '1.0';
    } else {
      theme = themefull.substring(0, pos);
      version = themefull.substring(pos + 1, themefull.length);
    }
    YamlMap defaultStyleInfo =
        await _themeCacher.getDefaultStyle(theme, version, style);
    if (defaultStyleInfo == null) {
      throw '404 Default Style Info Not Found. ${appname}';
    }
    //转换为themeData
    return defaultStyleInfo;
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
      if(map==null)return null;
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

class DisplayContext {
  IServiceProvider _site;
  BuildContext _context;
  MicroSite _mcrosite;

  MicroApp _microapp;

  String _name;

  Map<String, DisplayMethod> _methods;
  Map<String, DisplayProperty> _properties;

  YamlMap _styleInfo;

  YamlMap get styleInfo => _styleInfo;

  String get name => _name;

  MicroSite get mcrosite => _mcrosite;

  MicroApp get microapp => _microapp;

  Map<String, DisplayMethod> get methods => _methods;

  Map<String, DisplayProperty> get properties => _properties;

  String path() {
    return ModalRoute.of(_context).settings.name;
  }

  Object arguments() {
    return ModalRoute.of(_context).settings.arguments;
  }

  void forward(String pagePath, {Object arguments}) {
    Navigator.pushNamed(_context, pagePath, arguments: arguments);
  }

  getService(String name) {
    return _site.getService(name);
  }

  DisplayContext.create(this._site, this._context,
      {Map<String, Object> app,
      microTheme,
      Map<String, Object> pageInfo,
      styleInfo,
      String displayName,
      displayInfo}) {
    _name = displayName;
    this._microapp = MicroApp(app);
    Map<String, Object> msite = pageInfo['microsite'];
    if (msite == null) {
      msite = app['microsite'];
    }
    _mcrosite = MicroSite(host: msite['host'], token: msite['token']);
    _styleInfo = styleInfo;

    YamlMap props = displayInfo['properties'];
    _properties = Map();
    if (props != null) {
      props.forEach((key, v) {
        YamlMap item = v;
        var prop = DisplayProperty(
            name: key, type: item['value-type'], usage: item['usage']);
        _properties[key] = prop;
      });
    }

    YamlMap methods = displayInfo['methods'];
    _methods = Map();
    if (methods != null) {
      methods.forEach((key, v) {
        YamlMap item = v;
        var prop = DisplayMethod(
          name: key,
          usage: item['usage'],
          command: item['command'],
          protocol: item['protocol'],
          returnType: item['return-type'],
          restHeader: _paseRestHeader(item['rest-header']),
          parameters: _paseMethodParameter(item['parameters']),
        );
        _methods[key] = prop;
      });
    }
  }

  _paseRestHeader(var restHeader) {
    if (restHeader == null) return null;
    YamlMap header = restHeader as YamlMap;
    return RestHeader(
      stubFace: header['Rest-StubFace'],
      command: header['Rest-Command'],
    );
  }

  _paseMethodParameter(var parameterMap) {
    if (parameterMap == null) return null;
    YamlMap parameters = parameterMap as YamlMap;
    Map<String, DisplayMethodParameter> map = Map();
    parameters.forEach((key, pobj) {
      var p = DisplayMethodParameter(
        name: key,
        usage: pobj['usage'],
        type: pobj['type'],
        inrequest: pobj['in-request'],
      );
      map[key] = p;
    });
    return map;
  }
}

class DisplayProperty {
  final String name;
  final String type;
  final String usage;

  const DisplayProperty({this.name, this.type, this.usage});
}

class DisplayMethod {
  final String name;
  final String command;
  final String protocol;
  final String usage;
  final String returnType;
  final RestHeader restHeader;
  final Map<String, DisplayMethodParameter> parameters;

  const DisplayMethod(
      {this.name,
      this.command,
      this.protocol,
      this.usage,
      this.returnType,
      this.restHeader,
      this.parameters});
}

class DisplayMethodParameter {
  final String name;
  final String type;
  final String usage;
  final String inrequest;

  const DisplayMethodParameter(
      {this.name, this.type, this.usage, this.inrequest});
}

class RestHeader {
  final String stubFace;
  final String command;

  const RestHeader({this.stubFace, this.command});
}

class MicroSite {
  final String host;
  final String token;

  const MicroSite({this.host, this.token});
}

class MicroApp {
  String name;
  String title;
  String desc;
  String developer;
  String from;
  String style;
  String home;
  String theme;

  MicroApp(Map<String, Object> app) {
    name = app['name'];
    title = app['title'];
    desc = app['desc'];
    developer = app['developer'];
    from = app['from'];
    home = app['home'];
    style = app['style'];
    theme = app['theme'];
  }
}
