# Integration and lifecycle notes

## Controllers

- Create RefreshController in State, keep its lifetime aligned with SmartRefresher, and do not recreate it in build or share it between refreshers.
- Dispose it in State.dispose. Unmounting SmartRefresher detaches position listeners but does not dispose the controller's notifiers.
- Check mounted after asynchronous work before updating data and controller status. The component does not await onRefresh/onLoading Futures or handle business exceptions for you.
- position becomes available after an indicator mounts. Request operations after the first frame, or use initialRefresh: true. An operation cannot start its interaction without the matching indicator.
- See [API](propertys_en.md#refreshcontroller) for needCallback and Future return limitations.

## Scroll structure

Pass ListView, GridView or CustomScrollView directly as child. Put backgrounds, Scrollbar, NotificationListener and ScrollConfiguration outside SmartRefresher. Ordinary content uses SliverRefreshBody; do not wrap it in SingleChildScrollView. See [README](README.md#child).

header/footer can be compositions but must ultimately build slivers, not ordinary Containers. The builder constructor requires you to insert indicators and apply RefreshPhysics. A direct Scrollable must return a Viewport from viewportBuilder, not a single-child or shrink-wrapping viewport.

Rebuilding a ScrollView inherits selected properties rather than copying everything; shrinkWrap is not forwarded. Automatic BoxScrollView system padding is not retained; use explicit padding or SafeArea.

## Short lists and footers

hideFooterWhenNotFull defaults to false. With true, short content hides the footer and disables gesture loading; noMore can remain visible. By default noMore follows content, while other states sit at the viewport end; override shouldFooterFollowWhenNotFull as needed.

The implementation compares precedingScrollExtent against viewport extent after subtracting the refresh header's scrollExtent. Complex slivers may have different scroll and layout extents. If needed, turn off automatic hiding and calculate enablePullUp yourself; see [manual hiding](example/lib/ui/example/useStage/hidefooter_bycontent.dart) and [filling free space](example/lib/ui/example/useStage/force_full_one_page.dart).

LoadStyle controls layout space: ShowAlways retains it, HideAlways does not, and ShowWhenLoading retains it while loading. These are not direct painting switches; short-list footer scrollExtent has additional handling. Tapping calls onClick only; call requestLoading() yourself to retry.

## Special cases

- Validate NestedScrollView nesting, explicit requests and quick direction changes; see the [example](example/lib/ui/example/useStage/Nested.dart).
- Validate SliverAppBar/persistent-header positioning with UnFollow. The [basic example](example/lib/ui/example/useStage/basic.dart) puts a SliverToBoxAdapter before content.
- The [DraggableScrollableSheet example](example/lib/ui/example/otherwidget/draggable_bottomsheet_loadmore.dart) enables loading only and uses the sheet's ScrollController.
- Two-level layout currently uses viewport height. Do not assume horizontal behavior matches vertical behavior. The direct Scrollable path does not insert a header when only enableTwoLevel is enabled.
- Dispose custom AnimationControllers yourself. LinkHeader/LinkFooter require a mounted GlobalKey whose external State implements RefreshProcessor/LoadingProcessor respectively.

## Current implementation limits

Some configuration changes do not notify the subtree automatically; see [configuration](propertys_en.md#refreshconfiguration). CustomHeader's onResetValue is currently not called. Override resetValue in RefreshIndicatorState or use onModeChange to reset animations; see [custom indicators](custom_indicator_en.md).

These notes describe the current source; they do not imply these limits have been fixed.
