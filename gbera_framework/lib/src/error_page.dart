import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DefaultErrorPage extends StatelessWidget {
  final String message;

  const DefaultErrorPage(this.message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                child: Text(
                  '${ModalRoute.of(context).settings.name}',
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                message,
                style: TextStyle(
                  color: Colors.red,
                ),
                maxLines: 4,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
