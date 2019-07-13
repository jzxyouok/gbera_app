import 'package:flutter/widgets.dart';

import '../framework.dart';
import 'i_service.dart';
import 'package:yaml/yaml.dart';

mixin IThemeCacher {
  getDisplay(DisplayContext context) {}

  void cacheBinder(String theme, displays) {}
}

class ThemeCacher implements IThemeCacher {
  final IServiceProvider parent;
  Map<String, DisplayBinder> _binders;
  Map<String, Object> _displays;

  ThemeCacher(this.parent) {
    this._binders = Map();
    _displays = Map();
  }

  @override
  getDisplay(DisplayContext context) {
    String displayName = context.page['display'];
    String themefull = context.page['theme'];
    //将显器示绑定到主题
    var microTheme = getTheme(themefull);
    if (microTheme == null) {
      return null;
    }
    int pos = displayName.lastIndexOf("@");
    String dname = '';
    if (pos < 0) {
      dname = displayName;
    } else {
      dname = displayName.substring(0, pos);
    }

    Map<String, DisplayGetter> cachedDisplayGetters = _displays[themefull];
    if (cachedDisplayGetters != null) {
      var display = cachedDisplayGetters[dname];
      return display(context);
    }

    var binder = _binders[themefull];
    Map<String, DisplayGetter> displayGetters = binder(microTheme);
    _displays[themefull] = displayGetters;

    var display = displayGetters[dname];
    return display(context);
  }

  @override
  void cacheBinder(String theme, displays) {
    _binders[theme] = displays;
  }

  getTheme(String themefull) {
//    String theme;
//    String version;
//    int pos = themefull.lastIndexOf("/");
//    if (pos < 0) {
//      theme = themefull.substring(0, pos);
//    } else {
//      version=themefull.substring(pos+1,themefull.length);
//    }
//    var fn="src/themes/${theme}/versions/v-${}";
//    var yaml = loadYaml(yaml);
  return null;
  }
}
