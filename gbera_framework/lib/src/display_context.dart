import 'package:flutter/widgets.dart';

import 'i_service.dart';

class DisplayContext {
  BuildContext _context;
  PageInfo _pageInfo;
  IPortal _portal;
  IServiceProvider site;

//  Map<String, DisplayMethod> _methods;
//  Map<String, DisplayProperty> _properties;

  PageInfo get pageInfo => _pageInfo;

  IPortal get portal => _portal;

  Map<String, Object> get displayInfo {
    Map<String, Object> portal = _portal.getInfo();
    Map<String, Object> displays = portal['displays'];
    var _displayInfo = displays[_pageInfo.display];
    return _displayInfo;
  }

  DisplayContext({
    this.site,
    BuildContext context,
    PageInfo pageInfo,
  }) {
    ISystemDir _systemDir = site.getService("@systemDir");
    this._portal = _systemDir.getPortal(pageInfo);
    this._pageInfo = pageInfo;
    this._context = context;
  }

  String path() {
    return ModalRoute.of(_context).settings.name;
  }

  Object arguments() {
    return ModalRoute.of(_context).settings.arguments;
  }

  void forward(String pagePath, {Object arguments}) {
    Navigator.pushNamed(_context, pagePath, arguments: arguments);
  }
}
