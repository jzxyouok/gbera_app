import 'package:flutter/widgets.dart';

import '../framework.dart';
import 'i_service.dart';

mixin IThemeCacher {
  getDisplay(String themefull, String displayName) {}

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
  getDisplay(String themefull, String displayName) {
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
      return display(themefull, displayName);
    }
    //将显器示绑定到主题
    var microTheme = null;
    var binder = _binders[themefull];
    Map<String, DisplayGetter> displayGetters = binder(microTheme);
    _displays[themefull] = displayGetters;

    var display = displayGetters[dname];
    return display(themefull, displayName);
  }

  @override
  void cacheBinder(String theme, displays) {
    _binders[theme] = displays;
  }
}
