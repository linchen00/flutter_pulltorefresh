/*
    Author: Jpeng
    Email: peng8350@gmail.com
    createTime:2018-05-01 11:39
*/

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:pull_to_refresh/src/internals/slivers.dart';

export 'refresh_state.dart';

// ignore_for_file: INVALID_USE_OF_PROTECTED_MEMBER
// ignore_for_file: INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER
// ignore_for_file: DEPRECATED_MEMBER_USE

/// when viewport not full one page, for different state,whether it should follow the content
typedef void OnTwoLevel(bool isOpen);

/// when viewport not full one page, for different state,whether it should follow the content
typedef bool ShouldFollowContent(LoadStatus? status);

/// global default indicator builder
typedef IndicatorBuilder = Widget Function();

/// a builder for attaching refresh function with the physics
typedef Widget RefresherBuilder(BuildContext context, RefreshPhysics physics);

/// header indicator display style
enum RefreshStyle {
  // indicator box always follow content
  Follow,
  // indicator box follow content,When the box reaches the top and is fully visible, it does not follow content.
  UnFollow,

  /// Let the indicator size zoom in with the boundary distance,look like showing behind the content
  Behind,

  /// this style just like flutter RefreshIndicator,showing above the content
  Front
}

/// footer indicator display style
enum LoadStyle {
  /// indicator always own layoutExtent whatever the state
  ShowAlways,

  /// indicator always own 0.0 layoutExtent whatever the state
  HideAlways,

  /// indicator always own layoutExtent when loading state, the other state is 0.0 layoutExtent
  ShowWhenLoading
}

/// This is the most important component that provides drop-down refresh and up loading.
/// [RefreshState] is required. [RefreshController] is optional.
///
/// header,I have finished a lot indicators,you can checkout [ClassicHeader],[WaterDropMaterialHeader],[MaterialClassicHeader],[WaterDropHeader],[BezierCircleHeader]
/// footer,[ClassicFooter]
///If you need to custom header or footer,You should check out [CustomHeader] or [CustomFooter]
///
/// See also:
///
/// * [RefreshConfiguration], A global configuration for all SmartRefresher in subtrees
///
/// * [RefreshController], requests UI operations on a bound refresher
class SmartRefresher extends StatefulWidget {
  /// Refresh Content
  ///
  /// notice that: If child is  extends ScrollView,It will help you get the internal slivers and add footer and header in it.
  /// else it will put child into SliverToBoxAdapter and add footer and header
  final Widget? child;

  /// header indicator displace before content
  ///
  /// If reverse is false,header displace at the top of content.
  /// If reverse is true,header displace at the bottom of content.
  /// if scrollDirection = Axis.horizontal,it will display at left or right
  ///
  /// from 1.5.2,it has been change RefreshIndicator to Widget,but remember only pass sliver widget,
  /// if you pass not a sliver,it will throw error
  final Widget? header;

  /// footer indicator display after content
  ///
  /// If reverse is true,header displace at the top of content.
  /// If reverse is false,header displace at the bottom of content.
  /// if scrollDirection = Axis.horizontal,it will display at left or right
  ///
  /// from 1.5.2,it has been change LoadIndicator to Widget,but remember only pass sliver widget,
  //  if you pass not a sliver,it will throw error
  final Widget? footer;
  // This bool will affect whether or not to have the function of drop-up load.
  final bool enablePullUp;

  /// controll whether open the second floor function
  final bool enableTwoLevel;

  /// This bool will affect whether or not to have the function of drop-down refresh.
  final bool enablePullDown;

  /// callback when header refresh
  ///
  /// when the callback is happening,you should use [RefreshState]
  /// to end refreshing state,else it will keep refreshing state
  final VoidCallback? onRefresh;

  /// callback when footer loading more data
  ///
  /// when the callback is happening,you should use [RefreshState]
  /// to end loading state,else it will keep loading state
  final VoidCallback? onLoading;

  /// callback when header ready to twoLevel
  ///
  /// If you want to close twoLevel,you should use [RefreshController.twoLevelComplete]
  final OnTwoLevel? onTwoLevel;

  /// Externally owned refresh and loading state.
  final RefreshState state;

  /// Optional controller for requesting UI operations.
  final RefreshController? controller;

  /// Request a refresh after the first layout.
  final bool initialRefresh;

  /// child content builder
  final RefresherBuilder? builder;

  /// copy from ScrollView,for setting in SingleChildView,not ScrollView
  final Axis? scrollDirection;

  /// copy from ScrollView,for setting in SingleChildView,not ScrollView
  final bool? reverse;

  /// copy from ScrollView,for setting in SingleChildView,not ScrollView
  final ScrollController? scrollController;

  /// copy from ScrollView,for setting in SingleChildView,not ScrollView
  final bool? primary;

