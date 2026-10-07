/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time:  2019-06-26 13:28
 */

/*
   use to place indicator to other places,such as WeChat friend circle refresh effect
   int 1.4.7 version will add it
*/

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../Item.dart';

class LinkHeaderExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LinkHeaderExampleState();
  }
}

class _LinkHeaderExampleState extends State<LinkHeaderExample> {
  static const double _coverExtent = 150.0;

  final RefreshState _refreshState = RefreshState();
  final RefreshController _refreshController = RefreshController();
  final Key linkKey = GlobalKey();
  List<String> data = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];
  final ScrollController _scrollController = ScrollController();
  bool dismissAppbar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final barExtent = MediaQuery.paddingOf(context).top + kToolbarHeight;
      final bool ifdismissAppbar = _scrollController.offset >=
          (_coverExtent - barExtent).clamp(0.0, _coverExtent);
      if (dismissAppbar != ifdismissAppbar) {
        setState(() {
          dismissAppbar = ifdismissAppbar;
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _refreshState.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration.copyAncestor(
      context: context,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:
              dismissAppbar ? Colors.blueAccent : Colors.transparent,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: dismissAppbar ? 1.0 : 0.0,
          centerTitle: true,
          title: SimpleLinkBar(key: linkKey),
        ),
        body: SmartRefresher(
          state: _refreshState,
          controller: _refreshController,
          header: LinkHeader(
            linkKey: linkKey,
            // Preserve the negative overlap for the stretching cover sliver.
            refreshStyle: RefreshStyle.Behind,
          ),
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 3000));
            if (!mounted) return;
            setState(() {
              data = List.generate(9, (index) => "${index + 1}");
            });
            _refreshState.refreshCompleted(resetFooterState: true);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverAppBar(
                primary: false,
                toolbarHeight: 0,
                collapsedHeight: 0,
                expandedHeight: _coverExtent,
                stretch: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Image.asset(
                    "images/qqbg.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SliverFixedExtentList(
                delegate: SliverChildBuilderDelegate(
                  (c, i) => Item(title: data[i]),
                  childCount: data.length,
                ),
                itemExtent: 100.0,
              ),
            ],
          ),
        ),
      ),
      maxOverScrollExtent: 100,
    );
  }
}

class SimpleLinkBar extends StatefulWidget {
  SimpleLinkBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SimpleLinkBarState();
  }
}

class _SimpleLinkBarState extends State<SimpleLinkBar>
    with RefreshProcessor, SingleTickerProviderStateMixin {
  RefreshStatus? _status = RefreshStatus.idle;
  late AnimationController _animationController;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  Future<void> endRefresh() async {
    try {
      await _animationController
          .animateTo(0.0, duration: const Duration(milliseconds: 300))
          .orCancel;
    } on TickerCanceled {
      // A new refresh or disposal cancels the previous exit animation.
    }
  }

  @override
  void onOffsetChange(double offset) {
    if (_status == RefreshStatus.idle || _status == RefreshStatus.canRefresh) {
      final triggerDistance =
          RefreshConfiguration.of(context)?.headerTriggerDistance ?? 80.0;
      _animationController.value = (offset / triggerDistance).clamp(0.0, 1.0);
    }
    super.onOffsetChange(offset);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      child: const CupertinoActivityIndicator(color: Colors.white),
      scale: _animationController,
    );
  }

  @override
  void onModeChange(RefreshStatus? mode) {
    super.onModeChange(mode);
    _status = mode;
    if (mode == RefreshStatus.refreshing) {
      _animationController.value = 1.0;
    } else if (mode == RefreshStatus.idle) {
      _animationController.value = 0.0;
    }
  }
}
