/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time: 2019/3/29 下午4:27
 */

import 'package:flutter/material.dart';

class SecondActivity extends StatefulWidget {
  SecondActivity({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _SecondActivityState createState() => new _SecondActivityState();
}

class _SecondActivityState extends State<SecondActivity> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
        leading: GestureDetector(
            child: Container(
              child: Row(
                children: <Widget>[Icon(Icons.keyboard_arrow_left), Text("返回")],
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
            }),
      ),
      body: Text("测试跳转返回"),
    );
  }
}
