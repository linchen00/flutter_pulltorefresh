/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time: 2019/5/2 下午5:09
 */

import 'package:flutter/widgets.dart';
import 'dart:math' as Math;
import 'package:flutter/rendering.dart';
import '../smart_refresher.dart';

/// One committed layout result shared by state, physics and UI requests.
class IndicatorLayoutResult {
  const IndicatorLayoutResult(
      {required this.contentExtent,
      required this.effectiveExtent,
      required this.occupiedExtent,
      required this.hidden,
      required this.expanded});
  final double contentExtent;
  final double effectiveExtent;
  final double occupiedExtent;
  final bool hidden;
  final bool expanded;
}

mixin IndicatorExtentLayout on RenderSliverSingleBoxAdapter {
  double? _configuredExtent;
  double _contentExtent = 0;
  IndicatorLayoutResult? layoutResult;
  bool layoutPending = true;

  double? get configuredExtent => _configuredExtent;
  set configuredExtent(double? value) {
    validateExtent(value);
    if (_configuredExtent == value) return;
    _configuredExtent = value;
    markNeedsLayout();
  }

  static void validateExtent(double? value) {
    if (value != null && (!value.isFinite || value < 0)) {
      throw FlutterError(
          'Indicator extent must be finite and non-negative, or null.');
    }
  }

  double get effectiveExtent => _configuredExtent ?? _contentExtent;

  double measureContent() {
    layoutPending = true;
    child?.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    _contentExtent = child == null
        ? 0
        : constraints.axis == Axis.vertical
            ? child!.size.height
            : child!.size.width;
    validateExtent(_contentExtent);
    return _contentExtent;
  }

  void commitLayout(double occupiedExtent,
      {bool hidden = false, required bool expanded}) {
    if (layoutResult?.hidden != hidden || layoutResult?.expanded != expanded) {
      markNeedsSemanticsUpdate();
    }
    layoutPending = false;
    layoutResult = IndicatorLayoutResult(
        contentExtent: _contentExtent,
        effectiveExtent: effectiveExtent,
        occupiedExtent: occupiedExtent,
        hidden: hidden,
        expanded: expanded);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (layoutResult != null && !layoutResult!.hidden && geometry!.visible) {
      super.visitChildrenForSemantics(visitor);
    }
  }
}

///  Render header sliver widget
class SliverRefresh extends SingleChildRenderObjectWidget {
  const SliverRefresh({
    Key? key,
    this.paintOffsetY,
    this.refreshIndicatorLayoutExtent = 0.0,
    this.floating = false,
    Widget? child,
    this.refreshStyle,
  })  : assert(refreshIndicatorLayoutExtent == null ||
            (refreshIndicatorLayoutExtent >= 0.0 &&
                refreshIndicatorLayoutExtent < double.infinity)),
        super(key: key, child: child);

  /// The amount of space the indicator should occupy in the sliver in a
  /// resting state when in the refreshing mode.
  final double? refreshIndicatorLayoutExtent;

  /// _RenderSliverRefresh will paint the child in the available
  /// space either way but this instructs the _RenderSliverRefresh
  /// on whether to also occupy any layoutExtent space or not.
  final bool floating;

  /// header indicator display style
  final RefreshStyle? refreshStyle;

  /// headerOffset	Head indicator layout deviation Y coordinates, mostly for FrontStyle
  final double? paintOffsetY;

