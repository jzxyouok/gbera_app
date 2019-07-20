import 'dart:convert';

import 'package:dio/dio.dart';
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

  restfull(
    String methodName, {
    Map<String, Object> parameters, //有的自动放入内容，有一自动放入参数，有的自动放入头
    onsucceed,
    onerror,
  }) async {
    Map<String, Object> _methods = displayInfo['methods'];
    if (!_methods.containsKey(methodName)) {
      throw '404 方法在显示器中未有定义';
    }
    Map<String, Object> _method = _methods[methodName];
    var cmd = _method['command'];
    Map<String, Object> _defparameters = _method['parameters'];

    Map<String, String> _parameters = Map();
    Map<String, String> _headers = Map();
    Map<String, Object> _contents = Map();

    parameters.forEach((key, v) {
      if (!_defparameters.containsKey(key)) {
        throw '未定义参数:在方法:$methodName.$key';
      }
      Map<String, Object> _p = _defparameters[key];
      switch (_p['in-request']) {
        case 'header':
          _headers[key] = '$v';
          break;
        case 'parameter':
          _parameters[key] = '$v';
          break;
        case 'content':
          if ('get' == cmd) {
            throw 'get 请求无内容。$methodName.$key';
          }
          _contents[key] = v;
          break;
        default:
          throw '参数定义错误。参数仅能放到请求的header|parameter|content。$methodName.$key';
      }
    });
    Map<String, Object> restHeader = _method['rest-header'];
    if (restHeader != null) {
      restHeader.forEach((key, v) {
        _headers[key] = '$v';
      });
    }
    _headers['micrositeToken'] = pageInfo.micrositeToken;
    Options options = Options(headers: _headers);

    Dio dio = site.getService('@http');

    switch (cmd) {
      case 'get':
        var host = this.pageInfo.micrositeHost;
        Response response = await dio
            .get(
          host,
          queryParameters: _parameters,
          onReceiveProgress: (i, j) {},
          options: options,
        )
            .catchError(
          (e, stack) {
            if (onerror != null) {
              onerror(e);
              return;
            }
            FlutterErrorDetails details =
                FlutterErrorDetails(exception: e, stack: stack);
            FlutterError.reportError(details);
          },
        );
        if (onsucceed != null&&response!=null) {
          onsucceed(response);
        }
        break;
      case 'post':
        var host = this.pageInfo.micrositeHost;
        options.headers['Content-Type'] =
            'application/x-www-form-urlencoded; charset=UTF-8';
        Response response = await dio
            .post(
          host,
          data: json.encode(_contents),
          queryParameters: _parameters,
          onReceiveProgress: (i, j) {},
          onSendProgress: (i, j) {},
          options: options,
        )
            .catchError(
          (e, stack) {
            if (onerror != null) {
              onerror(e);
              return;
            }
            FlutterErrorDetails details =
                FlutterErrorDetails(exception: e, stack: stack);
            FlutterError.reportError(details);
          },
        );
        if (onsucceed != null&&response!=null) {
          onsucceed(response);
        }
        break;
      default:
        throw '不支持的命令：$cmd';
    }
  }
}
