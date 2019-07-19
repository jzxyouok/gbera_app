import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../framework.dart';
import 'display_context.dart';

typedef RouteElementGetter = Widget Function(BuildContext context);
typedef DisplayGetter = Widget Function(DisplayContext context);
typedef DisplayBinder = Map<String, DisplayGetter> Function(
  IPortalInfo portalInfo,
);

typedef OnFrameworkInit = Future Function(
    Framework framework, BuildContext context);
typedef OnFrameworkExit = Future Function(Framework framework);

mixin IServiceProvider {
  getService(String name);
}

///系统目录，里面有已安装的应用和框架
mixin ISystemDir {
  PageInfo getPageInfo({
    String pagePath,
  });

  Map<String, Object> getAppInfo(String microapp);
  IPortalInfo getPortalInfo(PageInfo pageInfo);
  Future init();

}

mixin IAppInstaller {
  Future init();

  Future installApp(String appname);

  bool isInstalledApp(String appname);

  String getInstalledAppVersion(String appname);
}

mixin IDisplayContainer {
  DisplayGetter getDisplayGetter(PageInfo pageInfo);

  void addBinder(String theme, displays);
}
mixin IPortalInfo {
  Map<String,Object> getInfo();
  Map<String,Object> getUseStyle();
}

class PageInfo {
  String app;
  String display;
  String portal;
  String style;
  String micrositeHost;
  String micrositeToken;
  String url;

  PageInfo({
    this.app,
    this.display,
    this.portal,
    this.style,
    this.micrositeHost,
    this.micrositeToken,
    this.url,
  });
}