  /// copy from ScrollView,for setting in SingleChildView,not ScrollView
  final ScrollPhysics? physics;

  /// copy from ScrollView,for setting in SingleChildView,not ScrollView
  final double? cacheExtent;

  /// copy from ScrollView,for setting in SingleChildView,not ScrollView
  final int? semanticChildCount;

  /// copy from ScrollView,for setting in SingleChildView,not ScrollView
  final DragStartBehavior? dragStartBehavior;

  /// creates a widget help attach the refresh and load more function
  /// state is required; controller is optional,
  /// child is your refresh content,Note that there's a big difference between children inheriting from ScrollView or not.
  /// If child is extends ScrollView,inner will get the slivers from ScrollView,if not,inner will wrap child into SliverToBoxAdapter.
  /// If your child inner container Scrollable,please consider about converting to Sliver,and use CustomScrollView,or use [builder] constructor
  /// such as AnimatedList,RecordableList,doesn't allow to put into child,it will wrap it into SliverToBoxAdapter
  /// If you don't need pull down refresh ,just enablePullDown = false,
  /// If you  need pull up load ,just enablePullUp = true
  SmartRefresher(
      {Key? key,
      required this.state,
      this.controller,
      this.initialRefresh = false,
      this.child,
      this.header,
      this.footer,
      this.enablePullDown = true,
      this.enablePullUp = false,
      this.enableTwoLevel = false,
      this.onRefresh,
      this.onLoading,
      this.onTwoLevel,
      this.dragStartBehavior,
      this.primary,
      this.cacheExtent,
      this.semanticChildCount,
      this.reverse,
      this.physics,
      this.scrollDirection,
      this.scrollController})
      : builder = null,
        super(key: key);

  /// creates a widget help attach the refresh and load more function
  /// state is required; controller is optional,builder must not be null
  /// this constructor use to handle some special third party widgets,this widget need to pass slivers ,but they are
  /// not extends ScrollView,so my widget inner will wrap child to SliverToBoxAdapter,which cause scrollable wrapping scrollable.
  /// for example,NestedScrollView is a StalessWidget,it's headerSliversbuilder can return a slivers array,So if we want to do
  /// refresh above NestedScrollVIew,we must use this constrctor to implements refresh above NestedScrollView,but for now,NestedScrollView
  /// can not support overscroll out of edge
  SmartRefresher.builder({
    Key? key,
    required this.state,
    this.controller,
    this.initialRefresh = false,
    required this.builder,
    this.enablePullDown = true,
    this.enablePullUp = false,
    this.enableTwoLevel = false,
    this.onRefresh,
    this.onLoading,
    this.onTwoLevel,
  })  : header = null,
        footer = null,
        child = null,
        scrollController = null,
        scrollDirection = null,
        physics = null,
        reverse = null,
        semanticChildCount = null,
        dragStartBehavior = null,
        cacheExtent = null,
        primary = null,
        super(key: key);

  static SmartRefresher? of(BuildContext? context) {
    return context!
        .dependOnInheritedWidgetOfExactType<_RefreshScope>()
        ?.refresher;
  }

  static SmartRefresherState? ofState(BuildContext? context) {
    return context!
        .dependOnInheritedWidgetOfExactType<_RefreshScope>()
        ?.refresherState;
  }

  @override
  State<StatefulWidget> createState() {
    return SmartRefresherState();
  }
}

class SmartRefresherState extends State<SmartRefresher> {
  RefreshPhysics? _physics;
  bool _updatePhysics = false;
  double viewportExtent = 0;
  bool _canDrag = true;

  final RefreshIndicator defaultHeader =
      defaultTargetPlatform == TargetPlatform.iOS
          ? ClassicHeader()
          : MaterialClassicHeader();

  final LoadIndicator defaultFooter = ClassicFooter();

  //build slivers from child Widget
  List<Widget>? _buildSliversByChild(BuildContext context, Widget? child,
      RefreshConfiguration? configuration) {
    List<Widget>? slivers;
    if (child is ScrollView) {
      if (child is BoxScrollView) {
        //avoid system inject padding when own indicator top or bottom
        Widget sliver = child.buildChildLayout(context);
        if (child.padding != null) {
          slivers = [SliverPadding(sliver: sliver, padding: child.padding!)];
        } else {
          slivers = [sliver];
        }
      } else {
        slivers = List.from(child.buildSlivers(context), growable: true);
      }
    } else if (child is! Scrollable) {
      slivers = [
        SliverRefreshBody(
          child: child ?? Container(),
        )
      ];
    }
    if (widget.enablePullDown || widget.enableTwoLevel) {
      slivers?.insert(
          0,
          widget.header ??
              (configuration?.headerBuilder != null
                  ? configuration?.headerBuilder!()
                  : null) ??
              defaultHeader);
    }
    //insert header or footer
    if (widget.enablePullUp) {
      slivers?.add(widget.footer ??
          (configuration?.footerBuilder != null
              ? configuration?.footerBuilder!()
              : null) ??
          defaultFooter);
    }

    return slivers;
  }