  @override
  RenderSliverRefresh createRenderObject(BuildContext context) {
    return RenderSliverRefresh(
      refreshIndicatorExtent: refreshIndicatorLayoutExtent,
      hasLayoutExtent: floating,
      paintOffsetY: paintOffsetY,
      refreshStyle: refreshStyle,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSliverRefresh renderObject) {
    renderObject
      ..configuredExtent = refreshIndicatorLayoutExtent
      ..hasLayoutExtent = floating
      ..refreshStyle = refreshStyle
      ..paintOffsetY = paintOffsetY;
  }
}

class RenderSliverRefresh extends RenderSliverSingleBoxAdapter
    with IndicatorExtentLayout {
  RenderSliverRefresh(
      {required double? refreshIndicatorExtent,
      required bool hasLayoutExtent,
      RenderBox? child,
      double? paintOffsetY,
      RefreshStyle? refreshStyle})
      : _paintOffsetY = paintOffsetY,
        _refreshStyle = refreshStyle,
        _hasLayoutExtent = hasLayoutExtent {
    configuredExtent = refreshIndicatorExtent;
    this.child = child;
  }

  RefreshStyle? _refreshStyle;
  RefreshStyle? get refreshStyle => _refreshStyle;
  set refreshStyle(RefreshStyle? value) {
    if (_refreshStyle == value) return;
    _refreshStyle = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  // The amount of layout space the indicator should occupy in the sliver in a
  // resting state when in the refreshing mode.
  double get refreshIndicatorLayoutExtent => effectiveExtent;
  double? _paintOffsetY;
  double? get paintOffsetY => _paintOffsetY;
  set paintOffsetY(double? value) {
    if (_paintOffsetY == value) return;
    _paintOffsetY = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  // The child box will be laid out and painted in the available space either
  // way but this determines whether to also occupy any
  // [SliverGeometry.layoutExtent] space or not.
  bool get hasLayoutExtent => _hasLayoutExtent;
  bool _hasLayoutExtent;

  set hasLayoutExtent(bool value) {
    if (value == _hasLayoutExtent) return;
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  double _previousLayoutExtent = 0.0;

  // Preserve the body anchor during overscroll or body scrolling, and the
  // relative position inside the header while the viewport displays it.
  // A collapsed header's leading edge maps to the expanded header's leading
  // edge, so publishing refreshing at rest reveals it without scrolling.
  double _scrollOffsetCorrection(double layoutExtent) {
    final pixels = (parent as RenderViewportBase).offset.pixels;
    final delta = layoutExtent - _previousLayoutExtent;
    if (pixels < 0.0 || pixels > _previousLayoutExtent) return delta;

    final headerFraction =
        _previousLayoutExtent > 0.0 ? pixels / _previousLayoutExtent : 0.0;
    return headerFraction * layoutExtent - pixels;
  }

  @override
  void performResize() {
    super.performResize();
  }

  @override
  double get centerOffsetAdjustment {
    if (refreshStyle == RefreshStyle.Front) {
      final RenderViewportBase renderViewport =
          parent as RenderViewportBase<ContainerParentDataMixin<RenderSliver>>;
      return Math.max(0.0, -renderViewport.offset.pixels);
    }
    return 0.0;
  }

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    if (refreshStyle == RefreshStyle.Front) {
      final RenderViewportBase renderViewport =
          parent as RenderViewportBase<ContainerParentDataMixin<RenderSliver>>;
      super.layout(
          (constraints as SliverConstraints)
              .copyWith(overlap: Math.min(0.0, renderViewport.offset.pixels)),
          parentUsesSize: true);
    } else {
      super.layout(constraints, parentUsesSize: parentUsesSize);
    }
  }

  @override
  void debugAssertDoesMeetConstraints() {
    assert(geometry!.debugAssertIsValid(informationCollector: () sync* {
      yield describeForError(
          'The RenderSliver that returned the offending geometry was');
    }));
    assert(() {
      if (geometry!.paintExtent > constraints.remainingPaintExtent) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'SliverGeometry has a paintOffset that exceeds the remainingPaintExtent from the constraints.'),
          describeForError(
              'The render object whose geometry violates the constraints is the following'),
          ErrorDescription(
            'The paintExtent must cause the child sliver to paint within the viewport, and so '
            'cannot exceed the remainingPaintExtent.',
          ),
        ]);
      }
      return true;
    }());
  }

  @override
  void performLayout() {
    final double boxExtent = measureContent();
    // The new layout extent this sliver should now have.
    final double layoutExtent =
        (_hasLayoutExtent && refreshStyle != RefreshStyle.Front ? 1.0 : 0.0) *
            effectiveExtent;
    // Changing display style and changing size use the same body anchor rule.
    if (layoutExtent != _previousLayoutExtent) {
      final correction = _scrollOffsetCorrection(layoutExtent);
      _previousLayoutExtent = layoutExtent;
      if (correction != 0.0) {
        geometry = SliverGeometry(scrollOffsetCorrection: correction);
        return;
      }
    }
    final active = constraints.overlap < 0.0 || _hasLayoutExtent;
    final double overscrolledExtent =
        -(parent as RenderViewportBase).offset.pixels;

    if (active) {
      double needPaintExtent = Math.min(
          Math.max(
            Math.max(
                    (constraints.axisDirection == AxisDirection.up ||
                            constraints.axisDirection == AxisDirection.down)
                        ? child!.size.height
                        : child!.size.width,
                    refreshStyle == RefreshStyle.Front && _hasLayoutExtent
                        ? effectiveExtent
                        : layoutExtent) -
                constraints.scrollOffset,
            0.0,
          ),
          constraints.remainingPaintExtent);
      if (refreshStyle == RefreshStyle.Behind) {
        needPaintExtent = Math.min(
            needPaintExtent, Math.max(0.0, overscrolledExtent + layoutExtent));
      }
      switch (refreshStyle) {
        case RefreshStyle.Follow:
          geometry = SliverGeometry(
            scrollExtent: layoutExtent,
            paintOrigin: -boxExtent - constraints.scrollOffset + layoutExtent,
            paintExtent: needPaintExtent,
            hitTestExtent: needPaintExtent,
            hasVisualOverflow: overscrolledExtent < boxExtent,
            maxPaintExtent: needPaintExtent,
            layoutExtent: Math.min(needPaintExtent,
                Math.max(layoutExtent - constraints.scrollOffset, 0.0)),
          );

          break;
        case RefreshStyle.Behind:
          geometry = SliverGeometry(
            scrollExtent: layoutExtent,
            paintOrigin: -overscrolledExtent - constraints.scrollOffset,
            paintExtent: needPaintExtent,
            maxPaintExtent: needPaintExtent,
            layoutExtent: Math.min(needPaintExtent,
                Math.max(layoutExtent - constraints.scrollOffset, 0.0)),
          );
          break;
        case RefreshStyle.UnFollow:
          geometry = SliverGeometry(
            scrollExtent: layoutExtent,
            paintOrigin: Math.min(
                -overscrolledExtent - constraints.scrollOffset,
                -boxExtent - constraints.scrollOffset + layoutExtent),
            paintExtent: needPaintExtent,
            hasVisualOverflow: overscrolledExtent < boxExtent,
            maxPaintExtent: needPaintExtent,
            layoutExtent: Math.min(needPaintExtent,
                Math.max(layoutExtent - constraints.scrollOffset, 0.0)),
          );

          break;
        case RefreshStyle.Front:
          geometry = SliverGeometry(
            paintExtent: needPaintExtent,
            layoutExtent: 0,
            maxPaintExtent: needPaintExtent,
            hitTestExtent: needPaintExtent,
            visible: needPaintExtent > 0,
            hasVisualOverflow: true,
          );
          break;
        case null:
          break;
      }
      // The viewport already positions this sliver by its paint origin.
      final data = child!.parentData as SliverPhysicalParentData;
      final reverse = constraints.axisDirection == AxisDirection.up ||
          constraints.axisDirection == AxisDirection.left;
      final shift = reverse ? geometry!.paintExtent - boxExtent : 0.0;
      data.paintOffset = constraints.axis == Axis.vertical
          ? Offset(0, shift)
          : Offset(shift, 0);
    } else {
      geometry = SliverGeometry.zero;
    }
    commitLayout(refreshStyle == RefreshStyle.Front ? 0 : layoutExtent,
        hidden: !active, expanded: hasLayoutExtent);
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    final reverse = constraints.axisDirection == AxisDirection.up ||
        constraints.axisDirection == AxisDirection.left;
    return reverse ? -(paintOffsetY ?? 0) : paintOffsetY ?? 0;
  }

  @override
  void paint(PaintingContext paintContext, Offset offset) {
    if (layoutResult == null || layoutResult!.hidden || !geometry!.visible)
      return;
    final shifted = offset +
        (constraints.axis == Axis.vertical
            ? Offset(0, paintOffsetY ?? 0)
            : Offset(paintOffsetY ?? 0, 0));
    if (refreshStyle == RefreshStyle.Behind) {
      final clip = constraints.axis == Axis.vertical
          ? Rect.fromLTWH(
              0, 0, constraints.crossAxisExtent, geometry!.paintExtent)
          : Rect.fromLTWH(
              0, 0, geometry!.paintExtent, constraints.crossAxisExtent);
      paintContext.pushClipRect(needsCompositing, shifted, clip,
          (context, offset) => super.paint(context, offset));
    } else {
      super.paint(paintContext, shifted);
    }
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    if (refreshStyle != RefreshStyle.Behind) return null;
    return constraints.axis == Axis.vertical
        ? Rect.fromLTWH(
            0, 0, constraints.crossAxisExtent, geometry!.paintExtent)
        : Rect.fromLTWH(
            0, 0, geometry!.paintExtent, constraints.crossAxisExtent);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    super.applyPaintTransform(child, transform);
    if (constraints.axis == Axis.vertical) {
      transform.translateByDouble(0.0, paintOffsetY ?? 0, 0, 1);
    } else {
      transform.translateByDouble(paintOffsetY ?? 0, 0.0, 0, 1);
    }
  }
}

