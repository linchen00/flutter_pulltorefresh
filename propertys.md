# API 与默认配置

本文对应本仓库当前实现：Dart ≥3.0、Flutter ≥3.32。包版本仍为 `2.0.0`；本仓库的 SDK 要求以 [pubspec.yaml](pubspec.yaml) 为准。

## SmartRefresher

| 属性 | 类型 | 默认值 / 说明 |
|---|---|---|
| controller | RefreshController | 必填，一个控制器对应一个 SmartRefresher |
| child | Widget? | null；ScrollView、Scrollable 和普通 Widget 的处理不同，见 [接入说明](README_CN.md#child) |
| header | Widget? | 局部设置优先，其次 headerBuilder；未配置时 iOS 使用 ClassicHeader，其他平台使用 MaterialClassicHeader |
| footer | Widget? | 局部设置优先，其次 footerBuilder；未配置时使用 ClassicFooter |
| enablePullDown | bool | true |
| enablePullUp | bool | false |
| enableTwoLevel | bool | false |
| onRefresh | VoidCallback? | 进入刷新状态时调用，业务完成后须通过控制器结束刷新 |
| onLoading | VoidCallback? | 进入加载状态时调用，业务完成后须通过控制器结束加载 |
| onTwoLevel | void Function(bool)? | 打开二楼时传 true，关闭时传 false |

普通构造方式还支持 `scrollDirection`、`reverse`、`scrollController`、`primary`、`physics`、`cacheExtent`、`semanticChildCount` 和 `dragStartBehavior`。直接传入 ScrollView 时，这些非空参数优先于 child 的对应属性。重建时还会继承 child 的 `center`、`anchor`、键盘收起方式、恢复标识和裁剪方式，但不会复制全部 ScrollView 属性，例如 `shrinkWrap`。

`SmartRefresher.builder` 提供 `(BuildContext context, RefreshPhysics physics)`，由调用方将 physics 传入滚动组件，并自行把 header/footer 插入 slivers；该构造方式不会自动插入指示器。

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

以上是签名参考，不是可直接执行的顶层函数定义。

- `initialRefresh` 在首帧结束后主动请求刷新。初始状态默认都是 idle；头部指示器初始化时会把 headerMode 重置为 idle，因此不要用 initialRefreshStatus 替代 initialRefresh。
- `position` 在指示器连接滚动位置后才可用。主动请求应在布局完成之后调用，并确保对应指示器已启用。
- `needMove` 控制是否移动到边界；返回的 Future 表示请求/移动流程结束，不表示业务请求完成。`requestRefresh(needMove: false)` 和 `twoLevelComplete()` 当前返回 null，不能依赖它们等待动画或业务结束。
- `needCallback: false` 当前只在 `needMove: true` 分支生效。该分支直接修改状态而不通知 notifier 监听器，因此也会跳过依赖状态通知的指示器钩子；`needMove: false` 仍会触发业务回调。
- `loadComplete()`、`loadFailed()`、`loadNoData()` 在帧结束后更新 footer 状态，给数据布局留出时间，防止重复加载。
- `resetNoData()` 只将 noMore 重置为 idle；`refreshCompleted(resetFooterState: true)` 会调用它。
- 可读取 `headerStatus`、`footerStatus`、`isRefresh`、`isLoading`、`isTwoLevel`，或监听 `headerMode` / `footerMode`。滚动监听使用自己的 ScrollController；RefreshController 不再提供 scrollController。

## RefreshConfiguration

通过 InheritedWidget 配置子树。在 `RefreshConfiguration.copyAncestor` 中，非空参数覆盖祖先配置；context 必须位于已有 RefreshConfiguration 下。

| 属性 | 类型 | 默认值 / 行为 |
|---|---|---|
| headerBuilder / footerBuilder | Widget Function()? | null，返回指示器或构建为 sliver 的组合组件 |
| springDescription | SpringDescription | mass: 1，stiffness: 364.71867768595047，damping: 35.2 |
| dragSpeedRatio | double | 1.0，越界拖动速度比例，须 >0 |
| headerTriggerDistance | double | 80.0，刷新触发距离，须 >0 |
| skipCanRefresh | bool | false；true 时达到阈值即准备刷新 |
| enableBallisticRefresh | bool | false，是否允许惯性触发刷新 |
| enableScrollWhenRefreshCompleted | bool | false，完成/失败后的回弹阶段是否允许拖动 |
| twiceTriggerDistance | double | 150.0，二楼触发距离，须 >0 |
| closeTwoLevelDistance | double | 80.0，二楼关闭距离，须 >0 |
| enableScrollWhenTwoLevel | bool | true，二楼打开后是否允许拖动 |
| footerTriggerDistance | double | 15.0；判断 maxScrollExtent - pixels，负数表示需要越过底部 |
| enableBallisticLoad | bool | true，是否允许惯性触发加载 |
| enableLoadingWhenFailed | bool | true，失败后是否允许手势重试 |
| enableLoadingWhenNoData | bool | false，noMore 后是否允许手势继续加载 |
| hideFooterWhenNotFull | bool | false；true 时内容不足一屏隐藏 footer 并禁用手势加载，noMore 状态仍可显示 |
| shouldFooterFollowWhenNotFull | bool Function(LoadStatus?)? | null；默认只有 noMore 跟随内容，其他状态位于视口末端 |
| maxOverScrollExtent | double? | null；按物理规则解析为 Bouncing: ∞，其他: 60.0 |
| maxUnderScrollExtent | double? | null；按物理规则解析为 Bouncing: ∞，其他: 0.0 |
| topHitBoundary / bottomHitBoundary | double? | null；惯性停止边界，Bouncing: ∞，其他: 0.0 |
| enableRefreshVibrate / enableLoadMoreVibrate | bool | false |

越界默认值根据传入物理规则及 ScrollConfiguration 判断，不只是按操作系统决定。最大可达拖动距离还包含指示器占位的补偿，应结合实际指示器验证触发阈值。

当前 `updateShouldNotify` 未比较 headerBuilder、footerBuilder、springDescription、enableBallisticLoad、enableLoadingWhenNoData 和 shouldFooterFollowWhenNotFull；仅修改这些字段不会自动通知依赖组件。不要假定动态替换任意配置都会立即生效。

## 状态

- 刷新：idle → canRefresh → refreshing → completed / failed → idle。
- 二楼：canTwoLevel → twoLevelOpening → twoLeveling → twoLevelClosing → idle。
- 加载：idle / failed → canLoading → loading → idle / failed / noMore。惯性加载或主动请求可跳过 canLoading。

`SmartRefresher.onOffsetChange`、`RefreshConfiguration.autoLoad` 和 `RefreshController.scrollController` 已移除。位移回调放在自定义指示器上，见 [自定义指示器](custom_indicator.md)。