  ScrollPhysics _getScrollPhysics(
      RefreshConfiguration? conf, ScrollPhysics physics) {
    final bool isBouncingPhysics = physics is BouncingScrollPhysics ||
        (physics is AlwaysScrollableScrollPhysics &&
            ScrollConfiguration.of(context)
                    .getScrollPhysics(context)
                    .runtimeType ==
                BouncingScrollPhysics);
    return _physics = RefreshPhysics(
            dragSpeedRatio: conf?.dragSpeedRatio ?? 1,
            springDescription: conf?.springDescription ??
                const SpringDescription(
                  mass: 1,
                  stiffness: 364.71867768595047,
                  damping: 35.2,
                ),
            refresherState: this,
            enableScrollWhenTwoLevel: conf?.enableScrollWhenTwoLevel ?? true,
            updateFlag: _updatePhysics ? 0 : 1,
            enableScrollWhenRefreshCompleted:
                conf?.enableScrollWhenRefreshCompleted ?? false,
            maxUnderScrollExtent: conf?.maxUnderScrollExtent ??
                (isBouncingPhysics ? double.infinity : 0.0),
            maxOverScrollExtent: conf?.maxOverScrollExtent ??
                (isBouncingPhysics ? double.infinity : 60.0),
            topHitBoundary: conf?.topHitBoundary ??
                (isBouncingPhysics
                    ? double.infinity
                    : 0.0), // need to fix default value by ios or android later
            bottomHitBoundary: conf?.bottomHitBoundary ??
                (isBouncingPhysics ? double.infinity : 0.0))
        .applyTo(!_canDrag ? NeverScrollableScrollPhysics() : physics);
  }

  // build the customScrollView
  Widget? _buildBodyBySlivers(
      Widget? childView, List<Widget>? slivers, RefreshConfiguration? conf) {
    Widget? body;
    if (childView is! Scrollable) {
      bool? primary = widget.primary;
      Key? key;
      double? cacheExtent = widget.cacheExtent;

      Axis? scrollDirection = widget.scrollDirection;
      int? semanticChildCount = widget.semanticChildCount;
      bool? reverse = widget.reverse;
      ScrollController? scrollController = widget.scrollController;
      DragStartBehavior? dragStartBehavior = widget.dragStartBehavior;
      ScrollPhysics? physics = widget.physics;
      Key? center;
      double? anchor;
      ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
      String? restorationId;
      Clip? clipBehavior;

      if (childView is ScrollView) {
        primary = primary ?? childView.primary;
        cacheExtent = cacheExtent ?? childView.cacheExtent;
        key = key ?? childView.key;
        semanticChildCount = semanticChildCount ?? childView.semanticChildCount;
        reverse = reverse ?? childView.reverse;
        dragStartBehavior = dragStartBehavior ?? childView.dragStartBehavior;
        scrollDirection = scrollDirection ?? childView.scrollDirection;
        physics = physics ?? childView.physics;
        center = center ?? childView.center;
        anchor = anchor ?? childView.anchor;
        keyboardDismissBehavior =
            keyboardDismissBehavior ?? childView.keyboardDismissBehavior;
        restorationId = restorationId ?? childView.restorationId;
        clipBehavior = clipBehavior ?? childView.clipBehavior;
        scrollController = scrollController ?? childView.controller;
      }
      body = CustomScrollView(
        // ignore: DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE
        controller: scrollController,
        cacheExtent: cacheExtent,
        key: key,
        scrollDirection: scrollDirection ?? Axis.vertical,
        semanticChildCount: semanticChildCount,
        primary: primary,
        clipBehavior: clipBehavior ?? Clip.hardEdge,
        keyboardDismissBehavior:
            keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
        anchor: anchor ?? 0.0,
        restorationId: restorationId,
        center: center,
        physics:
            _getScrollPhysics(conf, physics ?? AlwaysScrollableScrollPhysics()),
        slivers: slivers!,
        dragStartBehavior: dragStartBehavior ?? DragStartBehavior.start,
        reverse: reverse ?? false,
      );
    } else
      body = Scrollable(
        physics: _getScrollPhysics(
            conf, childView.physics ?? AlwaysScrollableScrollPhysics()),
        controller: childView.controller,
        axisDirection: childView.axisDirection,
        semanticChildCount: childView.semanticChildCount,
        dragStartBehavior: childView.dragStartBehavior,
        viewportBuilder: (context, offset) {
          Viewport viewport =
              childView.viewportBuilder(context, offset) as Viewport;
          if (widget.enablePullDown) {
            viewport.children.insert(
                0,
                widget.header ??
                    (conf?.headerBuilder != null
                        ? conf?.headerBuilder!()
                        : null) ??
                    defaultHeader);
          }
          //insert header or footer
          if (widget.enablePullUp) {
            viewport.children.add(widget.footer ??
                (conf?.footerBuilder != null ? conf?.footerBuilder!() : null) ??
                defaultFooter);
          }
          return viewport;
        },
      );

    return body;
  }

