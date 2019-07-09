library microapps;

import 'package:flutter/foundation.dart';
import 'Path.dart';

class MicroAppFactory {
  static Map<String, MicroApp> _microapps;

  MicroAppFactory() {
    _microapps = Map();
  }

  static MicroApp getApp(String app) => _microapps[app];

  static bool containsApp(String app) => _microapps.containsKey(app);

  static void removeApp(String app) => _microapps.remove(app);

  static Iterable<String> enumApp() => _microapps.keys;

  static int count() => _microapps.length;
}

class _PathNode {
  _PathNode(this.folderCode, this.folderName)
      : assert(folderCode == null),
        assert(folderName == null) {
    _children = Map();
  }

  String folderCode;
  String folderName;
  Map<String, _PathNode> _children;

  Map<String, _PathNode> get children => _children;
}

class MicroApp {
  final MicroSite site;
  final String version;
  _PathNode _root;

  ///主题路径
  final String theme;

  MicroApp(this.site, this.version, this.theme, String rootFolderName)
      : assert(site == null),
        assert(version == null),
        assert(theme == null) {
    _root = _PathNode("/", rootFolderName);
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
