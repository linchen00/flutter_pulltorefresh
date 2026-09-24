/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time: 2019/5/5 下午6:10
 */

import 'package:flutter/material.dart'
    hide RefreshIndicator, RefreshIndicatorState;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../Item.dart';

class IndicatorActivity extends StatefulWidget {
  final String? title;

  final Widget? header;

  final Widget? footer;

  final bool enableOverScroll;
  final bool reverse;

  IndicatorActivity(
      {this.title,
      this.header,
      this.reverse = false,
      this.footer,
      this.enableOverScroll = true});

  @override
  State<StatefulWidget> createState() {
    return _IndicatorActivityState();
  }
}

class _IndicatorActivityState extends State<IndicatorActivity> {
  List<Widget> items = [];
  late RefreshController _refreshController;

  void _init() {
    items.clear();
    for (int i = 0; i < 15; i++) {
      items.add(Item(
        title: "Data ${i + 1}",
      ));
    }
  }

  ScrollController? _scrollController;

  @override
  void initState() {
    _scrollController = new ScrollController();
    _refreshController = RefreshController();
    _init();

    super.initState();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Builder(
        builder: (c) {
          return SmartRefresher(
              child: ListView.builder(
                itemBuilder: (c, i) => items[i],
                itemExtent: 100.0,
                controller: _scrollController,
                reverse: widget.reverse,
                itemCount: items.length,
              ),
              onRefresh: _onRefresh,
              onLoading: () {
                _onLoading(c);
              },
              header: widget.header,
              footer: widget.footer,
              enablePullDown: true,
              enablePullUp: true,
              controller: _refreshController);
        },
      ),
    );
  }

  _onRefresh() {
    print("onRefresh");
    Future.delayed(Duration(milliseconds: 1000)).then((_) {
      if (!mounted) return;
      setState(_init);
      _refreshController.refreshCompleted(resetFooterState: true);
    });
  }

  _onLoading(BuildContext context) {
    print("onLoading");
    Future.delayed(Duration(milliseconds: 1000)).then((_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < 10; i++) {
          items.add(Item(title: "Data ${items.length + 1}"));
        }
      });
      _refreshController.loadComplete();
    });
  }
}
