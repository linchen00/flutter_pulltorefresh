/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time:  2019-07-26 18:22
 */

import 'dart:async';

import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:gif_view/gif_view.dart';
import 'package:flutter/material.dart'
    hide RefreshIndicator, RefreshIndicatorState;

class GifHeader1 extends RefreshIndicator {
  GifHeader1() : super(height: 80.0, refreshStyle: RefreshStyle.Follow);
  @override
  State<StatefulWidget> createState() {
    return GifHeader1State();
  }
}

class GifHeader1State extends RefreshIndicatorState<GifHeader1> {
  final GifController _gifController = GifController();
  bool _loopRefreshFrames = false;
  Completer<void>? _endRefreshCompleter;

  @override
  void onModeChange(RefreshStatus? mode) {
    if (mode == RefreshStatus.refreshing) {
      _loopRefreshFrames = true;
      _gifController.seek(0);
      _gifController.play(initialFrame: 0);
    }
    super.onModeChange(mode);
  }

  @override
  Future<void> endRefresh() {
    _loopRefreshFrames = false;
    _endRefreshCompleter = Completer<void>();
    _gifController.seek(30);
    _gifController.play(initialFrame: 30);
    return _endRefreshCompleter!.future;
  }

  @override
  void resetValue() {
    _loopRefreshFrames = false;
    _gifController.pause();
    _gifController.seek(0);
    super.resetValue();
  }

  @override
  Widget buildContent(BuildContext context, RefreshStatus mode) {
    return GifView(
      image: AssetImage("images/gifindicator1.gif"),
      controller: _gifController,
      autoPlay: false,
      loop: false,
      frameRate: 60,
      onFrame: (frame) {
        if (_loopRefreshFrames && frame >= 29) {
          _gifController.seek(0);
        } else if (_endRefreshCompleter != null && frame >= 59) {
          _gifController.pause();
          _endRefreshCompleter!.complete();
          _endRefreshCompleter = null;
        }
      },
      height: 80.0,
      width: 537.0,
    );
  }

  @override
  void dispose() {
    _loopRefreshFrames = false;
    _endRefreshCompleter?.complete();
    _endRefreshCompleter = null;
    _gifController.dispose();
    super.dispose();
  }
}

class GifFooter1 extends StatefulWidget {
  GifFooter1() : super();

  @override
  State<StatefulWidget> createState() {
    return _GifFooter1State();
  }
}

class _GifFooter1State extends State<GifFooter1> {
  final GifController _gifController = GifController();
  bool _loopLoadingFrames = false;
  Completer<void>? _endLoadingCompleter;

  @override
  Widget build(BuildContext context) {
    return CustomFooter(
      height: 80,
      builder: (context, mode) {
        return GifView(
          image: AssetImage("images/gifindicator1.gif"),
          controller: _gifController,
          autoPlay: false,
          loop: false,
          frameRate: 60,
          onFrame: (frame) {
            if (_loopLoadingFrames && frame >= 29) {
              _gifController.seek(0);
            } else if (_endLoadingCompleter != null && frame >= 59) {
              _gifController.pause();
              _endLoadingCompleter!.complete();
              _endLoadingCompleter = null;
            }
          },
          height: 80.0,
          width: 537.0,
        );
      },
      loadStyle: LoadStyle.ShowWhenLoading,
      onModeChange: (mode) {
        if (mode == LoadStatus.loading) {
          _loopLoadingFrames = true;
          _gifController.seek(0);
          _gifController.play(initialFrame: 0);
        }
      },
      endLoading: () async {
        _loopLoadingFrames = false;
        _endLoadingCompleter = Completer<void>();
        _gifController.seek(30);
        _gifController.play(initialFrame: 30);
        return _endLoadingCompleter!.future;
      },
    );
  }

  @override
  void dispose() {
    _loopLoadingFrames = false;
    _endLoadingCompleter?.complete();
    _endLoadingCompleter = null;
    _gifController.dispose();
    super.dispose();
  }
}

class GifIndicatorExample1 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return GifIndicatorExample1State();
  }
}

class GifIndicatorExample1State extends State<GifIndicatorExample1> {
  RefreshController _controller = RefreshController();
  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration.copyAncestor(
      context: context,
      enableBallisticLoad: false,
      footerTriggerDistance: -80,
      child: SmartRefresher(
        controller: _controller,
        enablePullUp: true,
        header: GifHeader1(),
        footer: GifFooter1(),
        onRefresh: () async {
          await Future.delayed(Duration(milliseconds: 2000));
          _controller.refreshCompleted();
        },
        onLoading: () async {
          await Future.delayed(Duration(milliseconds: 2000));
          _controller.loadFailed();
        },
        child: ListView.builder(
          itemBuilder: (c, q) => Card(),
          itemCount: 50,
          itemExtent: 100.0,
        ),
      ),
    );
  }
}
