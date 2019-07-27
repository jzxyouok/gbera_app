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

  MicroAppInfo getAppInfo(String microapp);

  IPortal getPortal(PageInfo pageInfo);

  MicroPortalInfo getPortalInfo(name, version);

  MicroStyleInfo getStyleInfo(name, version, style);

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
  MicroPortalInfo getInfo();

  MicroStyleInfo getUseStyle();
}

class PageInfo {
  String app;
  String display;
  String portal;
  String style;
  MicroSite microsite;
  String url;

  PageInfo({
    this.app,
    this.display,
    this.portal,
    this.microsite,
    this.style,
    this.url,
  });
}

class Portal implements IPortal {
  String name;
  String version;
  String useStyle;
  MicroStyleInfo Function(String, String, String) getStyleInfo;
  MicroPortalInfo Function(String, String) getPortalInfo;

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
  MicroStyleInfo getUseStyle() {
    if (getStyleInfo != null) {
      return getStyleInfo(name, version, useStyle);
    }
    return null;
  }

  @override
  MicroPortalInfo getInfo() {
    if (getPortalInfo != null) {
      return getPortalInfo(name, version);
    }
    return null;
  }
}

class MicroAppInfo {
  final String name;
  final String title;
  final String desc;
  final String developer;
  final String version;
  final String portal;
  final String style;
  final String home;
  final String error;
  final MicroSite microsite;
  Map<String, MicroDisplayPage> pages;

  MicroAppInfo({
    this.name,
    this.title,
    this.desc,
    this.developer,
    this.version,
    this.portal,
    this.style,
    this.home,
    this.error,
    this.microsite,
  }) {
    pages = Map();
  }
}

class MicroDisplayPage {
  final String display;
  final MicroSite microsite;

  const MicroDisplayPage({this.display, this.microsite});
}

class MicroSite {
  final String host;
  final String token;

  const MicroSite({this.host, this.token});
}

class MicroPortalInfo {
  final String name;
  final String version;
  final String title;
  final String desc;
  final String ctime;
  final String useStyle;
  final String developer;
  Map<String, dynamic> plugin;
  Map<String, MicroDisplayInfo> displays;
  Map<String, MicroStyleInfo> styles;

  MicroPortalInfo({
    this.name,
    this.version,
    this.title,
    this.desc,
    this.ctime,
    this.useStyle,
    this.developer,
  }) {
    styles = Map();
    displays = Map();
    plugin = Map();
  }
}

class MicroDisplayInfo {
  String name;
  Map<String, MicroDisplayMethod> methods;
  Map<String, MicroDisplayProperty> properties;

  MicroDisplayInfo({this.name}) {
    methods = Map();
    properties = Map();
  }
}

class MicroDisplayProperty {
  final String name;
  final String type;
  final String usage;

  MicroDisplayProperty({this.name, this.type, this.usage});
}

class MicroDisplayMethod {
  String name;
  String command;
  String protocol;
  String usage;
  String returnType;
  Map<String, MicroDisplayMethodParameter> parameters;
  MicroDisplayTokenInfo tokenInfo;

  MicroDisplayMethod({
    this.name,
    this.command,
    this.protocol,
    this.usage,
    this.returnType,
    this.tokenInfo,
  }) {
    parameters = Map();
  }
}

class MicroDisplayTokenInfo {
  String name;
  String inrequest;

  MicroDisplayTokenInfo(this.name, this.inrequest);
}

class MicroDisplayMethodParameter {
  final String name;
  final String type;
  final String usage;
  final String inRequest;

  const MicroDisplayMethodParameter(
      {this.name, this.type, this.usage, this.inRequest});
}

class MicroStyleInfo {
  final String name;
  final String title;
  final String desc;
  Map<String, Object> assets;
  Map<String, Object> colors;
  List<Object> fonts; //key是family名
  Map<String, Object> theme;

  MicroStyleInfo({
    this.name,
    this.title,
    this.desc,
  }) {
    assets = Map();
    colors = Map();
    fonts = List();
    theme = Map();
  }
}

class OpenportsException implements Exception {
  String message;
  int state;
  String cause;

  OpenportsException({
    this.message,
    this.state,
    this.cause,
  });

  @override
  String toString() {
    return "Openports [$state]: " +
        (message ?? "") +'\r\n'+
        (cause ?? "");
  }
}
