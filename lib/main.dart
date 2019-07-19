library gbera;

import 'package:gbera_app/src/login_display.dart';
import 'package:gbera_framework/framework.dart';

import 'package:gbera_app/src/backdrop_display.dart';

//flutter中的dart不支持动态反射实例化类型
//面向微主题开发，向framework注册微主题

void main() async {
  await Framework(
    remoteMicroappHost: 'http://localhost:7800',
    clearCaches: true,
    remoteMicroappToken: 'xxxx',
    bindPortals: (framework) {
      framework.portalBinder(
        portal: "gbera/1.0",
        displays: (portal) {
          //懒构造显示器的函数参数：在此传入当前app,主题,及显示器，因此得弄个displayContext让开发者传入其自定义的显示器构造
          return {
            'login_display': (context) => LoginDisplay(
                  context: context,
                  title: 'xxxx',
                ),
            'backdrop_display': (context) => BackdropDisplay(
                  context: context,
                  title: 'yyyy',
                ),
          };
        },
      );
    },
  ).runMicroAppOn(
      taskbarTitle: 'gbera',
      welcome: 'gbera://public/login.page',
      onBeforeRun: (app) {
        print("启动中..........");
      },
      onAfterRun: (app) {
        print("..........已启动");
      });
}
