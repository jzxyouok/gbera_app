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
  MicroAppInfo getAppInfo(String microapp) {
    var dir = Directory("$_homeDir/apps/$microapp");
    if (!dir.existsSync()) {
      throw ('404 应用不存在。$microapp');
    }
    File f = File("${dir.path}/app.json");
    if (!f.existsSync()) {
      throw ('404 应用缺少配置文件。${f.path}');
    }
    var text = f.readAsStringSync();
    Map<String, Object> map = json.decode(text);
    Map<String, Object> mapsite = map['microsite'];
    MicroSite microSite;
    if (mapsite != null) {
      microSite = MicroSite(
        host: mapsite['host'],
        token: mapsite['token'],
      );
    }
    MicroAppInfo info = MicroAppInfo(
      portal: map['portal'],
      style: map['style'],
      title: map['title'],
      name: map['name'],
      desc: map['desc'],
      developer: map['developer'],
      error: map['error'],
      home: map['home'],
      microsite: microSite,
      version: map['version'],
    );
    Map<String, Object> mpages = map['pages'];
    if (mpages != null) {
      mpages.forEach((path, v) {
        Map<String, Object> pageobj = v;
        Map<String, Object> msite = pageobj['microsite'];
        MicroSite site;
        if (msite != null) {
          site = MicroSite(host: msite['host'], token: msite['token']);
        }
        MicroDisplayPage page = MicroDisplayPage(
          microsite: site,
          display: pageobj['display'],
        );
        info.pages[path] = page;
      });
    }
    return info;
  }

  @override
  PageInfo getPageInfo({String pagePath}) {
    var path = pagePath;
    int pos = path.indexOf("://");
    if (pos < 0) {
      throw ('500 请求地址格式错误，不是页的全路径地址。$path');
    }
    String microapp = path.substring(0, pos);
    String pageUrl = path.substring(pos + 2, path.length);

    var app = getAppInfo(microapp);
    if (app == null) {
      throw ('404 未发现应用。$microapp');
    }
    Map<String, MicroDisplayPage> pages = app.pages;
    if (pages == null || pages.isEmpty) {
      throw ('404 应用中没有页配置。$microapp');
    }
    MicroDisplayPage page = pages[pageUrl];
    if (page == null) {
      throw ('404 页不存在。$pagePath');
    }
    String display = page.display;
    MicroSite microsite = page.microsite;
    if (microsite == null) {
      microsite = app.microsite;
    }
    if (microsite == null) {
      throw '404 缺少microsite配置。$pagePath';
    }

    return PageInfo(
      app: microapp,
      display: display,
      microsite: microsite,
      portal: app.portal,
      style: app.style,
      url: pageUrl,
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
  MicroPortalInfo getPortalInfo(name, version) {
    var dir = Directory("$_homeDir/portals/$name");
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File f = File("${dir.path}/portal-$version.json");
    if (!f.existsSync()) {
      throw ('404 未发现框架配置。${f.path}');
    }
    String text = f.readAsStringSync();
    Map<String, Object> map = json.decode(text);
    var info = MicroPortalInfo(
      version: map['version'],
      developer: map['developer'],
      desc: map['desc'],
      name: map['name'],
      title: map['title'],
      useStyle: map['useStyle'],
      ctime: map['ctime'],
    );
    Map<String, Object> mstyles = map['styles'];
    if (mstyles != null) {
      mstyles.forEach((styleName, v) {
        Map<String, Object> mstyle = v;
        var style = MicroStyleInfo(
          title: mstyle['title'],
          name: styleName,
          desc: mstyle['desc'],
        );
        style.assets = mstyle['assets'];
        style.colors = mstyle['colors'];
        style.fonts = mstyle['fonts'];
        style.theme = mstyle['theme'];
        info.styles[styleName] = style;
      });
    }
    Map<String, Object> mdisplays = map['displays'];
    if (mdisplays != null) {
      mdisplays.forEach((displayName, v) {
        Map<String, Object> mdisplay = v;
        var display = MicroDisplayInfo(name: displayName);
        Map<String, Object> mprops = mdisplay['properties'];
        if (mprops != null) {
          mprops.forEach((propName, propInfo) {
            Map<String, Object> mpropInfo = propInfo;
            var prop = MicroDisplayProperty(
              name: propName,
              type: mpropInfo['value-type'],
              usage: mpropInfo['usage'],
            );
            display.properties[propName] = prop;
          });
        }
        Map<String, Object> mmethods = mdisplay['methods'];
        if (mmethods != null) {
          mmethods.forEach((methodName, methodV) {
            Map<String, Object> mMethodInfo = methodV;
            Map<String, Object> mtoken = mMethodInfo['token'];
            var method = MicroDisplayMethod(
              name: methodName,
              usage: mMethodInfo['usage'],
              command: mMethodInfo['command'],
              returnType: mMethodInfo['return-type'],
              protocol: mMethodInfo['protocol'],
              tokenInfo: MicroDisplayTokenInfo(
                mtoken['name']??mtoken['name'],
                mtoken['in-request']??mtoken['in-request'],
              ),
            );
            Map<String, Object> mparameters = mMethodInfo['parameters'];
            if (mparameters != null) {
              mparameters.forEach((pname, pv) {
                Map<String, Object> mpv = pv;
                var p = MicroDisplayMethodParameter(
                  usage: mpv['usage'],
                  name: pname,
                  type: mpv['type'],
                  inRequest: mpv['in-request'],
                );
                method.parameters[pname] = p;
              });
            }
            display.methods[methodName] = method;
          });
        }
        info.displays[displayName] = display;
      });
    }
    info.plugin = map['plugin'];
    return info;
  }

  @override
  MicroStyleInfo getStyleInfo(name, version, style) {
    MicroPortalInfo info = getPortalInfo(name, version);
    if (info == null) return null;
    String useStyle = style;
    if (StringUtil.isEmpty(useStyle)) {
      useStyle = info.useStyle;
    }
    Map<String, MicroStyleInfo> styles = info.styles;
    return styles[useStyle];
  }

  @override
  emptySystemDir() {
    var dir = Directory("$_homeDir");
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}