  bool _ifNeedUpdatePhysics() {
    RefreshConfiguration? conf = RefreshConfiguration.of(context);
    if (conf == null || _physics == null) {
      return false;
    }

    if (conf.topHitBoundary != _physics!.topHitBoundary ||
        _physics!.bottomHitBoundary != conf.bottomHitBoundary ||
        conf.maxOverScrollExtent != _physics!.maxOverScrollExtent ||
        _physics!.maxUnderScrollExtent != conf.maxUnderScrollExtent ||
        _physics!.dragSpeedRatio != conf.dragSpeedRatio ||
        _physics!.enableScrollWhenTwoLevel != conf.enableScrollWhenTwoLevel ||
        _physics!.enableScrollWhenRefreshCompleted !=
            conf.enableScrollWhenRefreshCompleted) {
      return true;
    }
    return false;
  }

  void setCanDrag(bool canDrag) {
    if (_canDrag == canDrag) {
      return;
    }
    setState(() {
      _canDrag = canDrag;
    });
  }

  static final Expando<SmartRefresherState> _bindings =
      Expando<SmartRefresherState>('RefreshState binding');
  ScrollPosition? _position;
  int _bindingVersion = 0;
  final Set<String> _requests = <String>{};

  ScrollPosition? get position => _position;
  int get bindingVersion => _bindingVersion;

  void _bindRefreshState() {
    if (widget.state.isDisposed) {
      throw StateError('Cannot bind a disposed RefreshState.');
    }
    final owner = _bindings[widget.state];
    if (owner != null && owner != this) {
      throw StateError('A RefreshState can only bind one SmartRefresher.');
    }
    _bindings[widget.state] = this;
  }

  void onPositionUpdated(ScrollPosition newPosition) {
    if (_position == newPosition) return;
    _position?.isScrollingNotifier.removeListener(_listenScrollEnd);
    _position = newPosition;
    _position!.isScrollingNotifier.addListener(_listenScrollEnd);
  }

  void _listenScrollEnd() {
    if (_position?.outOfRange == true) {
      _position?.activity?.applyNewDimensions();
    }
  }

  void _invalidateRequests() {
    _bindingVersion++;
    _requests.clear();
    _canDrag = true;
  }

  bool _isCurrent(int version, RefreshState state) =>
      mounted &&
      version == _bindingVersion &&
      identical(widget.state, state) &&
      !state.isDisposed;

  StatefulElement? _findIndicator(BuildContext context, Type type) {
    StatefulElement? result;
    context.visitChildElements((element) {
      if ((type == RefreshIndicator && element.widget is RefreshIndicator) ||
          (type == LoadIndicator && element.widget is LoadIndicator)) {
        result = element as StatefulElement;
      }
      result ??= _findIndicator(element, type);
    });
    return result;
  }

  Future<void> requestRefresh({
    bool needMove = true,
    bool needCallback = true,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.linear,
  }) =>
      _requestIndicator(true, needMove, needCallback, duration, curve);

