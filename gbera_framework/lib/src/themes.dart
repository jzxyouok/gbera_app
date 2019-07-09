library themes;

import 'Path.dart';

class MicroThemeFactory {
  static Map<String, MicroTheme> _themes;

  MicroThemeFactory() {
    _themes = Map();
  }

  static MicroTheme get(String theme) {
    return _themes[theme];
  }

  static bool containsTheme(String theme) {
    return _themes.containsKey(theme);
  }

  static int count() {
    return _themes.length;
  }

  static void addTheme(MicroTheme theme) {
    if (containsTheme(theme.theme)) {
      throw '已存在异常：${theme.theme}';
    }
    _themes[theme.theme] = theme;
  }

  static void removeTheme(String theme) {
    _themes.remove(theme);
  }

  static Iterable<String> enumTheme() {
    return _themes.keys;
  }


}

class MicroTheme {
  final String theme;
  final String version;
  Map<String, MicroThemeDisplay> displays;
  Map<String, MicroThemeStyle> styles;

  MicroTheme(this.theme, this.version)
      : assert(theme == null),
        assert(version == null) {
    displays = Map();
    styles = Map();
  }
}

///样式等同于flutter的主题,包括：icon,color,font,background etc.
class MicroThemeStyle {
  List<MicroThemeStyleItem> items;

  MicroThemeStyle() {
    items = List();
  }
}

class MicroThemeStyleItem {
  String name;
  String usage;
  MicroStyleItemType type;

  MicroThemeStyleItem(this.name, this.usage, this.type)
      : assert(usage == null),
        assert(type == null),
        assert(name == null);
}

enum MicroStyleItemType { icon, color, font, background, custom }

class MicroThemeDisplay {
  String displayId;
  String usage;
  List<MicroThemeDisplayMethod> methods;
  Map<String, MicroThemeDisplayProperty> properties;

  MicroThemeDisplay(this.displayId, [this.usage]) : assert(displayId == null) {
    methods = List();
    properties = Map();
  }
}

class MicroThemeDisplayProperty {
  String key;

  ///值类型
  String type;
  String usage;

  MicroThemeDisplayProperty(this.key, this.type, this.usage)
      : assert(key == null),
        assert(type == null),
        assert(usage == null);
}

class MicroThemeDisplayMethod {
  final String name;
  final String returnType;
  final String usage;
  List<MicroThemeDispalyMethodParameter> parameters;

  MicroThemeDisplayMethod(this.name, this.returnType, [this.usage])
      : assert(name == null),
        assert(returnType == null) {
    parameters = List();
  }
}

class MicroThemeDispalyMethodParameter {
  final String name;
  final String usage;
  final String type;

  const MicroThemeDispalyMethodParameter(this.name, this.type, this.usage);
}
