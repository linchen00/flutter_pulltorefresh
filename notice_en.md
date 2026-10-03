# Integration and lifecycle notes

## State and controller lifecycle

- Create RefreshState and an optional RefreshController outside build. Each can bind one SmartRefresher at a time.
- The caller disposes both objects. Unmounting removes UI listeners and bindings without disposing either object; state can outlive the UI and be mounted again.
- Check mounted after asynchronous UI work before updating data. Complete or fail status through RefreshState; the component does not await business callback Futures or handle their exceptions.
- startRefresh/startLoading and direct state assignments only update state and indicators. Use controller requests to invoke business callbacks or scrolling.
- position is available after an indicator mounts and becomes null after detachment. Request operations after layout, or use SmartRefresher(initialRefresh: true).
- All controller operations return Future<void>. needCallback: false preserves status notifications in both needMove branches; see [API](propertys_en.md#refreshcontroller).

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
