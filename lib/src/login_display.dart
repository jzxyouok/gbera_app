//以下主页应放到主程序中实现并向framework注册s
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gbera_framework/framework.dart';

class LoginDisplay extends StatefulWidget {
  LoginDisplay({Key key, this.title, this.context}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final DisplayContext context;
  final String title; //应用的标题，不是android任务栏状态时的标题

  @override
  _LoginDisplayState createState() => _LoginDisplayState();
}

class _LoginDisplayState extends State<LoginDisplay> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var dctx = widget.context;
    var s=dctx.portal;
    var b=dctx.site;
    var e=dctx.displayInfo;
    var f=dctx.pageInfo;
    var l=s.getUseStyle();
    var m=s.getInfo();
    return Scaffold(
//      resizeToAvoidBottomPadding: false,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: <Widget>[
            const SizedBox(height: 80.0),
            Column(
              children: <Widget>[
//                Image.asset('packages/shrine_images/diamond.png'),
                const SizedBox(height: 16.0),
                Text(
                  '金证时代',
                  style: Theme.of(context).textTheme.headline,
                ),
              ],
            ),
            const SizedBox(height: 120.0),
            PrimaryColorOverride(
              color: Colors.red,
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            PrimaryColorOverride(
              color: Colors.red,
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                ),
              ),
            ),
            Wrap(
              children: <Widget>[
                ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: const Text('重置'),
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(7.0)),
                      ),
                      onPressed: () {
                        _passwordController.text = '';
                        _usernameController.text = '';
                      },
                    ),
                    RaisedButton(
                      child: const Text('登录'),
                      elevation: 8.0,
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(7.0)),
                      ),
                      onPressed: () {
                        //widget.context.forward("gbera://home2.page");
//                      Navigator.of(context).pushNamed('/error.page');
                        LoginAction loginAction = LoginAction(
                            context: dctx,
                            user: _usernameController.text,
                            pwd: _passwordController.text,).login();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryColorOverride extends StatelessWidget {
  const PrimaryColorOverride({Key key, this.color, this.child})
      : super(key: key);

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      child: child,
      data: Theme.of(context).copyWith(primaryColor: color),
    );
  }
}

class LoginAction {
  final String user;
  final String pwd;
  final DisplayContext context;

  const LoginAction({this.user, this.pwd, this.context});

  login() {
    int pos = user.lastIndexOf("@");
    var account = '';
    var tenant = '';
    if (pos < 0) {
      account = user;
    } else {
      account = user.substring(0, pos);
      tenant = user.substring(pos + 1, user.length);
    }
    if ((user.length == 11 || user.length == 12) &&
        (user.startsWith("1") || user.startsWith("01"))) {
      context.restfull(
        'authenticate',
        parameters: {
          "authName": "auth.phone",
          "tenant": tenant,
          "principals": account,
          "password": pwd,
          "ttlMillis": "31536000000000",
        },
        onsucceed: (response) {
          forwardOK(response);
        },
        onerror: (e) {
          forwardError(e);
        },
        onReceiveProgress: (i,j){

        },
      );
    } else {
      context.restfull(
        'authenticate',
        parameters: {
          "authName": "auth.password",
          "tenant": tenant,
          "principals": account,
          "password": pwd,
          "ttlMillis": "31536000000000",
        },
        onsucceed: (response) {
          forwardOK(response);
        },
        onerror: (e) {
          forwardError(e);
        },
        onReceiveProgress: (i,j){
          print('$i-$j');
        },
      );
    }
  }

  void forwardOK(response) {
    context.forward("gbera://home.page");
  }

  void forwardError(e) {
    context.forward("gbera://public/error.page",arguments: {"error":'$e'});
  }
}