  Future<void> requestLoading({
    bool needMove = true,
    bool needCallback = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) =>
      _requestIndicator(false, needMove, needCallback, duration, curve);

  Future<void> _requestIndicator(bool refresh, bool needMove, bool needCallback,
      Duration duration, Curve curve) async {
    final state = widget.state;
    final position = _position;
    final enabled = refresh ? widget.enablePullDown : widget.enablePullUp;
    if (!mounted || state.isDisposed || position == null || !enabled) {
      throw StateError('The requested indicator is not mounted or enabled.');
    }
    final name = refresh ? 'refresh' : 'loading';
    if ((refresh ? state.isRefresh : state.isLoading) ||
        _requests.contains(name)) {
      return;
    }
    final element = _findIndicator(position.context.storageContext,
        refresh ? RefreshIndicator : LoadIndicator);
    if (element == null)
      throw StateError('The requested indicator is unavailable.');
    final indicator = element.state as IndicatorStateMixin;
    final notifier = refresh ? state.headerMode : state.footerMode;
    if (notifier == null)
      throw StateError('The requested state notifier is unavailable.');
    final version = _bindingVersion;
    var changed = false;
    var published = false;
    void listen() {
      changed = true;
    }

    notifier.addListener(listen);
    _requests.add(name);
    indicator.floating = true;
    indicator.update();
    if (needMove) setCanDrag(false);
    try {
      if (needMove) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!_isCurrent(version, state) || changed || !element.state.mounted)
          return;
        final currentPosition = _position;
        if (currentPosition == null) return;
        await currentPosition.animateTo(
          refresh
              ? currentPosition.minScrollExtent - 0.0001
              : currentPosition.maxScrollExtent,
          duration: duration,
          curve: curve,
        );
      } else {
        await Future<void>.value();
      }
      if (!_isCurrent(version, state) || changed || !element.state.mounted)
        return;
      if (!identical(notifier, refresh ? state.headerMode : state.footerMode))
        return;
      published = true;
      if (refresh) {
        state.startRefresh();
      } else {
        state.startLoading();
      }
      if (needCallback && _isCurrent(version, state)) {
        (refresh ? widget.onRefresh : widget.onLoading)?.call();
      }
    } finally {
      notifier.removeListener(listen);
      if (_isCurrent(version, state)) {
        _requests.remove(name);
        if (needMove) setCanDrag(true);
        if (!published && !(refresh ? state.isRefresh : state.isLoading)) {
          indicator.floating = false;
          indicator.update();
        }
      }
    }
  }

  Future<void> requestTwoLevel({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async {
    final state = widget.state;
    final position = _position;
    if (!mounted ||
        state.isDisposed ||
        position == null ||
        !widget.enableTwoLevel) {
      throw StateError('Two-level refresh is not mounted or enabled.');
    }
    if (_findIndicator(position.context.storageContext, RefreshIndicator) ==
        null) {
      throw StateError('The two-level header is unavailable.');
    }
    if (state.isTwoLevel || _requests.contains('twoLevel')) return;
    final version = _bindingVersion;
    final notifier = state.headerMode;
    if (notifier == null)
      throw StateError('The header state notifier is unavailable.');
    _requests.add('twoLevel');
    notifier.value = RefreshStatus.twoLevelOpening;
    var changed = false;
    void listen() {
      changed = true;
    }

    notifier.addListener(listen);
    try {
      widget.onTwoLevel?.call(true);
      await WidgetsBinding.instance.endOfFrame;
      if (!_isCurrent(version, state) ||
          changed ||
          !identical(state.headerMode, notifier) ||
          state.headerStatus != RefreshStatus.twoLevelOpening) return;
      await _position!.animateTo(0.0, duration: duration, curve: curve);
      if (_isCurrent(version, state) &&
          !changed &&
          identical(state.headerMode, notifier) &&
          state.headerStatus == RefreshStatus.twoLevelOpening) {
        state.headerMode!.value = RefreshStatus.twoLeveling;
      }
    } finally {
      notifier.removeListener(listen);
      if (_isCurrent(version, state)) _requests.remove('twoLevel');
    }
  }

  Future<void> twoLevelComplete({
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.linear,
  }) async {
    final state = widget.state;
    final position = _position;
    if (!mounted ||
        state.isDisposed ||
        position == null ||
        !widget.enableTwoLevel) {
      throw StateError('Two-level refresh is not mounted or enabled.');
    }
    if (_findIndicator(position.context.storageContext, RefreshIndicator) ==
        null) {
      throw StateError('The two-level header is unavailable.');
    }
    if (!state.isTwoLevel ||
        state.headerStatus == RefreshStatus.twoLevelClosing) return;
    final version = _bindingVersion;
    final notifier = state.headerMode;
    if (notifier == null)
      throw StateError('The header state notifier is unavailable.');
    notifier.value = RefreshStatus.twoLevelClosing;
    var changed = false;
    void listen() {
      changed = true;
    }

    notifier.addListener(listen);
    try {
      widget.onTwoLevel?.call(false);
      await WidgetsBinding.instance.endOfFrame;
      if (!_isCurrent(version, state) ||
          changed ||
          !identical(state.headerMode, notifier) ||
          state.headerStatus != RefreshStatus.twoLevelClosing) return;
      await _position!.animateTo(0.0, duration: duration, curve: curve);
      if (_isCurrent(version, state) &&
          !changed &&
          identical(state.headerMode, notifier) &&
          state.headerStatus == RefreshStatus.twoLevelClosing) {
        notifier.value = RefreshStatus.idle;
      }
    } finally {
      notifier.removeListener(listen);
    }
  }

  @override
  void didUpdateWidget(SmartRefresher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state ||
        widget.controller != oldWidget.controller) {
      _invalidateRequests();
      if (widget.state != oldWidget.state) {
        if (_bindings[oldWidget.state] == this) {
          _bindings[oldWidget.state] = null;
        }
        _bindRefreshState();
      }
      if (widget.controller != oldWidget.controller) {
        oldWidget.controller?._detach(this);
        widget.controller?._bindState(this);
      }
      _updatePhysics = !_updatePhysics;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ifNeedUpdatePhysics()) _updatePhysics = !_updatePhysics;
  }

  @override
  void initState() {
    super.initState();
    _bindRefreshState();
    widget.controller?._bindState(this);
    final version = _bindingVersion;
    if (widget.initialRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && version == _bindingVersion) requestRefresh();
      });
    }
  }

  @override
  void dispose() {
    _invalidateRequests();
    if (_bindings[widget.state] == this) _bindings[widget.state] = null;
    widget.controller?._detach(this);
    _position?.isScrollingNotifier.removeListener(_listenScrollEnd);
    _position = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RefreshConfiguration? configuration =
        RefreshConfiguration.of(context);
    Widget? body;
    if (widget.builder != null)
      body = widget.builder!(
          context,
          _getScrollPhysics(configuration, AlwaysScrollableScrollPhysics())
              as RefreshPhysics);
    else {
      List<Widget>? slivers =
          _buildSliversByChild(context, widget.child, configuration);
      body = _buildBodyBySlivers(widget.child, slivers, configuration);
    }
    if (configuration == null) {
      body = RefreshConfiguration(child: body!);
    }
    return _RefreshScope(
      refresher: widget,
      refresherState: this,
      bindingVersion: _bindingVersion,
      child: LayoutBuilder(
        builder: (c2, cons) {
          viewportExtent = cons.biggest.height;
          return body!;
        },
      ),
    );
  }
}

