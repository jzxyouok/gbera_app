import 'package:flutter/material.dart';

import '../framework.dart';
import '../util.dart';

class MyThemeData {
  static ThemeData parseStyle(MicroStyleInfo styleInfo) {
    Map<String, Object> theme = styleInfo.theme;
    if (theme == null) return null;

    getColorByHex(String styleItem, String text) {
      if (StringUtil.isEmpty(text)) {
        return null;
      }
      if (!text.startsWith("#") && !text.startsWith("0x")) {
        debugPrint('主题：$styleItem 的定义即不是以#开头也不是以0x开头，请求单引号包括');
        return null;
      }
      while (text.startsWith("#")) {
        text = text.substring(1, text.length);
      }
      while (text.startsWith("0x")) {
        text = text.substring(2, text.length);
      }
      var intcolor = int.parse(text, radix: 16);
      return Color(intcolor);
    }

    getMaterialColor(String styleItem, Map<String, Object> map) {
      if (map == null) return null;
      dynamic py = map['primary'];
      py = py == null ? null : '$py';
      var primary = getColorByHex(styleItem, py);
      List swatchs = map['swatchs'];
      Map<int, Color> mc = Map();
      swatchs.forEach((item) {
        Map<String, Object> obj = item as Map<String, Object>;
        obj.forEach((key, v) {
          String text = v == null ? null : '$v';
          var c = getColorByHex(styleItem, text);
          if (c != null) {
            mc[int.parse(key)] = c;
          }
        });
      });

      return MaterialColor(primary.value, mc);
    }

    getIconThemeData(String styleItem, Map<String, Object> map) {
      if (map == null) return null;
      return IconThemeData(
        color: getColorByHex(styleItem, map['color']),
        opacity: map['opacity'],
        size: map['size'],
      );
    }

    return ThemeData(
      backgroundColor:
          getColorByHex('backgroundColor', theme['backgroundColor']),
      accentColor: getColorByHex('accentColor', theme['accentColor']),
      accentColorBrightness: theme['accentColorBrightness'] == null
          ? null
          : () {
              switch (theme['accentColorBrightness']) {
                case 'dark':
                  return Brightness.dark;
                case 'light':
                  return Brightness.light;
              }
              return null;
            }(),
      accentIconTheme:
          getIconThemeData('accentIconTheme', theme['accentIconTheme']),
      bottomAppBarColor:
          getColorByHex('bottomAppBarColor', theme['bottomAppBarColor']),
      brightness: theme['brightness'] == null
          ? null
          : () {
              switch (theme['brightness']) {
                case 'dark':
                  return Brightness.dark;
                case 'light':
                  return Brightness.light;
              }
              return null;
            }(),
      buttonColor: getColorByHex('buttonColor', theme['buttonColor']),
      canvasColor: getColorByHex('canvasColor', theme['canvasColor']),
      cardColor: getColorByHex('cardColor', theme['cardColor']),
      cursorColor: getColorByHex('cursorColor', theme['cursorColor']),
      dialogBackgroundColor: getColorByHex(
          'dialogBackgroundColor', theme['dialogBackgroundColor']),
      disabledColor: getColorByHex('disabledColor', theme['disabledColor']),
      dividerColor: getColorByHex('dividerColor', theme['dividerColor']),
      errorColor: getColorByHex('errorColor', theme['errorColor']),
      focusColor: getColorByHex('focusColor', theme['focusColor']),
      fontFamily: theme['fontFamily'],
      highlightColor: getColorByHex('highlightColor', theme['highlightColor']),
      hintColor: getColorByHex('hintColor', theme['hintColor']),
      hoverColor: getColorByHex('hoverColor', theme['hoverColor']),
      indicatorColor: getColorByHex('indicatorColor', theme['indicatorColor']),
      platform: theme['platform'] == null
          ? null
          : () {
              switch (theme['platform']) {
                case 'android':
                  return TargetPlatform.android;
                case 'ios':
                  return TargetPlatform.iOS;
                case 'fuchsia':
                  return TargetPlatform.fuchsia;
              }
              return null;
            }(),
      primaryColor: getColorByHex('primaryColor', theme['primaryColor']),
      primaryColorBrightness: theme['primaryColorBrightness'] == null
          ? null
          : () {
              switch (theme['primaryColorBrightness']) {
                case 'dark':
                  return Brightness.dark;
                case 'light':
                  return Brightness.light;
              }
              return null;
            }(),
      primaryColorDark:
          getColorByHex('primaryColorDark', theme['primaryColorDark']),
      primaryColorLight:
          getColorByHex('primaryColorLight', theme['primaryColorLight']),
      primarySwatch: getMaterialColor('primarySwatch', theme['primarySwatch']),
      scaffoldBackgroundColor: getColorByHex(
          'scaffoldBackgroundColor', theme['scaffoldBackgroundColor']),
      secondaryHeaderColor:
          getColorByHex('secondaryHeaderColor', theme['secondaryHeaderColor']),
      selectedRowColor:
          getColorByHex('selectedRowColor', theme['selectedRowColor']),
      splashColor: getColorByHex('splashColor', theme['splashColor']),
      textSelectionColor:
          getColorByHex('textSelectionColor', theme['textSelectionColor']),
      textSelectionHandleColor: getColorByHex(
          'textSelectionHandleColor', theme['textSelectionHandleColor']),
      textTheme: theme['textTheme'],
      toggleableActiveColor: getColorByHex(
          'toggleableActiveColor', theme['toggleableActiveColor']),
      unselectedWidgetColor: getColorByHex(
          'unselectedWidgetColor', theme['unselectedWidgetColor']),
    );
  }
}
