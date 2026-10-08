/*
    Author: Jpeng
    Email: peng8350@gmail.com
    createTime:2018-05-02 14:39
 */
// ignore_for_file: INVALID_USE_OF_PROTECTED_MEMBER
// ignore_for_file: INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:pull_to_refresh/src/internals/slivers.dart';

/// a scrollPhysics for config refresh scroll effect,enable viewport out of edge whatever physics it is
/// in [ClampingScrollPhysics], it doesn't allow to flip out of edge,but in RefreshPhysics,it will allow to do that,
/// by parent physics passing,it also can attach the different of iOS and Android different scroll effect
/// it also handles interception scrolling when refreshed, or when the second floor is open and closed.
/// with [SpringDescription] passing,you can custom spring back animate,the more paramter can be setting in [RefreshConfiguration]
///
/// see also:
///
/// * [RefreshConfiguration], a configuration for Controlling how SmartRefresher widgets behave in a subtree
// ignore: MUST_BE_IMMUTABLE
class RefreshPhysics extends ScrollPhysics {
  // Ownership belongs to an activity, not to the refresher or position. A
  // replacement drag, jump or driven animation never inherits this entry.
  static final _headerSettlements =
      Expando<_HeaderSettlement>('header settlement');

  static void beginHeaderSettlement(
      ScrollPosition position, bool Function() isCurrent) {
    final activity = position.activity;
    if (activity != null) {
      _headerSettlements[activity] = _HeaderSettlement(isCurrent);
    }
  }

  final double? maxOverScrollExtent, maxUnderScrollExtent;
  final double? topHitBoundary, bottomHitBoundary;
  final SpringDescription? springDescription;
  final double? dragSpeedRatio;
  final bool? enableScrollWhenTwoLevel, enableScrollWhenRefreshCompleted;
  final SmartRefresherState? refresherState;
  final int? updateFlag;

  /// find out the viewport when bouncing,for compute the layoutExtent in header and footer
  /// This does not have any impact on performance. it only  execute once
  RenderViewport? viewportRender;
  ScrollPosition? _viewportPosition;

  void _resolveViewport() {
    final position = refresherState?.position;
    if (!identical(position, _viewportPosition) ||
        viewportRender?.attached != true) {
      _viewportPosition = position;
      viewportRender = findViewport(position?.context.storageContext);
    }
  }

  /// Creates scroll physics that bounce back from the edge.
  RefreshPhysics(
      {ScrollPhysics? parent,
      this.updateFlag,
      this.maxUnderScrollExtent,
      this.springDescription,
      this.refresherState,
      this.dragSpeedRatio,
      this.topHitBoundary,
      this.bottomHitBoundary,
      this.enableScrollWhenRefreshCompleted,
      this.enableScrollWhenTwoLevel,
      this.maxOverScrollExtent})
      : super(parent: parent);

  @override
  RefreshPhysics applyTo(ScrollPhysics? ancestor) {
    return RefreshPhysics(
        parent: buildParent(ancestor),
        updateFlag: updateFlag,
        springDescription: springDescription,
        dragSpeedRatio: dragSpeedRatio,
        enableScrollWhenTwoLevel: enableScrollWhenTwoLevel,
        topHitBoundary: topHitBoundary,
        bottomHitBoundary: bottomHitBoundary,
        refresherState: refresherState,
        enableScrollWhenRefreshCompleted: enableScrollWhenRefreshCompleted,
        maxUnderScrollExtent: maxUnderScrollExtent,
        maxOverScrollExtent: maxOverScrollExtent);
  }

  RenderViewport? findViewport(BuildContext? context) {
    if (context == null) {
      return null;
    }
    RenderViewport? result;
    context.visitChildElements((Element e) {
      final RenderObject? renderObject = e.findRenderObject();
      if (renderObject is RenderViewport) {
        assert(result == null);
        result = renderObject;
      } else {
        result = findViewport(e);
      }
    });
    return result;
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (parent is NeverScrollableScrollPhysics) {
      return false;
    }
    return true;
  }