class _RefreshScope extends InheritedWidget {
  const _RefreshScope(
      {required this.refresher,
      required this.refresherState,
      required this.bindingVersion,
      required super.child});
  final SmartRefresher refresher;
  final SmartRefresherState refresherState;
  final int bindingVersion;

  @override
  bool updateShouldNotify(_RefreshScope oldWidget) =>
      oldWidget.refresher != refresher ||
      oldWidget.bindingVersion != bindingVersion;
}

/// Requests UI operations on one bound [SmartRefresher].
/// The caller owns this controller and its separate [RefreshState].
class RefreshController {
  SmartRefresherState? _refresherState;
  bool _disposed = false;

  RefreshController();

  ScrollPosition? get position => _refresherState?.position;

  SmartRefresherState get _boundState {
    if (_disposed || _refresherState == null || !_refresherState!.mounted) {
      throw StateError(
          'RefreshController is disposed or not bound to a SmartRefresher.');
    }
    return _refresherState!;
  }

  void _bindState(SmartRefresherState state) {
    if (_disposed)
      throw StateError('Cannot bind a disposed RefreshController.');
    if (_refresherState != null && _refresherState != state) {
      throw StateError('A RefreshController can only bind one SmartRefresher.');
    }
    _refresherState = state;
  }

  void _detach(SmartRefresherState state) {
    if (_refresherState == state) _refresherState = null;
  }

  Future<void> requestRefresh({
    bool needMove = true,
    bool needCallback = true,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.linear,
  }) async =>
      _boundState.requestRefresh(
          needMove: needMove,
          needCallback: needCallback,
          duration: duration,
          curve: curve);

