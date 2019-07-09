import 'package:flutter/material.dart';
import 'package:gbera_app/src/themes/gbera/versions/v-1.0/displays/home_display.dart';
import 'package:gbera_framework/gbera_app.dart';

//flutter中的dart不支持动态反射实例化类型
//面向微主题开发，向framework注册微主题

void main() => runApp(NetosApp(
      taskbarTitle: 'gbera',
      welcome: 'gbera://index.page',
      initFramework: (framework) {
        framework.loadThemeConfig(path: "src/conf");

        framework.themeBinder(
          theme: "mytheme/1.0",
          displays: (theme) {
            return {
              'mydisplay1': GberaHomeDisplay(),
              'mydisplay2': GberaHomeDisplay(),
              'mydisplay3': GberaHomeDisplay(),
              'mydisplay4': GberaHomeDisplay(),
            };
          },
        );

        framework.themeBinder(
          theme: "mytheme/1.1",
          displays: (theme) {
            return {
              'mydisplay1': GberaHomeDisplay(),
              'mydisplay2': GberaHomeDisplay(),
              'mydisplay3': GberaHomeDisplay(),
              'mydisplay4': GberaHomeDisplay(),
            };
          },
        );
      },
    ));
