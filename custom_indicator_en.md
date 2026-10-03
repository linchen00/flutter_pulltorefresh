# Custom indicators

header/footer must ultimately build slivers. Use built-in indicators directly, or compose CustomHeader, ClassicHeader and others inside ordinary StatelessWidget/StatefulWidget wrappers.

## CustomHeader / CustomFooter

Place these fragments in SmartRefresher's header/footer arguments:

```dart
CustomHeader(
  height: 80,
  refreshStyle: RefreshStyle.Follow,
  builder: (BuildContext context, RefreshStatus? mode) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(mode == RefreshStatus.refreshing ? 'Loading…' : '↓'),
      ),
    );
  },
)
```

```dart
CustomFooter(
  loadStyle: LoadStyle.ShowWhenLoading,
  builder: (BuildContext context, LoadStatus? mode) {
    return SizedBox(
      height: 60,
      child: Center(child: Text(mode == LoadStatus.loading ? 'Loading…' : '↑')),
    );
  },
)
```

Builder status arguments are nullable. Offset callbacks belong to indicators; SmartRefresher.onOffsetChange was removed.

| Lifecycle | CustomHeader | CustomFooter |
|---|---|---|
| Content | builder(context, RefreshStatus?) | builder(context, LoadStatus?) |
| Offset | onOffsetChange(double) | onOffsetChange(double) |
| Status | onModeChange(RefreshStatus?) | onModeChange, receiving LoadStatus |
| Prepare | readyToRefresh, returning Future<void> | readyLoading, returning Future<void> |
| Finish | endRefresh, returning Future<void> | endLoading, returning Future<void> |

In the ordinary gesture flow, preparation runs before entry to the business status. Finish animations run after your business code finishes the status. Overriding endRefresh replaces the default completeDuration delay; add a delay to your custom Future if needed.

CustomHeader declares onResetValue, but its State currently does not call it. Reset on idle/canRefresh in onModeChange, or subclass State as below.

onOffsetChange does not automatically rebuild your outer widget. Use AnimationController, AnimatedBuilder or setState to drive visuals; the base onOffsetChange implementation is empty.

## Subclass indicator State

This complete header can be used directly. Configure business work on SmartRefresher.onRefresh, not the indicator constructor:

```dart
import 'package:flutter/material.dart'
    hide RefreshIndicator, RefreshIndicatorState;
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ScaleHeader extends RefreshIndicator {
  const ScaleHeader({super.key})
      : super(height: 80, refreshStyle: RefreshStyle.Follow);

  @override
  State<ScaleHeader> createState() => _ScaleHeaderState();
}

class _ScaleHeaderState extends RefreshIndicatorState<ScaleHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    super.initState();
  }

  @override
  void onOffsetChange(double offset) {
    if (!floating) {
      _scale.value =
          (offset / configuration!.headerTriggerDistance).clamp(0.0, 1.0);
    }
  }

  @override
  Future<void> readyToRefresh() => _scale.animateTo(1);

  @override
  Future<void> endRefresh() => _scale.animateTo(0);

  @override
  void resetValue() => _scale.value = 0;

  @override
  Widget buildContent(BuildContext context, RefreshStatus? mode) {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Text(mode == RefreshStatus.refreshing ? 'Loading…' : '↓'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }
}
```

RefreshIndicatorState handles position listeners, the state machine and sliver wrapping. Override buildContent, onOffsetChange, onModeChange, readyToRefresh, endRefresh and resetValue as needed. floating represents retained layout space during refresh, not a visibility flag; Front uses separate layout handling.

For a footer, extend LoadIndicator and LoadIndicatorState and override readyToLoad/endLoading as needed. The corresponding CustomFooter constructor parameter is named readyLoading, not readyToLoad. Tapping invokes onClick only; request loading through the controller yourself.

Dispose custom animation controllers. Explicit requestRefresh/requestLoading and gesture preparation are not identical. needCallback: false preserves status notifications and onModeChange hooks. Updating RefreshState also updates indicators without invoking business callbacks. See [API](propertys_en.md#refreshcontroller).

## Styles and composition

- Follow moves with content.
- UnFollow stops following once fully exposed.
- Behind stretches with overscroll behind content.
- Front overlays content.

Footer ShowAlways, HideAlways and ShowWhenLoading control layout space; see [indicator properties](indicator_attribute_en.md).

Composition examples: [Bezier and circle](lib/src/indicator/bezier_indicator.dart), [two level](lib/src/indicator/twolevel_indicator.dart), [GIF](example/lib/ui/example/customindicator/gif_indicator_example1.dart), and [SpinKit](example/lib/ui/example/customindicator/spinkit_header.dart).

## External indicators

LinkHeader/LinkFooter stay in the scroll structure and forward events to an external State through linkKey. Although typed as Key, linkKey must be a mounted GlobalKey. The external State mixes in RefreshProcessor/LoadingProcessor respectively.

LinkHeader forwards offset, status, prepare, finish and reset. LinkFooter currently forwards only offset and status. Ensure the external State is mounted and dispose its animations; see the [external header example](example/lib/ui/example/customindicator/link_header_example.dart).