  Future<void> requestLoading({
    bool needMove = true,
    bool needCallback = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async =>
      _boundState.requestLoading(
          needMove: needMove,
          needCallback: needCallback,
          duration: duration,
          curve: curve);

  Future<void> requestTwoLevel({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async =>
      _boundState.requestTwoLevel(duration: duration, curve: curve);

  Future<void> twoLevelComplete({
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.linear,
  }) async =>
      _boundState.twoLevelComplete(duration: duration, curve: curve);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final state = _refresherState;
    state?._invalidateRequests();
    if (state?.mounted == true) state!.setState(() {});
    _refresherState = null;
  }
}

/// Controls how SmartRefresher widgets behave in a subtree.the usage just like [ScrollConfiguration]
///
/// The refresh configuration determines smartRefresher some behaviours,global setting default indicator
///
/// see also:
///
/// * [SmartRefresher], a widget help attach the refresh and load more function
class RefreshConfiguration extends InheritedWidget {
  final Widget child;

  /// global default header builder
  final IndicatorBuilder? headerBuilder;

  /// global default footer builder
  final IndicatorBuilder? footerBuilder;

  /// custom spring animate
  final SpringDescription springDescription;

  /// If need to refreshing now when reaching triggerDistance
  final bool skipCanRefresh;

  /// if it should follow content for different state
  final ShouldFollowContent? shouldFooterFollowWhenNotFull;

  /// when listView data small(not enough one page) , it should be hide
  final bool hideFooterWhenNotFull;

  /// whether user can drag viewport when twoLeveling
  final bool enableScrollWhenTwoLevel;

  /// whether user can drag viewport when refresh complete and spring back
  final bool enableScrollWhenRefreshCompleted;

  /// whether trigger refresh by  BallisticScrollActivity
  final bool enableBallisticRefresh;

  /// whether trigger loading by  BallisticScrollActivity
  final bool enableBallisticLoad;

  /// whether footer can trigger load by reaching footerDistance when failed state
  final bool enableLoadingWhenFailed;

  /// whether footer can trigger load by reaching footerDistance when inNoMore state
  final bool enableLoadingWhenNoData;

  /// overScroll distance of trigger refresh
  final double headerTriggerDistance;

  ///	the overScroll distance of trigger twoLevel
  final double twiceTriggerDistance;

  /// Close the bottom crossing distance on the second floor, premise:enableScrollWhenTwoLevel is true
  final double closeTwoLevelDistance;

  /// the extentAfter distance of trigger loading
  final double footerTriggerDistance;

  /// the speed ratio when dragging overscroll ,compute=origin physics dragging speed *dragSpeedRatio
  final double dragSpeedRatio;

  /// max overScroll distance when out of edge
  final double? maxOverScrollExtent;

  /// 	max underScroll distance when out of edge
  final double? maxUnderScrollExtent;

  /// The boundary is located at the top edge and stops when inertia rolls over the boundary distance
  final double? topHitBoundary;

  /// The boundary is located at the bottom edge and stops when inertia rolls under the boundary distance
  final double? bottomHitBoundary;

  /// toggle of  refresh vibrate
  final bool enableRefreshVibrate;

  /// toggle of  loadmore vibrate
  final bool enableLoadMoreVibrate;

  RefreshConfiguration(
      {Key? key,
      required this.child,
      this.headerBuilder,
      this.footerBuilder,
      this.dragSpeedRatio = 1.0,
      this.shouldFooterFollowWhenNotFull,
      this.enableScrollWhenTwoLevel = true,
      this.enableLoadingWhenNoData = false,
      this.enableBallisticRefresh = false,
      this.springDescription = const SpringDescription(
        mass: 1,
        stiffness: 364.71867768595047,
        damping: 35.2,
      ),
      this.enableScrollWhenRefreshCompleted = false,
      this.enableLoadingWhenFailed = true,
      this.twiceTriggerDistance = 150.0,
      this.closeTwoLevelDistance = 80.0,
      this.skipCanRefresh = false,
      this.maxOverScrollExtent,
      this.enableBallisticLoad = true,
      this.maxUnderScrollExtent,
      this.headerTriggerDistance = 80.0,
      this.footerTriggerDistance = 15.0,
      this.hideFooterWhenNotFull = false,
      this.enableRefreshVibrate = false,
      this.enableLoadMoreVibrate = false,
      this.topHitBoundary,
      this.bottomHitBoundary})
      : assert(headerTriggerDistance > 0),
        assert(twiceTriggerDistance > 0),
        assert(closeTwoLevelDistance > 0),
        assert(dragSpeedRatio > 0),
        super(key: key, child: child);

  /// Construct RefreshConfiguration to copy attributes from ancestor nodes
  /// If the parameter is null, it will automatically help you to absorb the attributes of your ancestor Refresh Configuration, instead of having to copy them manually by yourself.
  ///
  /// it mostly use in some stiuation is different the other SmartRefresher in App
  RefreshConfiguration.copyAncestor({
    Key? key,
    required BuildContext context,
    required this.child,
    IndicatorBuilder? headerBuilder,
    IndicatorBuilder? footerBuilder,
    double? dragSpeedRatio,
    ShouldFollowContent? shouldFooterFollowWhenNotFull,
    bool? enableScrollWhenTwoLevel,
    bool? enableBallisticRefresh,
    bool? enableBallisticLoad,
    bool? enableLoadingWhenNoData,
    SpringDescription? springDescription,
    bool? enableScrollWhenRefreshCompleted,
    bool? enableLoadingWhenFailed,
    double? twiceTriggerDistance,
    double? closeTwoLevelDistance,
    bool? skipCanRefresh,
    double? maxOverScrollExtent,
    double? maxUnderScrollExtent,
    double? topHitBoundary,
    double? bottomHitBoundary,
    double? headerTriggerDistance,
    double? footerTriggerDistance,
    bool? enableRefreshVibrate,
    bool? enableLoadMoreVibrate,
    bool? hideFooterWhenNotFull,
  })  : assert(RefreshConfiguration.of(context) != null,
            "search RefreshConfiguration anscestor return null,please  Make sure that RefreshConfiguration is the ancestor of that element"),
        headerBuilder =
            headerBuilder ?? RefreshConfiguration.of(context)!.headerBuilder,
        footerBuilder =
            footerBuilder ?? RefreshConfiguration.of(context)!.footerBuilder,
        dragSpeedRatio =
            dragSpeedRatio ?? RefreshConfiguration.of(context)!.dragSpeedRatio,
        twiceTriggerDistance = twiceTriggerDistance ??
            RefreshConfiguration.of(context)!.twiceTriggerDistance,
        headerTriggerDistance = headerTriggerDistance ??
            RefreshConfiguration.of(context)!.headerTriggerDistance,
        footerTriggerDistance = footerTriggerDistance ??
            RefreshConfiguration.of(context)!.footerTriggerDistance,
        springDescription = springDescription ??
            RefreshConfiguration.of(context)!.springDescription,
        hideFooterWhenNotFull = hideFooterWhenNotFull ??
            RefreshConfiguration.of(context)!.hideFooterWhenNotFull,
        maxOverScrollExtent = maxOverScrollExtent ??
            RefreshConfiguration.of(context)!.maxOverScrollExtent,
        maxUnderScrollExtent = maxUnderScrollExtent ??
            RefreshConfiguration.of(context)!.maxUnderScrollExtent,
        topHitBoundary =
            topHitBoundary ?? RefreshConfiguration.of(context)!.topHitBoundary,
        bottomHitBoundary = bottomHitBoundary ??
            RefreshConfiguration.of(context)!.bottomHitBoundary,
        skipCanRefresh =
            skipCanRefresh ?? RefreshConfiguration.of(context)!.skipCanRefresh,
        enableScrollWhenRefreshCompleted = enableScrollWhenRefreshCompleted ??
            RefreshConfiguration.of(context)!.enableScrollWhenRefreshCompleted,
        enableScrollWhenTwoLevel = enableScrollWhenTwoLevel ??
            RefreshConfiguration.of(context)!.enableScrollWhenTwoLevel,
        enableBallisticRefresh = enableBallisticRefresh ??
            RefreshConfiguration.of(context)!.enableBallisticRefresh,
        enableBallisticLoad = enableBallisticLoad ??
            RefreshConfiguration.of(context)!.enableBallisticLoad,
        enableLoadingWhenNoData = enableLoadingWhenNoData ??
            RefreshConfiguration.of(context)!.enableLoadingWhenNoData,
        enableLoadingWhenFailed = enableLoadingWhenFailed ??
            RefreshConfiguration.of(context)!.enableLoadingWhenFailed,
        closeTwoLevelDistance = closeTwoLevelDistance ??
            RefreshConfiguration.of(context)!.closeTwoLevelDistance,
        enableRefreshVibrate = enableRefreshVibrate ??
            RefreshConfiguration.of(context)!.enableRefreshVibrate,
        enableLoadMoreVibrate = enableLoadMoreVibrate ??
            RefreshConfiguration.of(context)!.enableLoadMoreVibrate,
        shouldFooterFollowWhenNotFull = shouldFooterFollowWhenNotFull ??
            RefreshConfiguration.of(context)!.shouldFooterFollowWhenNotFull,
        super(key: key, child: child);

  static RefreshConfiguration? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RefreshConfiguration>();
  }

  @override
  bool updateShouldNotify(RefreshConfiguration oldWidget) {
    return skipCanRefresh != oldWidget.skipCanRefresh ||
        hideFooterWhenNotFull != oldWidget.hideFooterWhenNotFull ||
        dragSpeedRatio != oldWidget.dragSpeedRatio ||
        enableScrollWhenRefreshCompleted !=
            oldWidget.enableScrollWhenRefreshCompleted ||
        enableBallisticRefresh != oldWidget.enableBallisticRefresh ||
        enableScrollWhenTwoLevel != oldWidget.enableScrollWhenTwoLevel ||
        closeTwoLevelDistance != oldWidget.closeTwoLevelDistance ||
        footerTriggerDistance != oldWidget.footerTriggerDistance ||
        headerTriggerDistance != oldWidget.headerTriggerDistance ||
        twiceTriggerDistance != oldWidget.twiceTriggerDistance ||
        maxUnderScrollExtent != oldWidget.maxUnderScrollExtent ||
        oldWidget.maxOverScrollExtent != maxOverScrollExtent ||
        enableBallisticRefresh != oldWidget.enableBallisticRefresh ||
        enableLoadingWhenFailed != oldWidget.enableLoadingWhenFailed ||
        topHitBoundary != oldWidget.topHitBoundary ||
        enableRefreshVibrate != oldWidget.enableRefreshVibrate ||
        enableLoadMoreVibrate != oldWidget.enableLoadMoreVibrate ||
        bottomHitBoundary != oldWidget.bottomHitBoundary;
  }
}
