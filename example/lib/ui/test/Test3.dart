import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Test3 extends StatefulWidget {
  Test3({Key? key}) : super(key: key);

  @override
  Test3State createState() => Test3State();
}

class Test3State extends State<Test3> with TickerProviderStateMixin {
  ValueNotifier<double> topOffsetLis = ValueNotifier(0.0);
  ValueNotifier<double> bottomOffsetLis = ValueNotifier(0.0);
  late RefreshController _refreshController;
  late RefreshState _refreshState;

  List<Widget> data = [];

  void _getDatas() {
    data.add(Row(
      children: <Widget>[
        TextButton(
            onPressed: () {
              _refreshController
                  .requestRefresh(needCallback: false)
                  .then((value) async {
                print("requestRefresh");
                await Future.delayed(const Duration(milliseconds: 5000));
                _refreshState.refreshCompleted();
              });
            },
            child: Text("请求刷新")),
        TextButton(
            onPressed: () {
              _refreshController
                  .requestLoading(needCallback: false)
                  .then((value) async {
                print("requestLoading");
                await Future.delayed(const Duration(milliseconds: 5000));
                _refreshState.loadComplete();
              });
            },
            child: Text("请求加载数据"))
      ],
    ));
    for (int i = 0; i < 1; i++) {
      data.add(GestureDetector(
        child: Container(
          color: Color.fromARGB(255, 250, 250, 250),
          child: Card(
            margin:
                EdgeInsets.only(left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
            child: Center(
              child: Text('Data $i'),
            ),
          ),
        ),
        onTap: () {
          _refreshController.requestRefresh();
        },
      ));
    }
  }

  void enterRefresh() {
    _refreshController.requestLoading();
  }

  @override
  void initState() {
    _getDatas();
    _refreshState = RefreshState(initialLoadStatus: LoadStatus.noMore);
    _refreshController = RefreshController();
    super.initState();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _refreshState.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration.copyAncestor(
      context: context,
      footerTriggerDistance: -80,
      maxUnderScrollExtent: 60,
      enableLoadingWhenNoData: true,
      child: SmartRefresher(
        enablePullUp: true,
        enablePullDown: true,
        state: _refreshState,
        controller: _refreshController,
        footer: ClassicFooter(
          height: 60,
          loadStyle: LoadStyle.ShowWhenLoading,
        ),
        header: TwoLevelHeader(
          twoLevelWidget: Center(
            child: Container(
              color: Colors.green,
              width: double.infinity,
              child: Text("twoLevel"),
              height: 60,
            ),
          ),
        ),
        onRefresh: () async {
          print("onRefresh");
          await Future.delayed(const Duration(milliseconds: 3000));
          data.add(Container(
            child: Card(),
            height: 100.0,
          ));
          if (mounted) setState(() {});
          _refreshState.refreshCompleted();
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverFillViewport(
                delegate: SliverChildListDelegate(
                    [data[0], data[1], Text("第一页"), Text("第一页")]))
          ],
          physics: PageScrollPhysics(),
        ),
        onLoading: () async {
          await Future.delayed(const Duration(milliseconds: 1000));
          print("onLoading");
          _refreshState.loadNoData();
        },
      ),
      dragSpeedRatio: 0.9,
    );
  }
}

class CirclePainter extends CustomClipper<Path> {
  final double? offset;
  final bool? up;

  CirclePainter({this.offset, this.up});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (!up!) path.moveTo(0.0, size.height);
    path.cubicTo(
        0.0,
        up! ? 0.0 : size.height,
        size.width / 2,
        up! ? offset! * 2.3 : size.height - offset! * 2.3,
        size.width,
        up! ? 0.0 : size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return oldClipper != this;
  }
}
