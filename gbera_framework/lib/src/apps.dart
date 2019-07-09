library microapps;

import 'package:flutter/foundation.dart';


class MicroApp {
  final MicroSite site;
  final String version;

  ///主题路径
  final String theme;

  MicroApp(this.site, this.version, this.theme, String rootFolderName)
      : assert(site == null),
        assert(version == null),
        assert(theme == null) {
  }

  void mkdir(String path, String folderCode, String folderName) {}

  void deldir(String path) {}

  bool existsPath(String path) {
    return false;
  }

  MicroPage getPage(String path) {
    return null;
  }

  void delPage(String path) {}

  List<String> listChildDir(String path) {
    return null;
  }

  List<MicroPage> listPage(String path) {
    return null;
  }
}

class MicroPage {
  String name;
  String desc;
  String path;
  String displayPath; //显示器路径，格式：/displayid.styleid
  MicroSite site; //私有站点

}

///微应用服务站
class MicroSite {
  final String url;
  final String token;
  Map<String, String> headers;
  Map<String, String> parameters;

  MicroSite(
      {@required this.url, @required this.token, this.headers, this.parameters})
      : assert(url == null),
        assert(token == null) {
    if (this.headers == null) {
      this.headers = Map();
    }
    if (this.parameters == null) {
      this.parameters = Map();
    }
  }

  MicroSite.createSite({@required this.url, @required this.token})
      : assert(url == null),
        assert(token == null) {
    headers = Map();
    parameters = Map();
  }
}
