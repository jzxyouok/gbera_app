library framework;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:yaml/yaml.dart';
import 'src/error_page.dart';
import 'src/i_service.dart';
import 'package:gbera_framework/src/updater_manager.dart';
import 'src/theme_cacher.dart';

typedef RouteElementGetter = Widget Function(BuildContext context);
typedef DisplayGetter = Widget Function(DisplayContext context);
typedef DisplayBinder = Map<String, DisplayGetter> Function(
  YamlMap theme,
);

class Framework implements IServiceProvider {
  static Framework _framework;
  IUpdateManager _updater;
  IThemeCacher _themeCacher;
  String remoteMicroappHost; //远程微应用配置服务器地址
  Dio dio;

  Framework() {
    _updater = UpdateManager(this);
    _themeCacher = ThemeCacher(this);

    BaseOptions options = BaseOptions(headers: {
      'Content-Type': "text/html; charset=utf-8",
    });
    dio = Dio(options); //使用base配置可以通用，包括共享token
  }

  @override
  getService(String name) {
    if ("@remote.updater" == name) {
      return '${this.remoteMicroappHost}/microapp/updateManager.service';
    }
    if ('@http' == name) {
      return dio;
    }
    if ('@rootBundle' == name) {
      return rootBundle;
    }
  }

  void themeBinder({String theme, DisplayBinder displays}) {
    if (theme.indexOf("/") < 0) {
      throw '微主题未带版本号，表示为：mytheme/1.0';
    }

    _themeCacher.cacheBinder(theme, displays);
  }

/*
  ///由于异步请求无法同步获取远程路由，因此该方法在调用处已被注释掉，不会被执行
  Map<String, RouteElementGetter> onOfficialMicroappRouters(
      BuildContext context, String welcome) {
    //为了主微应用页面间切换的性能考虑，在此方法中一次性初始化官方（app启动的第一个微应用）微应用的路由表：微应用页地址->display实例

    assert(!StringUtil.isEmpty(welcome));
    int pos = welcome.indexOf("://");
    dynamic microapp;
    if (pos < 0) {
      microapp = welcome;
    } else {
      microapp = welcome.substring(0, pos);
    }
    var _app; //它大爷的，不论什么方式都无法采用异步转同步，人家是真的异步架构，NB

//    var completer=Completer();
//    var f= completer.future;

    Future f = Future.sync(() {
      return Future.wait({
        _updater.getMicroApp(microapp, onsuccess: (app) {
          _app = app;
          print('----++---------------------------$_app');
        })
      });
    });
    print('-------------------------------$_app');
    MicroAppParser parser = MicroAppParser(_app);
    List<String> pathlist = parser.enumPagePath();
    Map<String, RouteElementGetter> map = Map();
    pathlist.forEach((path) {
      //查显示器
      Map<String, Object> page = parser.getPage(path);

      if (path == null) {
        return false;
      }
      var displayName = page['display'];
      String themefull = _app['theme'];

      var display = _themeCacher.getDisplay(themefull, displayName);
      if (display != null) {
        map[path] = (context) => display;
      }
      return true;
    });
    return map;
  }
*/
//return new MaterialPageRoute(builder: builder, settings: settings);
  Route onUnofficialMicroappRouters(RouteSettings settings) {
    //如果不存在则到网上查找页，如果网上仍没有则返回null，如果网上有则检查是否有display，如果没有display则返回null
    //懒加载模式，每次查找一个显示器绑定之

    var route = MaterialPageRoute(
      settings: settings,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: _getMicroPageLazy(context),
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

  _getMicroPageLazy(BuildContext context) async {
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

  ///初始化环境
  void initEnv({String remoteMicroappHost}) {
    this.remoteMicroappHost = remoteMicroappHost;
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
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
