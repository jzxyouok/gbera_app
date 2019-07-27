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

  MicroDisplayInfo get displayInfo {
    var portal = _portal.getInfo();
    var displays = portal.displays;
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

  call(
    String methodName, {
    Map<String, Object> parameters, //有的自动放入内容，有一自动放入参数，有的自动放入头
    void Function(dynamic data, Response response) onsucceed,
    void Function(dynamic e, dynamic stack) onerror,
    void Function(int, int) onReceiveProgress,
    void Function(int, int) onSendProgress,
  }) async {
    var _methods = displayInfo.methods;
    if (!_methods.containsKey(methodName)) {
      throw '404 方法在显示器中未有定义';
    }
    var _method = _methods[methodName];
    var cmd = _method.command;
    var _defparameters = _method.parameters;

    Map<String, String> _parameters = Map();
    Map<String, String> _headers = Map();
    Map<String, Object> _contents = Map();

    parameters.forEach((key, v) {
      if (!_defparameters.containsKey(key)) {
        throw '未定义参数:在方法:$methodName.$key';
      }
      var _p = _defparameters[key];
      switch (_p.inRequest) {
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
    _headers['Rest-Command'] = _method.name;
    switch (_method.tokenInfo?.inrequest) {
      case "header":
        _headers[_method?.tokenInfo?.name] = pageInfo?.microsite?.token;
        break;
      case "parameter":
        _parameters[_method?.tokenInfo?.name] = pageInfo?.microsite?.token;
        break;
      case 'nope': //表示无令牌
      default:
        print('错误:令牌只能放到请求头或参数中，错误放在：${_method.tokenInfo?.inrequest}');
        break;
    }
    Options options = Options(headers: _headers);

    Dio dio = site.getService('@http');

    switch (cmd) {
      case 'get':
        var host = this.pageInfo?.microsite?.host;
        try {
          var response = await dio.get(
            host,
            queryParameters: _parameters,
            onReceiveProgress: onReceiveProgress,
            options: options,
          );
          if (onsucceed != null) {
            var data = response.data;
            Map<String, Object> rc = jsonDecode(data);
            int status = rc['status'];
            if ((status >= 200 && status < 300) || status == 304) {
              onsucceed(rc, response);
            } else {
              onerror(
                  OpenportsException(
                    state: status,
                    message: rc['message'],
                    cause: rc['dataText'],
                  ),
                  null);
            }
          }
        } on DioError catch (e, stack) {
          if (e.response != null) {
            if (onsucceed != null) {
              var data = e.response.data;
              Map<String, Object> rc = jsonDecode(data);
              onsucceed(rc, e.response);
            }
          } else {
            // Something happened in setting up or sending the request that triggered an Error
            if (onerror != null) {
              onerror(e, stack);
              return;
            }
            FlutterErrorDetails details =
                FlutterErrorDetails(exception: e, stack: stack);
            FlutterError.reportError(details);
          }
        }
        break;
      case 'post':
        var host = this.pageInfo.microsite?.host;
        options.headers['Content-Type'] =
            'application/x-www-form-urlencoded; charset=UTF-8';
        try {
          var response = await dio.post(
            host,
            data: json.encode(_contents),
            queryParameters: _parameters,
            onReceiveProgress: onReceiveProgress,
            onSendProgress: onSendProgress,
            options: options,
          );
          if (onsucceed != null) {
            var data = response.data;
            Map<String, Object> rc = jsonDecode(data);
            int status = rc['status'];
            if ((status >= 200 && status < 300) || status == 304) {
              onsucceed(rc, response);
            } else {
              onerror(
                  OpenportsException(
                    state: status,
                    message: rc['message'],
                    cause: rc['dataText'],
                  ),
                  null);
            }
          }
        } on DioError catch (e, stack) {
          // The request was made and the server responded with a status code
          // that falls out of the range of 2xx and is also not 304.
          if (e.response != null) {
            if (onsucceed != null) {
              var data = e.response.data;
              Map<String, Object> rc = jsonDecode(data);
              onsucceed(rc, e.response);
            }
          } else {
            // Something happened in setting up or sending the request that triggered an Error
            if (onerror != null) {
              onerror(e, stack);
              return;
            }
            FlutterErrorDetails details =
                FlutterErrorDetails(exception: e, stack: stack);
            FlutterError.reportError(details);
          }
        }
        break;
      default:
        throw '不支持的命令：$cmd';
    }
  }
}
