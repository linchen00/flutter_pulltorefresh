/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time:  2019-07-03 17:24
 */

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/*
  notice that,If your combine with DraggableScrollSheet with SmartRefresher,
  It not support enablePullDown,only support enablePullUp = true.
  the second, the example has StatefulBuilder,just not setState(),it will never rebuild scrollSheet
 */
class DraggableLoadingBottomSheet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DraggableLoadingBottomSheetState();
  }
}

class _DraggableLoadingBottomSheetState
    extends State<DraggableLoadingBottomSheet> {
  RefreshController _controller = RefreshController();

  List<String> items = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 15; i++) items.add("数据");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DraggableScrollableSheet'),
      ),
      body: Container(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
                backgroundColor: Colors.transparent,
                context: context,
                builder: (c) {
                  return DraggableScrollableSheet(
                    initialChildSize: 1.0,
                    maxChildSize: 1.0,
                    minChildSize: 0.5,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        color: Colors.blue[100],
                        child: StatefulBuilder(
                          builder: (BuildContext context2, setter) {
                            return SmartRefresher(
                              child: ListView.separated(
                                controller: scrollController,
                                separatorBuilder: (c, i) => Divider(),
                                itemBuilder: (_, e) => Container(
                                  child: Center(child: Text(items[e])),
                                  height: 40.0,
                                ),
                                physics: ClampingScrollPhysics(),
                                itemCount: items.length,
                              ),
                              controller: _controller,
                              onLoading: () async {
                                await Future.delayed(
                                    Duration(milliseconds: 1000));
                                if (!mounted) return;
                                for (int i = 0; i < 15; i++) {
                                  items.add("数据 ${items.length + 1}");
                                }
                                setter(() {});
                                _controller.loadComplete();
                              },
                              enablePullUp: true,
                              enablePullDown: false,
                            );
                          },
                        ),
                      );
                    },
                  );
                });
          },
          child: Text("点击打开滑动BottomSheet"),
        ),
      ),
    );
  }
}
