# API and defaults

This document describes this checkout: Dart ≥3.0 and Flutter ≥3.32. The package version remains `2.0.0`; see [pubspec.yaml](pubspec.yaml) for this checkout's SDK requirements.

## SmartRefresher

| Property | Type | Default / behavior |
|---|---|---|
| controller | RefreshController | Required; one controller per SmartRefresher |
| child | Widget? | null; ScrollView, Scrollable and ordinary widgets use different paths; see [integration](README.md#child) |
| header | Widget? | Explicit header, then headerBuilder; otherwise ClassicHeader on iOS and MaterialClassicHeader elsewhere |
| footer | Widget? | Explicit footer, then footerBuilder; otherwise ClassicFooter |
| enablePullDown | bool | true |
| enablePullUp | bool | false |
| enableTwoLevel | bool | false |
| onRefresh | VoidCallback? | Called on entry to refreshing; finish through the controller |
| onLoading | VoidCallback? | Called on entry to loading; finish through the controller |
| onTwoLevel | void Function(bool)? | true when opening, false when closing |

The ordinary constructor also accepts `scrollDirection`, `reverse`, `scrollController`, `primary`, `physics`, `cacheExtent`, `semanticChildCount` and `dragStartBehavior`. With a direct ScrollView child, non-null overrides take precedence over its matching properties. The rebuilt view also inherits center, anchor, keyboard dismissal, restoration ID and clipping, but does not copy every ScrollView property, such as shrinkWrap.

`SmartRefresher.builder` supplies `(BuildContext context, RefreshPhysics physics)`. Pass physics to the scrollable and insert header/footer into its slivers yourself; this constructor does not insert indicators.

## RefreshController

```dart
RefreshController({
  bool initialRefresh = false,
  RefreshStatus? initialRefreshStatus,
  LoadStatus? initialLoadStatus,
});

Future<void>? requestRefresh({
  bool needMove = true,
  bool needCallback = true,
  Duration duration = const Duration(milliseconds: 500),
  Curve curve = Curves.linear,
});

Future<void>? requestLoading({
  bool needMove = true,
  bool needCallback = true,
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.linear,
});

Future<void> requestTwoLevel({
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.linear,
});

void refreshCompleted({bool resetFooterState = false});
void refreshFailed();
void refreshToIdle();
Future<void>? twoLevelComplete({
  Duration duration = const Duration(milliseconds: 500),
  Curve curve = Curves.linear,
});
void loadComplete();
void loadFailed();
void loadNoData();
void resetNoData();
void dispose();
```

These are signature references, not executable top-level function definitions.

- initialRefresh requests refresh after the first frame. Both initial statuses default to idle; mounting the header resets headerMode to idle, so initialRefreshStatus is not a replacement for initialRefresh.
- position becomes available when an indicator attaches to its ScrollPosition. Request operations after layout, with the corresponding indicator enabled.
- needMove controls movement to the boundary. A returned Future covers the request/movement, not completion of your data request. Currently requestRefresh(needMove: false) and twoLevelComplete() return null; do not await them to track animations or data work.
- needCallback: false currently works only with needMove: true. This branch changes status without notifying notifier listeners, also bypassing indicator hooks that depend on those notifications. With needMove: false, business callbacks still run.
- loadComplete(), loadFailed() and loadNoData() update the footer after the frame, allowing data layout to complete and preventing duplicate loads.
- resetNoData() resets only noMore to idle; refreshCompleted(resetFooterState: true) calls it.
- Read headerStatus, footerStatus, isRefresh, isLoading and isTwoLevel, or listen to headerMode / footerMode. Use your own ScrollController for scroll listeners; RefreshController no longer exposes scrollController.

## RefreshConfiguration

An InheritedWidget configures its subtree. RefreshConfiguration.copyAncestor copies ancestor values and overrides non-null arguments; its context must have a RefreshConfiguration ancestor.

| Property | Type | Default / behavior |
|---|---|---|
| headerBuilder / footerBuilder | Widget Function()? | null; return indicators or compositions that build slivers |
| springDescription | SpringDescription | mass: 1, stiffness: 364.71867768595047, damping: 35.2 |
| dragSpeedRatio | double | 1.0; overscroll drag ratio, must be >0 |
| headerTriggerDistance | double | 80.0; must be >0 |
| skipCanRefresh | bool | false; true prepares refresh immediately at the threshold |
| enableBallisticRefresh | bool | false |
| enableScrollWhenRefreshCompleted | bool | false; dragging during completion/failure retraction |
| twiceTriggerDistance | double | 150.0; must be >0 |
| closeTwoLevelDistance | double | 80.0; must be >0 |
| enableScrollWhenTwoLevel | bool | true |
| footerTriggerDistance | double | 15.0; compares maxScrollExtent - pixels; negative values require bottom overscroll |
| enableBallisticLoad | bool | true |
| enableLoadingWhenFailed | bool | true |
| enableLoadingWhenNoData | bool | false; gesture loading from noMore |
| hideFooterWhenNotFull | bool | false; true hides the footer and disables gesture loading for short content, except noMore can remain visible |
| shouldFooterFollowWhenNotFull | bool Function(LoadStatus?)? | null; by default only noMore follows content; other states sit at the viewport end |
| maxOverScrollExtent | double? | null; resolves to ∞ for Bouncing, 60.0 otherwise |
| maxUnderScrollExtent | double? | null; resolves to ∞ for Bouncing, 0.0 otherwise |
| topHitBoundary / bottomHitBoundary | double? | null; ballistic boundaries resolve to ∞ for Bouncing, 0.0 otherwise |
| enableRefreshVibrate / enableLoadMoreVibrate | bool | false |

Overscroll defaults depend on the supplied physics and ScrollConfiguration, not solely the OS. Reachable drag distances also include indicator layout compensation; verify thresholds with your chosen indicator.

Currently updateShouldNotify does not compare headerBuilder, footerBuilder, springDescription, enableBallisticLoad, enableLoadingWhenNoData or shouldFooterFollowWhenNotFull. Changing only these fields does not automatically notify dependent widgets. Do not assume every configuration change applies immediately.

## States

- Refresh: idle → canRefresh → refreshing → completed / failed → idle.
- Two level: canTwoLevel → twoLevelOpening → twoLeveling → twoLevelClosing → idle.
- Load: idle / failed → canLoading → loading → idle / failed / noMore. Ballistic loading and explicit requests can skip canLoading.

SmartRefresher.onOffsetChange, RefreshConfiguration.autoLoad and RefreshController.scrollController have been removed. Put offset callbacks on custom indicators; see [custom indicators](custom_indicator_en.md).
