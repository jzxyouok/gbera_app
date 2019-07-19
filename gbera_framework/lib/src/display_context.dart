import 'package:flutter/widgets.dart';

import 'i_service.dart';

class DisplayContext {
  BuildContext _context;
  Map<String,Object> _displayInfo;
  PageInfo _pageInfo;
  IPortalInfo _portalInfo;
  IServiceProvider site;
//  Map<String, DisplayMethod> _methods;
//  Map<String, DisplayProperty> _properties;

  PageInfo get pageInfo => _pageInfo;

  IPortalInfo get portalInfo => _portalInfo;

  DisplayContext({
    this.site,
    BuildContext context,
    PageInfo pageInfo,
  }) {
    ISystemDir _systemDir = site.getService("@systemDir");
    this._portalInfo = _systemDir.getPortalInfo(pageInfo);
    this._pageInfo = pageInfo;
    this._context = context;
    Map<String,Object> portal=_portalInfo.getInfo();
    Map<String,Object> displays=portal['displays'];
    _displayInfo=displays[_pageInfo.display];
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
