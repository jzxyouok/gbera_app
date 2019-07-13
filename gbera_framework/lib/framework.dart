library framework;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:gbera_framework/src/util.dart';
import 'src/error_page.dart';
import 'src/i_service.dart';
import 'package:gbera_framework/src/updater_manager.dart';
import 'src/theme_cacher.dart';
import 'dart:async';

typedef RouteElementGetter = Widget Function(BuildContext context);
typedef DisplayGetter = Widget Function(DisplayContext context);
typedef DisplayBinder = Map<String, DisplayGetter> Function(
  Map<String, Object> theme,
);

final framework = Framework.getFramework();

class Framework implements IServiceProvider {
  static Framework _framework;
  IUpdateManager _updater;
  IThemeCacher _themeCacher;
  String remoteMicroappHost; //远程微应用配置服务器地址
  Dio dio;

  BuildContext _context;

  Framework._() {
    _updater = UpdateManager(this);
    _themeCacher = ThemeCacher(this);

    BaseOptions options = BaseOptions(headers: {
      'Content-Type': "text/html; charset=utf-8",
    });
    dio = Dio(options); //使用base配置可以通用，包括共享token
  }

  factory Framework.getFramework() {
    if (_framework == null) {
      _framework = Framework._();
    }
    return _framework;
  }

  @override
  getService(String name) {
    if ("@remote.updater" == name) {
      return '${this.remoteMicroappHost}/microapp/updateManager.service';
    }
    if ('@http' == name) {
      return dio;
    }
  }

  ///页面跳转
  void forward(String pagePath, {Object arguments}) {
    Navigator.pushNamed(_context, pagePath, arguments: arguments);
  }

  void load({String path}) {}

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
                Map<String, Object> page = snapshot.data;

                DisplayContext displayContext =
                    DisplayContext(this, context, page);
                var display = _themeCacher.getDisplay(displayContext);
                return display;
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
                          child:
                              Text('${ModalRoute.of(context).settings.name}'),
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
    var _app;
    await _updater.getMicroApp(microapp, onsuccess: (app) {
      _app = app;
    }, onerror: (e) {
      throw '500 $e.';
    });
    if (_app == null) {
      throw '404 Not Microapp Found.';
    }
    MicroAppParser parser = MicroAppParser(_app);
    //查显示器
    Map<String, Object> page = parser.getPage(path);
    if (page == null) {
      throw '404 Not Page Found.';
    }
    page['theme'] = _app['theme'];
    return page;
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

class MicroAppParser {
  final Map<String, Object> app;

  MicroAppParser(this.app);

  List<String> enumPagePath() {
    String appname = app['name']?.toString();
    Map<String, Object> pages = app['pages'];
    List<String> list = List();
    pages.forEach((pt, value) {
      while (pt.startsWith("/")) {
        pt = pt.substring(1, pt.length);
      }
      String path = appname + '://' + pt;
      list.add(path);
    });
    return list;
  }

  Map<String, Object> getPage(String path) {
    int pos = path.indexOf("://");
    var relPage = '';
    if (pos > -1) {
      relPage = path.substring(pos + '://'.length - 1, path.length);
    }
    Map<String, Object> pages = app['pages'];
    return pages[relPage];
  }
}

class DisplayContext {
  final BuildContext context;
  final Map<String, Object> page;
  final IServiceProvider site;

  const DisplayContext(this.site, this.context, this.page);

  String path() {
    return ModalRoute.of(context).settings.name;
  }
  Object arguments(){
    return ModalRoute.of(context).settings.arguments;
  }
  void forward(String pagePath, {Object arguments}) {
    Navigator.pushNamed(context, pagePath, arguments: arguments);
  }
}
