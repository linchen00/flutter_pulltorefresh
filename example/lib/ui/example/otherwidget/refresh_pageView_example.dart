/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time:  2019-06-24 17:14
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/*
  this example will show you how to use vertical PageView as child in SmartRefresher(vertical refresh)
 */
class PageViewExample extends StatefulWidget {
  PageViewExample({Key? key}) : super(key: key);

  @override
  PageViewExampleState createState() => PageViewExampleState();
}

class PageViewExampleState extends State<PageViewExample>
    with TickerProviderStateMixin {
  late RefreshController _refreshController;
  int _lastReportedPage = 0;
  int _pageCount = 4;

  final PageController _pageController = PageController();

  void enterRefresh() {
    _refreshController.requestLoading();
  }

  @override
  void initState() {
    _refreshController = RefreshController(initialRefresh: true);
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
      appBar: AppBar(),
      body: NotificationListener(
        onNotification: (ScrollNotification notification) {
          if (notification.depth == 0 &&
              notification is ScrollUpdateNotification) {
            final PageMetrics metrics = notification.metrics as PageMetrics;
            final int currentPage = metrics.page!.round();
            if (currentPage != _lastReportedPage) {
              _lastReportedPage = currentPage;
              // this will callback onPageChange()
              print("onPageChange + $currentPage");
            }
          }
          return false;
        },
        child: SmartRefresher(
          enablePullUp: true,
          enablePullDown: true,
          footer: ClassicFooter(
            loadStyle: LoadStyle.ShowWhenLoading,
          ),
          controller: _refreshController,
          header: MaterialClassicHeader(),
          onRefresh: () async {
            print("onRefresh");
            await Future.delayed(const Duration(milliseconds: 4000));
            if (!mounted) return;
            setState(() {
              _pageCount = 4;
              _lastReportedPage = 0;
            });
            _pageController.jumpToPage(0);
            _refreshController.refreshCompleted(resetFooterState: true);
          },
          child: CustomScrollView(
            physics: PageScrollPhysics(),
            controller: _pageController,
            slivers: <Widget>[
              SliverFillViewport(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Center(child: Text("第${index + 1}页")),
                  childCount: _pageCount,
                ),
              )
            ],
          ),
          onLoading: () {
            print("onload");
            Future.delayed(const Duration(milliseconds: 2000)).then((val) {
              if (!mounted) return;
              setState(() => _pageCount += 1);
              _refreshController.loadComplete();
            });
          },
        ),
      ),
    );
  }
}
