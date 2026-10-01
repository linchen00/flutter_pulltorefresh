# FAQ

## How do I listen to or control scrolling?

Pass your ScrollController to the direct ScrollView child or SmartRefresher.scrollController. RefreshController.position can drive scrolling after an indicator mounts; RefreshController.scrollController was removed.

## Why are header/footer missing?

Check enablePullDown/enablePullUp, then ensure ListView is the direct child. Wrapping it in Container, Scrollbar or a custom widget creates nested scrolling. Use [SliverAnimatedList](example/lib/ui/example/otherwidget/refresh_animatedlist_example.dart) for animations and the [adapter example](example/lib/ui/example/otherwidget/refresh_recordable_listview_example.dart) for reordering.

## Why does refreshing/loading never end?

onRefresh/onLoading trigger your work; the component does not await its Future to finish status. Call refreshCompleted/refreshFailed or loadComplete/loadFailed/loadNoData, including on error paths. Check mounted after asynchronous work.

## How do I restore loading after refresh?

Call refreshCompleted(resetFooterState: true), or resetNoData() when the footer is noMore. enableLoadingWhenNoData defaults to false. For tap-to-retry, configure footer.onClick to call requestLoading().

## How do I hide or position a short-list footer?

hideFooterWhenNotFull: true hides the footer and disables gesture loading for short content; noMore can remain visible. With false, noMore follows content by default and other states sit at the viewport end; override shouldFooterFollowWhenNotFull. For complex slivers, see [manual hiding](example/lib/ui/example/useStage/hidefooter_bycontent.dart); to fill a viewport, see [this example](example/lib/ui/example/useStage/force_full_one_page.dart).

## Why cannot I reach the trigger, or how do I load earlier?

headerTriggerDistance measures leading overscroll. footerTriggerDistance compares maxScrollExtent - pixels: positive values load early, negative values require bottom overscroll. Ensure maxOverScrollExtent/maxUnderScrollExtent allow the threshold, accounting for indicator layout compensation. Defaults depend on physics, not just platform; see [configuration](propertys_en.md#refreshconfiguration).

## How do I change springs or ballistic loading?

springDescription controls mass, stiffness and damping; dragSpeedRatio scales overscroll dragging. maxOverScrollExtent/maxUnderScrollExtent constrain dragging, and topHitBoundary/bottomHitBoundary constrain ballistic overscroll. enableBallisticLoad defaults to true; false requires dragging to canLoading before release.

## How do I integrate PageView or SingleChildScrollView?

Avoid directly nesting same-axis scrollables. Pass ordinary content to SmartRefresher with appropriate constraints. For paging, see [PageScrollPhysics + SliverFillViewport](example/lib/ui/example/otherwidget/refresh_pageView_example.dart). Horizontal child scrollables need finite height; inspect parent constraints for unbounded-height errors.

## How do I implement GIFs or complex animations?

Use CustomHeader/CustomFooter offset and mode callbacks, or subclass indicator State. The [GIF example](example/lib/ui/example/customindicator/gif_indicator_example1.dart) uses gif_view for frame ranges; call GifController.seek in onOffsetChange to follow dragging. See [custom indicators](custom_indicator_en.md).

## Why is content obscured, or why does tapping the status bar not scroll to the top?

The rebuilt CustomScrollView does not retain automatic BoxScrollView system padding; use SafeArea or explicit padding. A custom ScrollController can bypass Scaffold's PrimaryScrollController; inspect primary, controllers and Scaffold hierarchy.

## Does NestedScrollView or custom physics work automatically?

Validate your structure. The library listens to ScrollPosition and applies RefreshPhysics; special scrollables may have different activity, boundary and Viewport assumptions. See [notes](notice_en.md) and the [NestedScrollView example](example/lib/ui/example/useStage/Nested.dart).

## Why does needCallback: false still call my callback?

Currently only the needMove: true branch handles needCallback. With needMove: false, status listeners and business callbacks still run; see [API](propertys_en.md#refreshcontroller).
