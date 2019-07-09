library framework;

import 'package:flutter/src/widgets/framework.dart';

export 'package:gbera_framework/src/themes.dart';
export 'package:gbera_framework/src/microapps.dart';

class Framework {
  static Framework _framework;

  Framework();

  factory Framework.getFramework() {
    if (_framework != null) {
      return _framework;
    }
    _framework = Framework();
    return _framework;
  }

  BuildContext _context;

  void forward(String pagePath, {Object arguments}) {}
}
