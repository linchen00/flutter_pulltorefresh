/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time:  2019-06-24 17:23
 */

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../Item.dart';

/*
   this example will show you how to implements horizontal refresh or reverse,
   the main point is in child scrollDirection attr
 */
class HorizontalRefresh extends StatefulWidget {
  @override
  _HorizontalRefreshState createState() => _HorizontalRefreshState();
}

class _HorizontalRefreshState extends State<HorizontalRefresh> {
  RefreshController _controller1 = RefreshController();
  RefreshController _controller2 = RefreshController();
  static const int _pageSize = 10;
  int _nextPage = 1;
  int _refreshVersion = 0;
  int _requestVersion = 0;
  List<String> data = [];
  List<String> reverseData = List.generate(10, (index) => "data ${index + 1}");

  Future<void> _fetch({bool refresh = false, bool loading = false}) async {
    final requestVersion = ++_requestVersion;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || requestVersion != _requestVersion) return;

    final page = refresh ? 1 : _nextPage;
    final refreshVersion = refresh ? _refreshVersion + 1 : _refreshVersion;
    final newItems = List.generate(
      _pageSize,
      (index) =>
          'https://picsum.photos/seed/pull-refresh-$refreshVersion-$page-$index/300/200',
    );

    setState(() {
      if (refresh) {
        data = newItems;
        _refreshVersion = refreshVersion;
      } else {
        data.addAll(newItems);
      }
      _nextPage = page + 1;
    });

    if (refresh) {
      _controller1.refreshCompleted(resetFooterState: true);
    } else if (loading) {
      _controller1.loadComplete();
    }
  }

  void _onRefresh() {
    _fetch(refresh: true);
  }

  void _onLoading() {
    _fetch(loading: true);
  }

  Widget buildImage(context, index) {
    return GestureDetector(
      child: Item1(
        url: data[index],
      ),
      onTap: () {
        _controller1.requestRefresh();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _controller1 = RefreshController();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          child: SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            controller: _controller1,
            onRefresh: _onRefresh,
            footer: ClassicFooter(
              iconPos: IconPosition.top,
              outerBuilder: (child) {
                return Container(
                  width: 80.0,
                  child: Center(
                    child: child,
                  ),
                );
              },
            ),
            header: ClassicHeader(
              iconPos: IconPosition.top,
              outerBuilder: (child) {
                return Container(
                  width: 80.0,
                  child: Center(
                    child: child,
                  ),
                );
              },
            ),
            onLoading: _onLoading,
            child: ListView.builder(
              itemCount: data.length,
              scrollDirection: Axis.horizontal,
              physics: ClampingScrollPhysics(),
              itemBuilder: buildImage,
            ),
          ),
          height: 200.0,
        ),
        Expanded(
          child: Container(
            child: SmartRefresher(
              enablePullDown: true,
              enablePullUp: true,
              controller: _controller2,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 1000));
                if (!mounted) return;
                setState(() {
                  reverseData =
                      List.generate(10, (index) => "data ${index + 1}");
                });
                _controller2.refreshCompleted(resetFooterState: true);
              },
              footer: ClassicFooter(
                iconPos: IconPosition.top,
                outerBuilder: (child) {
                  return Container(
                    width: 80.0,
                    child: Center(
                      child: child,
                    ),
                  );
                },
              ),
              header: WaterDropMaterialHeader(),
              onLoading: () async {
                await Future.delayed(const Duration(milliseconds: 1000));
                if (!mounted) return;
                setState(() {
                  for (int i = 0; i < 10; i++) {
                    reverseData.add("data ${reverseData.length + 1}");
                  }
                });
                _controller2.loadComplete();
              },
              child: ListView.builder(
                reverse: true,
                itemCount: reverseData.length,
                physics: ClampingScrollPhysics(),
                itemBuilder: (c, i) => Item(title: reverseData[i]),
              ),
            ),
            height: 200.0,
          ),
        )
      ],
    );
  }
}

class Item1 extends StatefulWidget {
  final String? url;

  Item1({this.url});

  @override
  _ItemState createState() => _ItemState();
}

class _ItemState extends State<Item1> {
  @override
  Widget build(BuildContext context) {
    return FadeInImage(
      placeholder: AssetImage("images/empty.png"),
      image: NetworkImage(
        widget.url!,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