/// Render footer sliver widget
class SliverLoading extends SingleChildRenderObjectWidget {
  /// when not full one page,whether it should be hide and disable loading
  final bool? hideWhenNotFull;
  final bool? floating;

  /// load state
  final LoadStatus? mode;
  final double? layoutExtent;

  /// when not full one page,whether it should follow content
  final bool? shouldFollowContent;

  SliverLoading({
    Key? key,
    this.mode,
    this.floating,
    this.shouldFollowContent,
    this.layoutExtent,
    this.hideWhenNotFull,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  RenderSliverLoading createRenderObject(BuildContext context) {
    return RenderSliverLoading(
        hideWhenNotFull: hideWhenNotFull,
        mode: mode,
        hasLayoutExtent: floating,
        shouldFollowContent: shouldFollowContent,
        layoutExtent: layoutExtent);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSliverLoading renderObject) {
    renderObject
      ..mode = mode
      ..hasLayoutExtent = floating!
      ..configuredExtent = layoutExtent
      ..shouldFollowContent = shouldFollowContent
      ..hideWhenNotFull = hideWhenNotFull;
  }
}

class RenderSliverLoading extends RenderSliverSingleBoxAdapter
    with IndicatorExtentLayout {
  RenderSliverLoading({
    RenderBox? child,
    LoadStatus? mode,
    double? layoutExtent,
    bool? hasLayoutExtent,
    bool? shouldFollowContent,
    bool? hideWhenNotFull,
  })  : _mode = mode,
        _shouldFollowContent = shouldFollowContent,
        _hideWhenNotFull = hideWhenNotFull {
    _hasLayoutExtent = hasLayoutExtent;
    configuredExtent = layoutExtent;
    this.child = child;
  }

  bool? _shouldFollowContent;
  bool? get shouldFollowContent => _shouldFollowContent;
  set shouldFollowContent(bool? value) {
    if (value == _shouldFollowContent) return;
    _shouldFollowContent = value;
    markNeedsLayout();
  }

  bool? _hideWhenNotFull;
  bool? get hideWhenNotFull => _hideWhenNotFull;
  set hideWhenNotFull(bool? value) {
    if (value == _hideWhenNotFull) return;
    _hideWhenNotFull = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  LoadStatus? _mode;
  LoadStatus? get mode => _mode;
  set mode(LoadStatus? value) {
    if (value == _mode) return;
    _mode = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  double get layoutExtent => effectiveExtent;

  bool get hasLayoutExtent => _hasLayoutExtent!;
  bool? _hasLayoutExtent;

  set hasLayoutExtent(bool value) {
    if (value == _hasLayoutExtent) return;
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  bool _computeIfFull(SliverConstraints cons) {
    final RenderViewport viewport = parent as RenderViewport;
    RenderSliver? sliverP = viewport.firstChild;
    double totalScrollExtent = cons.precedingScrollExtent;
    while (sliverP != this) {
      if (sliverP is RenderSliverRefresh) {
        totalScrollExtent -= sliverP.geometry!.scrollExtent;
        break;
      }
      sliverP = viewport.childAfter(sliverP!);
    }
    // consider about footer layoutExtent,it should be subtracted it's height
    return totalScrollExtent > cons.viewportMainAxisExtent;
  }

  //  many sitiuation: 1. reverse 2. not reverse
  // 3. follow content 4. unfollow content
  //5. not full 6. full
  double? computePaintOrigin(double? layoutExtent, bool reverse, bool follow) {
    if (follow) {
      if (reverse) {
        return layoutExtent;
      }
      return 0.0;
    } else {
      if (reverse) {
        return Math.max(
                constraints.viewportMainAxisExtent -
                    constraints.precedingScrollExtent,
                0.0) +
            layoutExtent!;
      } else {
        return Math.max(
            constraints.viewportMainAxisExtent -
                constraints.precedingScrollExtent,
            0.0);
      }
    }
  }

  @override
  void debugAssertDoesMeetConstraints() {
    assert(geometry!.debugAssertIsValid(informationCollector: () sync* {
      yield describeForError(
          'The RenderSliver that returned the offending geometry was');
    }));
    assert(() {
      if (geometry!.paintExtent > constraints.remainingPaintExtent) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'SliverGeometry has a paintOffset that exceeds the remainingPaintExtent from the constraints.'),
          describeForError(
              'The render object whose geometry violates the constraints is the following'),
          ErrorDescription(
            'The paintExtent must cause the child sliver to paint within the viewport, and so '
            'cannot exceed the remainingPaintExtent.',
          ),
        ]);
      }
      return true;
    }());
  }

  @override
  void performLayout() {
    assert(constraints.growthDirection == GrowthDirection.forward);
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    final full = _computeIfFull(constraints);
    final active =
        !(hideWhenNotFull ?? false) || mode == LoadStatus.noMore || full;
    final childExtent = measureContent();
    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final double cacheExtent =
        calculateCacheOffset(constraints, from: 0.0, to: childExtent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    if (active) {
      // consider reverse loading and HideAlways==loadStyle
      geometry = SliverGeometry(
        scrollExtent: !_hasLayoutExtent! || !full ? 0 : layoutExtent,
        paintExtent: paintedChildSize,
        // this need to fix later
        paintOrigin: computePaintOrigin(
            !_hasLayoutExtent! || !full ? layoutExtent : 0.0,
            constraints.axisDirection == AxisDirection.up ||
                constraints.axisDirection == AxisDirection.left,
            full || shouldFollowContent!)!,
        cacheExtent: cacheExtent,
        maxPaintExtent: childExtent,
        hitTestExtent: paintedChildSize,
        visible: true,
        hasVisualOverflow: true,
      );
      setChildParentData(child!, constraints, geometry!);
    } else {
      geometry = SliverGeometry.zero;
    }
    commitLayout(geometry!.scrollExtent,
        hidden: !active, expanded: hasLayoutExtent);
  }
}

class SliverRefreshBody extends SingleChildRenderObjectWidget {
  /// Creates a sliver that contains a single box widget.
  const SliverRefreshBody({
    Key? key,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  RenderSliverRefreshBody createRenderObject(BuildContext context) =>
      RenderSliverRefreshBody();
}

class RenderSliverRefreshBody extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a [RenderBox].
  RenderSliverRefreshBody({
    RenderBox? child,
  }) : super(child: child);

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    child!.layout(constraints.asBoxConstraints(maxExtent: 1111111),
        parentUsesSize: true);
    double? childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child!.size.width;
        break;
      case Axis.vertical:
        childExtent = child!.size.height;
        break;
    }
    if (childExtent == 1111111) {
      child!.layout(
          constraints.asBoxConstraints(
              maxExtent: constraints.viewportMainAxisExtent),
          parentUsesSize: true);
    }
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child!.size.width;
        break;
      case Axis.vertical:
        childExtent = child!.size.height;
        break;
    }
    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final double cacheExtent =
        calculateCacheOffset(constraints, from: 0.0, to: childExtent);

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );
    setChildParentData(child!, constraints, geometry!);
  }
}
