import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../framework.dart';
import 'display_context.dart';

typedef RouteElementGetter = Widget Function(BuildContext context);
typedef DisplayGetter = Widget Function(DisplayContext context);
typedef DisplayBinder = Map<String, DisplayGetter> Function(
  IPortal portalInfo,
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
  bool isInstalledApp(String appname);
  emptySystemDir();

  Map<String, Object> getAppInfo(String microapp);

  IPortal getPortal(PageInfo pageInfo);

  Map<String, Object> getPortalInfo(name, version);

  Map<String, Object> getStyleInfo(name, version, style);

  Future init();
}

mixin IAppInstaller {
  Future init();

  Future installApp(String appname);
}

mixin IDisplayContainer {
  DisplayGetter getDisplayGetter(PageInfo pageInfo);

  void addBinder(String theme, displays);
}
mixin IPortal {
  Map<String, Object> getInfo();

  Map<String, Object> getUseStyle();
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

class Portal implements IPortal {
  String name;
  String version;
  String useStyle;
  var getStyleInfo;
  var getPortalInfo;

  IServiceProvider _site;

  Portal({
    IServiceProvider site,
    this.name,
    this.version,
    this.useStyle,
    this.getStyleInfo,
    this.getPortalInfo,
  }) {
    _site = site;
  }

  @override
  Map<String, Object> getUseStyle() {
    if (getStyleInfo != null) {
      return getStyleInfo(name, version, useStyle);
    }
    return null;
  }

  @override
  Map<String, Object> getInfo() {
    if (getPortalInfo != null) {
      return getPortalInfo(name, version);
    }
    return null;
  }
}
