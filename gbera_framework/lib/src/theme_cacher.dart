import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../framework.dart';
import 'i_service.dart';
import 'package:yaml/yaml.dart';

import 'util.dart';

mixin IThemeCacher {
  getDisplay(
      BuildContext context, Map<String, Object> app, String path) async {}

  void cacheBinder(String theme, displays) {}
}

class ThemeCacher implements IThemeCacher {
  final IServiceProvider parent;
  Map<String, DisplayBinder> _binders;
  Map<String, Object> _displayGetters;

  ThemeCacher(this.parent) {
    this._binders = Map();
    _displayGetters = Map();
  }

  @override
  getDisplay(
      BuildContext _context, Map<String, Object> app, String path) async {
    MicroAppParser parser = MicroAppParser(app);
    //查显示器
    Map<String, Object> pageInfo = parser.getPage(path);
    if (pageInfo == null) {
      throw '404 Not Page Found.';
    }
    String themefull = app['theme'];
    String displayName = pageInfo['display'];
    String style = pageInfo['style'];
    String theme;
    String version;
    int pos = themefull.lastIndexOf("/");
    if (pos > -1) {
      theme = theme = themefull.substring(0, pos);
      version = themefull.substring(pos + 1, themefull.length);
    } else {
      theme = themefull;
    }
    //将显器示绑定到主题
    var microTheme = await _getThemeInfo(theme, version);
    if (microTheme == null) {
      throw '404 MicroTheme Not Found.';
    }
    var styleInfo = await _getStyleInfo(theme, version, style);
    if (styleInfo == null) {
      throw '404 MicroStyle Not Found.';
    }
    var displayInfo = await _getDisplayInfo(theme, version, displayName);
    if (displayInfo == null) {
      throw '404 MicroDisplay Not Found.';
    }
    pos = displayName.lastIndexOf("@");
    String dname = '';
    if (pos < 0) {
      dname = displayName;
    } else {
      dname = displayName.substring(0, pos);
    }
    DisplayContext context = DisplayContext.create(
      this.parent,
      _context,
      app: app,
      microTheme: microTheme,
      pageInfo: pageInfo,
      displayName:dname,
      styleInfo: styleInfo,
      displayInfo: displayInfo,
    );

    Map<String, DisplayGetter> cachedDisplayGetters =
        _displayGetters[themefull];
    if (cachedDisplayGetters != null) {
      var display = cachedDisplayGetters[dname];
      return display(context);
    }

    var binder = this._binders[themefull];
    if (binder == null) {
      throw '404 MicroTheme Binder Not Found for ${themefull}';
    }
    Map<String, DisplayGetter> displayGetters = binder(microTheme);
    _displayGetters[themefull] = displayGetters;

    var display = displayGetters[dname];
    return display(context);
  }

  @override
  void cacheBinder(String theme, displays) {
    _binders[theme] = displays;
  }

  _getThemeInfo(String theme, String version) async {
    AssetBundle rootBundle = parent.getService("@rootBundle");

    var themeYaml = 'lib/src/themes/${theme}/theme.yaml';
    dynamic themeYamlText = await rootBundle.loadString(themeYaml);
    YamlMap themeInfo = loadYaml(themeYamlText);

    return themeInfo;
  }

  _getStyleInfo(String theme, String version, String style) async {
    AssetBundle rootBundle = parent.getService("@rootBundle");
    String selectStyle = style;
    if (StringUtil.isEmpty(selectStyle)) {
      selectStyle = style;
      if (StringUtil.isEmpty(selectStyle)) {
        var defaultStyleYaml =
            "lib/src/themes/${theme}/versions/v-${version}/default_style.yaml";
        dynamic defaultStyleYamlText =
            await rootBundle.loadString(defaultStyleYaml);
        YamlMap defaultStyleInfo = loadYaml(defaultStyleYamlText);
        selectStyle = defaultStyleInfo['default'];
      }
      if (StringUtil.isEmpty(selectStyle)) {
        throw '500 Not Select Style.';
      }
    }

    var selectStyleYaml =
        "lib/src/themes/${theme}/versions/v-${version}/styles/${selectStyle}.yaml";
    dynamic selectStyleYamlText = await rootBundle.loadString(selectStyleYaml);
    YamlMap selectStyleInfo = loadYaml(selectStyleYamlText);
    return selectStyleInfo;
  }

  _getDisplayInfo(String theme, String version, String displayName) async {
    AssetBundle rootBundle = parent.getService("@rootBundle");
    int pos = displayName.lastIndexOf("@");
    String dname = '';
    if (pos < 0) {
      dname = displayName;
    } else {
      dname = displayName.substring(0, pos);
    }
    var dispalyYaml =
        "lib/src/themes/${theme}/versions/v-${version}/displays/${dname}.yaml";
    dynamic dispalyYamlText = await rootBundle.loadString(dispalyYaml);
    YamlMap selectStyleInfo = loadYaml(dispalyYamlText);
    return selectStyleInfo;
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
