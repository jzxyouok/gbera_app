import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../util.dart';
import 'i_service.dart';

class SystemDir implements ISystemDir {
  final IServiceProvider parent;
  String _homeDir;

  SystemDir(this.parent);

  @override
  init() async {
    Directory docDir = await getApplicationDocumentsDirectory();
    _homeDir = '${docDir.path}/system';
  }

  @override
  Map<String, Object> getAppInfo(String microapp) {
    var dir = Directory("$_homeDir/apps/$microapp");
    if (!dir.existsSync()) {
      throw ('404 应用不存在。$microapp');
    }
    File f = File("${dir.path}/app.json");
    if (!f.existsSync()) {
      throw ('404 应用缺少配置文件。${f.path}');
    }
    var text = f.readAsStringSync();
    return json.decode(text);
  }

  @override
  PageInfo getPageInfo({String pagePath}) {
    var path = pagePath;
    int pos = path.indexOf("://");
    if (pos < 0) {
      throw ('500 请求地址格式错误，不是页的全路径地址。$path');
    }
    String microapp = path.substring(0, pos);
    String page = path.substring(pos + 2, path.length);

    Map<String, Object> app = getAppInfo(microapp);
    if (app == null||app.isEmpty) {
      throw ('404 未发现应用。$microapp');
    }
    Map<String, Object> pages = app['pages'];
    if (pages == null||pages.isEmpty) {
      throw ('404 应用中没有页配置。$microapp');
    }
    Map<String, Object> pageProps = pages[page];
    if (pageProps == null||pageProps.isEmpty) {
      throw ('404 页不存在。$pagePath');
    }
    String display = pageProps['display'];
    Map<String, Object> microsite = pageProps['microsite'];
    if (microsite == null||microsite.isEmpty) {
      microsite = app['microsite'];
    }
    if (microsite == null||microsite.isEmpty) {
      throw '404 缺少microsite配置。$pagePath';
    }
    String micrositeHost = microsite['host'];
    String micrositeToken = microsite['token'];

    return PageInfo(
      app: microapp,
      display: display,
      micrositeHost: micrositeHost,
      micrositeToken: micrositeToken,
      portal: app['portal'],
      style: app['style'],
      url: page,
    );
  }
  @override
  IPortal getPortal(PageInfo pageInfo) {
    String portal = pageInfo.portal;
    int pos = portal.indexOf("/");
    String name = portal.substring(0, pos);
    String version = portal.substring(pos + 1, portal.length);
    return Portal(
      site: parent,
      name: name,
      version: version,
      useStyle: pageInfo.style,
      getPortalInfo: getPortalInfo,
      getStyleInfo: getStyleInfo,
    );
  }

  @override
  bool isInstalledApp(String appname) {
    var dir = Directory("$_homeDir/apps/$appname");
    if (!dir.existsSync()) {
      return false;
    }
    File f = File("${dir.path}/app.json");
    if (!f.existsSync()) {
      return false;
    }
    return true;
  }

  @override
  Map<String, Object> getPortalInfo(name, version) {
    var dir = Directory("$_homeDir/portals/$name");
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File f = File("${dir.path}/portal-$version.json");
    if (!f.existsSync()) {
      throw ('404 未发现框架配置。${f.path}');
    }
    String text = f.readAsStringSync();
    return json.decode(text);
  }
  @override
  Map<String, Object> getStyleInfo(name, version, style) {
    Map<String, Object> info = getPortalInfo(name, version);
    if (info == null) return null;
    String useStyle = style;
    if(StringUtil.isEmpty(useStyle)){
      useStyle=info['useStyle'];
    }
    Map<String, Object> styles = info['styles'];
    return styles[useStyle];
  }
  @override
  emptySystemDir(){
    var dir = Directory("$_homeDir");
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}

