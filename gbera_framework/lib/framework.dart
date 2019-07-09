library framework;

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'src/i_service_provider.dart';
import 'src/themes.dart';
export 'package:gbera_framework/src/themes.dart';
export 'package:gbera_framework/src/apps.dart';

typedef _DisplayBinder = Map<String, Widget> Function(MicroTheme theme);

final framework = Framework.getFramework();

class Framework implements IServiceProvider {
  static Framework _framework;

  Framework._create();

  factory Framework.getFramework() {
    if (_framework == null) {
      _framework = Framework._create();
    }
    return _framework;
  }

  BuildContext _context;

  @override
  getService(String name) {}

  ///页面跳转
  void forward(String pagePath, {Object arguments}) {
    Navigator.pushNamed(_context, pagePath, arguments: arguments);
  }

  void loadThemeConfig({String path}) {
    assert(path == null);
  }

  void themeBinder({String theme, _DisplayBinder displays}) {
    //将显器示绑定到主题
    MicroTheme microTheme=null;

    Map<String,Widget> binder=displays(microTheme);
  }

  Map<String, WidgetBuilder> onOfficialMicroappRouters(BuildContext context,String welcome) {
    //为了主微应用页面间切换的性能考虑，在此方法中一次性初始化官方（app启动的第一个微应用）微应用的路由表：微应用页地址->display实例

    return {};
  }

//return new MaterialPageRoute(builder: builder, settings: settings);
  Route onUnofficialMicroappRouters(RouteSettings settings) {
    //如果不存在则到网上查找页，如果网上仍没有则返回null，如果网上有则检查是否有display，如果没有display则返回null
    //懒加载模式，每次查找一个显示器绑定之

    return null;
  }

  Route onUnknownRoute(RouteSettings settings) {
    //如果页仍不存在，或者是对应的显示器不存在，则弹出404界面
    return null;
  }
}