  //  It seem that it was odd to do so,but I have no choose to do this for updating the state value(enablePullDown and enablePullUp),
  // in Scrollable.dart _shouldUpdatePosition method,it use physics.runtimeType to check if the two physics is the same,this
  // will lead to whether the newPhysics should replace oldPhysics,If flutter can provide a method such as "shouldUpdate",
  // It can work perfectly.
  @override
  Type get runtimeType {
    if (updateFlag == 0) {
      return RefreshPhysics;
    } else {
      return BouncingScrollPhysics;
    }
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    _resolveViewport();
    if (refresherState!.widget.state.headerMode.value ==
        RefreshStatus.twoLeveling) {
      if (offset > 0.0) {
        return parent!.applyPhysicsToUserOffset(position, offset);
      }
    } else {
      if ((offset > 0.0 &&
              viewportRender?.firstChild is! RenderSliverRefresh) ||
          (offset < 0 && viewportRender?.lastChild is! RenderSliverLoading)) {
        return parent!.applyPhysicsToUserOffset(position, offset);
      }
    }
    if (position.outOfRange ||
        refresherState!.widget.state.headerMode.value ==
            RefreshStatus.twoLeveling) {
      final double overscrollPastStart =
          math.max(position.minScrollExtent - position.pixels, 0.0);
      final double overscrollPastEnd = math.max(
          position.pixels -
              (refresherState!.widget.state.headerMode.value ==
                      RefreshStatus.twoLeveling
                  ? 0.0
                  : position.maxScrollExtent),
          0.0);
      final double overscrollPast =
          math.max(overscrollPastStart, overscrollPastEnd);
      final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
          (overscrollPastEnd > 0.0 && offset > 0.0);

      final double friction = easing
          // Apply less resistance when easing the overscroll vs tensioning.
          ? frictionFactor(
              (overscrollPast - offset.abs()) / position.viewportDimension)
          : frictionFactor(overscrollPast / position.viewportDimension);
      final double direction = offset.sign;
      return direction *
          _applyFriction(overscrollPast, offset.abs(), friction) *
          (dragSpeedRatio ?? 1.0);
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) return absDelta * gamma;
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  double frictionFactor(double overscrollFraction) =>
      0.52 * math.pow(1 - overscrollFraction, 2);

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final ScrollPosition scrollPosition = position as ScrollPosition;
    _resolveViewport();
    bool notFull = position.minScrollExtent == position.maxScrollExtent;
    final bool enablePullDown = viewportRender == null
        ? false
        : viewportRender!.firstChild is RenderSliverRefresh;
    final bool enablePullUp = viewportRender == null
        ? false
        : viewportRender!.lastChild is RenderSliverLoading;
    if (refresherState!.widget.state.headerMode.value ==
        RefreshStatus.twoLeveling) {
      if (position.pixels - value > 0.0) {
        return parent!.applyBoundaryConditions(position, value);
      }
    } else {
      if ((position.pixels - value > 0.0 && !enablePullDown) ||
          (position.pixels - value < 0 && !enablePullUp)) {
        return parent!.applyBoundaryConditions(position, value);
      }
    }
    double topExtra = 0.0;
    double bottomExtra = 0.0;
    if (enablePullDown) {
      final RenderSliverRefresh sliverHeader =
          viewportRender!.firstChild as RenderSliverRefresh;
      topExtra = sliverHeader.layoutResult?.expanded != false
          ? 0.0
          : math.max(
              sliverHeader.layoutResult?.effectiveExtent ?? 0.0,
              RefreshConfiguration.of(scrollPosition.context.storageContext)!
                  .headerTriggerDistance);
    }
    if (enablePullUp) {
      final RenderSliverLoading sliverFooter =
          viewportRender!.lastChild as RenderSliverLoading;
      bottomExtra = (!notFull &&
                  (sliverFooter.layoutResult?.occupiedExtent ?? 0) != 0) ||
              (notFull &&
                  refresherState!.widget.state.footerStatus ==
                      LoadStatus.noMore &&
                  !RefreshConfiguration.of(
                          refresherState!.position!.context.storageContext)!
                      .enableLoadingWhenNoData) ||
              (notFull &&
                  (RefreshConfiguration.of(
                              refresherState!.position!.context.storageContext)
                          ?.hideFooterWhenNotFull ??
                      false))
          ? 0.0
          : sliverFooter.layoutResult?.hidden != false
              ? 0.0
              : math.max(
                  sliverFooter.layoutResult!.effectiveExtent,
                  math.max(
                      0.0,
                      -RefreshConfiguration.of(
                              scrollPosition.context.storageContext)!
                          .footerTriggerDistance));
    }
    final double topBoundary =
        position.minScrollExtent - maxOverScrollExtent! - topExtra;
    final double bottomBoundary =
        position.maxScrollExtent + maxUnderScrollExtent! + bottomExtra;

    if (maxOverScrollExtent != double.infinity &&
        position.pixels <= topBoundary &&
        value < position.pixels) {
      return value - position.pixels;
    }
    if (maxUnderScrollExtent != double.infinity &&
        position.pixels >= bottomBoundary &&
        value > position.pixels) {
      return value - position.pixels;
    }

    if (scrollPosition.activity is BallisticScrollActivity) {
      if (topHitBoundary != double.infinity) {
        if (value < -topHitBoundary! && -topHitBoundary! <= position.pixels) {
          // hit top edge
          return value + topHitBoundary!;
        }
      }
      if (bottomHitBoundary != double.infinity) {
        if (position.pixels < bottomHitBoundary! + position.maxScrollExtent &&
            bottomHitBoundary! + position.maxScrollExtent < value) {
          // hit bottom edge
          return value - bottomHitBoundary! - position.maxScrollExtent;
        }
      }
    }
    if (maxOverScrollExtent != double.infinity &&
        value < topBoundary &&
        topBoundary < position.pixels) // hit top edge
      return value - topBoundary;
    if (maxUnderScrollExtent != double.infinity &&
        position.pixels < bottomBoundary &&
        bottomBoundary < value) {
      // hit bottom edge
      return value - bottomBoundary;
    }

    // check user is dragging,it is import,some devices may not bounce with different frame and time,bouncing return the different velocity
    if (scrollPosition.activity is DragScrollActivity) {
      if (maxOverScrollExtent != double.infinity &&
          value < position.pixels &&
          position.pixels <= topBoundary) // underscroll
        return value - position.pixels;
      if (maxUnderScrollExtent != double.infinity &&
          bottomBoundary <= position.pixels &&
          position.pixels < value) // overscroll
        return value - position.pixels;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    _resolveViewport();

    final bool enablePullDown = viewportRender == null
        ? false
        : viewportRender!.firstChild is RenderSliverRefresh;
    final bool enablePullUp = viewportRender == null
        ? false
        : viewportRender!.lastChild is RenderSliverLoading;
    final scrollPosition = position as ScrollPosition;
    final activity = scrollPosition.activity;
    final settlement = activity == null ? null : _headerSettlements[activity];
    if (enablePullDown &&
        settlement?.isCurrent == true &&
        (viewportRender!.firstChild as RenderSliverRefresh)
                .layoutResult
                ?.expanded ==
            true) {
      final target = position.minScrollExtent;
      final tolerance = toleranceFor(position);
      if ((position.pixels - target).abs() <= tolerance.distance &&
          velocity.abs() <= tolerance.velocity) {
        settlement!.finish();
      } else {
        // The old return velocity may now point away from the new edge after
        // layout expands the header. Do not carry that recoil into settlement.
        return _HeaderSettlementSimulation(
          springDescription ?? spring,
          position.pixels,
          target,
          velocity * (target - position.pixels) < 0 ? 0 : velocity * 0.91,
          position: scrollPosition,
          settlement: settlement!,
          tolerance: tolerance,
        );
      }
    }
    if (refresherState!.widget.state.headerMode.value ==
        RefreshStatus.twoLeveling) {
      if (velocity < 0.0) {
        return parent!.createBallisticSimulation(position, velocity);
      }
    } else if (!position.outOfRange) {
      if ((velocity < 0.0 && !enablePullDown) ||
          (velocity > 0 && !enablePullUp)) {
        return parent!.createBallisticSimulation(position, velocity);
      }
    }
    if ((position.pixels > 0 &&
            refresherState!.widget.state.headerMode.value ==
                RefreshStatus.twoLeveling) ||
        position.outOfRange) {
      return BouncingScrollSimulation(
        spring: springDescription ?? spring,
        position: position.pixels,
        // -1.0 avoid stop springing back ,and release gesture
        velocity: velocity * 0.91,
        leadingExtent: position.minScrollExtent,
        trailingExtent: refresherState!.widget.state.headerMode.value ==
                RefreshStatus.twoLeveling
            ? 0.0
            : position.maxScrollExtent,
        tolerance: toleranceFor(position),
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

class _HeaderSettlement {
  _HeaderSettlement(this._isCurrent);

  final bool Function() _isCurrent;
  bool _active = true;

  bool get isCurrent {
    if (_active && !_isCurrent()) _active = false;
    return _active;
  }

  void finish() => _active = false;
}

class _HeaderSettlementSimulation extends ScrollSpringSimulation {
  _HeaderSettlementSimulation(
      super.spring, super.start, super.end, super.velocity,
      {required this.position,
      required this.settlement,
      required super.tolerance});

  final ScrollPosition position;
  final _HeaderSettlement settlement;
  BallisticScrollActivity? _owner;

  @override
  double dx(double time) {
    // BallisticScrollActivity reads this velocity before rebuilding itself
    // for new dimensions. Associate the running simulation with that actual
    // activity, including a dimension change before its first animation tick.
    final activity = position.activity;
    if (settlement.isCurrent && activity is BallisticScrollActivity) {
      _owner ??= activity;
      if (identical(activity, _owner)) {
        RefreshPhysics._headerSettlements[activity] = settlement;
      }
    }
    return super.dx(time);
  }
}
