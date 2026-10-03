# API and defaults

This document describes this checkout: Dart ≥3.0 and Flutter ≥3.32. The package version remains `2.0.0`; see [pubspec.yaml](pubspec.yaml) for this checkout's SDK requirements.

## SmartRefresher

| Property | Type | Default / behavior |
|---|---|---|
| state | RefreshState | Required; one state per mounted SmartRefresher |
| controller | RefreshController? | null; optional UI operations |
| initialRefresh | bool | false; request refresh after the first frame |
| child | Widget? | null; ScrollView, Scrollable and ordinary widgets use different paths; see [integration](README.md#child) |
| header | Widget? | Explicit header, then headerBuilder; otherwise ClassicHeader on iOS and MaterialClassicHeader elsewhere |
| footer | Widget? | Explicit footer, then footerBuilder; otherwise ClassicFooter |
| enablePullDown | bool | true |
| enablePullUp | bool | false |
| enableTwoLevel | bool | false |
| onRefresh | VoidCallback? | Called by gestures or UI requests; finish through RefreshState |
| onLoading | VoidCallback? | Called by gestures or UI requests; finish through RefreshState |
| onTwoLevel | void Function(bool)? | true when opening, false when closing |

The ordinary constructor also accepts `scrollDirection`, `reverse`, `scrollController`, `primary`, `physics`, `cacheExtent`, `semanticChildCount` and `dragStartBehavior`. With a direct ScrollView child, non-null overrides take precedence over its matching properties. The rebuilt view also inherits center, anchor, keyboard dismissal, restoration ID and clipping, but does not copy every ScrollView property, such as shrinkWrap.

`SmartRefresher.builder` supplies `(BuildContext context, RefreshPhysics physics)`. Pass physics to the scrollable and insert header/footer into its slivers yourself; this constructor does not insert indicators.

## RefreshState

```dart
RefreshState({
  RefreshStatus? initialRefreshStatus,
  LoadStatus? initialLoadStatus,
});

RefreshNotifier<RefreshStatus>? headerMode;
RefreshNotifier<LoadStatus>? footerMode;
RefreshStatus? get headerStatus;
LoadStatus? get footerStatus;
bool get isRefresh;
bool get isLoading;
bool get isTwoLevel;
bool get isDisposed;

void startRefresh();
void startLoading();
void refreshCompleted({bool resetFooterState = false});
void refreshFailed();
void refreshToIdle();
void loadComplete();
void loadFailed();
void loadNoData();
void resetNoData();
void dispose();
```

Initial statuses default to idle and survive mounting and remounting. All state updates are synchronous and work without a UI or frame scheduling. Reading and listening move from the controller to this object. headerMode/footerMode are transferred unchanged from RefreshController.

startRefresh/startLoading and direct notifier.value assignments update the status and indicator hooks without calling onRefresh/onLoading or requesting scrolling. Completion/failure methods also belong to RefreshState. resetNoData clears only noMore; refreshCompleted(resetFooterState: true) calls it.

The caller creates and disposes the state. One state can bind one SmartRefresher at a time, with any number of business listeners; it can be reused after unmounting. Dispose is repeatable; methods reject updates after disposal.

## RefreshController

```dart
RefreshController();

Future<void> requestRefresh({
  bool needMove = true,
  bool needCallback = true,
  Duration duration = const Duration(milliseconds: 500),
  Curve curve = Curves.linear,
});

Future<void> requestLoading({
  bool needMove = true,
  bool needCallback = true,
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.linear,
});

Future<void> requestTwoLevel({
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.linear,
});

Future<void> twoLevelComplete({
  Duration duration = const Duration(milliseconds: 500),
  Curve curve = Curves.linear,
});

ScrollPosition? get position;
void dispose();
```

These are signature references, not executable top-level function definitions.

- The controller is optional. It requests UI operations and does not own refresh/loading state or its notifiers.
- position is available after an indicator attaches, and becomes null after detachment. Invoke requests after layout with the corresponding feature and indicator enabled; otherwise the Future reports StateError.
- needMove controls movement to the boundary. Every operation returns a non-null Future<void> for the UI operation, not your data request.
- needCallback: false suppresses onRefresh/onLoading for both needMove branches. Status listeners and indicator hooks still run.
- Gesture and controller request flows invoke business callbacks explicitly. Mounting an existing active state does not invoke them again.
- Replacing a controller retains the supplied RefreshState. Unmounting, replacement or disposal invalidates old operations, so they cannot publish stale state or callbacks.
- SmartRefresher(initialRefresh: true) requests refresh after the first frame, including without an external controller.

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
