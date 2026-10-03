# API 与默认配置

本文对应本仓库当前实现：Dart ≥3.0、Flutter ≥3.32。包版本仍为 `2.0.0`；本仓库的 SDK 要求以 [pubspec.yaml](pubspec.yaml) 为准。

## SmartRefresher

| 属性 | 类型 | 默认值 / 说明 |
|---|---|---|
| state | RefreshState | 必填，一个状态对应一个挂载中的 SmartRefresher |
| controller | RefreshController? | null，可选，用于主动 UI 操作 |
| initialRefresh | bool | false，首帧结束后主动刷新 |
| child | Widget? | null；ScrollView、Scrollable 和普通 Widget 的处理不同，见 [接入说明](README_CN.md#child) |
| header | Widget? | 局部设置优先，其次 headerBuilder；未配置时 iOS 使用 ClassicHeader，其他平台使用 MaterialClassicHeader |
| footer | Widget? | 局部设置优先，其次 footerBuilder；未配置时使用 ClassicFooter |
| enablePullDown | bool | true |
| enablePullUp | bool | false |
| enableTwoLevel | bool | false |
| onRefresh | VoidCallback? | 手势或 UI 请求触发，业务完成后通过 RefreshState 结束刷新 |
| onLoading | VoidCallback? | 手势或 UI 请求触发，业务完成后通过 RefreshState 结束加载 |
| onTwoLevel | void Function(bool)? | 打开二楼时传 true，关闭时传 false |

普通构造方式还支持 `scrollDirection`、`reverse`、`scrollController`、`primary`、`physics`、`cacheExtent`、`semanticChildCount` 和 `dragStartBehavior`。直接传入 ScrollView 时，这些非空参数优先于 child 的对应属性。重建时还会继承 child 的 `center`、`anchor`、键盘收起方式、恢复标识和裁剪方式，但不会复制全部 ScrollView 属性，例如 `shrinkWrap`。

`SmartRefresher.builder` 提供 `(BuildContext context, RefreshPhysics physics)`，由调用方将 physics 传入滚动组件，并自行把 header/footer 插入 slivers；该构造方式不会自动插入指示器。

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

初始状态默认都是 idle，挂载和重新挂载时会保留。状态更新同步完成，不依赖 UI 或帧调度。原控制器的状态查询和监听迁移到此对象；headerMode/footerMode 从 RefreshController 原样迁移。

startRefresh/startLoading 和直接修改 notifier.value 只更新状态与指示器钩子，不调用 onRefresh/onLoading，也不请求滚动。完成、失败和重置方法也归 RefreshState。resetNoData 只清除 noMore；refreshCompleted(resetFooterState: true) 会调用它。

使用方创建和释放状态。一个状态同时绑定一个 SmartRefresher，可以有任意数量的业务监听者，解绑后可重新挂载。dispose 可重复调用；释放后调用状态更新方法会报错。

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

以上是签名参考，不是可直接执行的顶层函数定义。

- 控制器可选，只请求 UI 操作，不拥有刷新/加载状态及其 notifier。
- position 在指示器连接滚动位置后才可用，解绑后为 null。主动请求应在布局完成后调用，并启用对应功能和指示器，否则 Future 报 StateError。
- needMove 控制是否移动到边界。所有操作返回非空 Future<void>，表示 UI 操作结束，不表示业务请求完成。
- needCallback: false 在两个 needMove 分支下都不触发 onRefresh/onLoading，状态监听与指示器钩子仍正常执行。
- 手势和控制器请求流程显式触发业务回调；挂载已有刷新/加载状态不会再次触发业务请求。
- 替换控制器时保留传入的 RefreshState。卸载、替换或释放后，旧操作不能继续更新状态或调用业务回调。
- SmartRefresher(initialRefresh: true) 在首帧结束后主动请求刷新，也支持不传外部控制器。

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
