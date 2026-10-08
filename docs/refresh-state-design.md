# RefreshState 与 RefreshController 分离设计

状态：已实施，随代码与测试维护。

本文记录已确认并实施的职责拆分及行为约定。此次重构直接迁移 API，不保留旧控制器状态接口的兼容代理。

## 1. 目标与已确认决策

将刷新和加载状态从 RefreshController 中分离，让业务能够在没有 UI 的情况下创建、更新和监听 RefreshState。

已确认的决策：

- RefreshState 包含 headerMode、footerMode，由使用方创建和释放。
- SmartRefresher 必须接收 RefreshState，RefreshController 改为可选。
- RefreshController 保留 requestRefresh、requestTwoLevel、requestLoading、twoLevelComplete 四个操作。
- 完成、失败、重置及状态查询归 RefreshState。
- headerMode、footerMode 迁移到 RefreshState，类型非空；dispose 释放 notifier，但不将字段置空。
- RefreshState 提供 startRefresh、startLoading，以支持脱离 UI 的完整业务生命周期。
- startRefresh、startLoading 只更新状态和指示器，不触发 onRefresh、onLoading。
- 手势或控制器主动请求才触发对应业务回调。
- 直接迁移示例、测试和文档，不保留已移除 API。

## 2. 职责边界

| 对象 | 负责 | 不负责 |
|---|---|---|
| RefreshState | 保存状态、同步更新状态、通知监听者、状态查询 | 滚动、布局、动画、业务请求、界面帧调度 |
| RefreshController | 向已绑定组件发出主动刷新、加载和二楼开关请求 | 持有或释放业务状态，报告完成和失败 |
| SmartRefresher 及指示器 | 绑定对象、响应手势、展示状态、执行动画、调用业务回调、防重复触发 | 拥有外部 RefreshState，执行网络请求 |
| 使用方 | 创建和释放对象、执行请求、更新数据、通过状态方法或 notifier.value 报告状态 | 执行组件内部的布局和动画流程 |

RefreshState 的实现只依赖 Flutter foundation 的监听能力，不依赖 BuildContext、ScrollPosition、WidgetsBinding 或挂载中的组件。“脱离 UI”指可以在 Flutter 的业务层与单元测试中使用；本次不将它拆成独立的纯 Dart 包。

## 3. 公开 API

以下为接口摘要，完整声明以源代码为准。

### RefreshState

```dart
class RefreshState {
  RefreshState({
    RefreshStatus? initialRefreshStatus,
    LoadStatus? initialLoadStatus,
  });

  RefreshNotifier<RefreshStatus> headerMode;
  RefreshNotifier<LoadStatus> footerMode;

  RefreshStatus get headerStatus;
  LoadStatus get footerStatus;

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
}
```

行为：

- 所有公开状态更新方法同步修改状态并通知监听者，不等待界面帧。
- 重复设置相同状态不重复通知。
- startRefresh 进入 refreshing，startLoading 进入 loading；不会请求滚动或调用业务回调。
- 直接给 headerMode.value、footerMode.value 赋值也只更新状态和指示器，不触发 onRefresh/onLoading。startRefresh/startLoading 是对应赋值的便捷方法，不是唯一更新入口。
- loadComplete 回到 idle，loadFailed 进入 failed，loadNoData 进入 noMore。
- resetNoData 只把 noMore 重置为 idle。
- refreshCompleted(resetFooterState: true) 同时恢复 footer 的 noMore 状态，默认不重置 footer。
- 不增加无通知的公开更新接口；业务回调是否触发不能靠屏蔽状态通知实现。

### RefreshController

```dart
class RefreshController {
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
}
```

保留 position，以迁移现有滚动定位示例；它仅表示 UI 绑定，不是刷新状态。生命周期方法 dispose 也保留，但不释放 RefreshState。

四个操作均返回 Future<void>，原 requestRefresh(needMove: false) 与 twoLevelComplete 返回 null 的差异已消除。Future 表示该次 UI 操作结束，不表示业务请求结束。

未绑定、对应功能未启用或已释放时，Future 报 StateError；同一操作已在进行时不重复触发业务回调。组件卸载、状态替换或控制器替换后，旧异步操作不得继续修改当前状态或调用回调。

### SmartRefresher

普通构造与 builder 构造都采用以下关系：

```dart
SmartRefresher(
  state: refreshState,            // 必填
  controller: refreshController, // 可选
  initialRefresh: false,
  onRefresh: onRefresh,
  onLoading: onLoading,
  child: listView,
)
```

将 initialRefresh 从控制器移到组件：它表示首帧之后发起一次 UI 刷新请求，而不是初始业务状态。没有外部控制器时，组件仍能执行该流程。

## 4. 使用方式

以下片段只展示对象关系，假定已有 fetchData、fetchFirstPage、fetchNextPage 等业务方法。

### 无 UI 的业务状态

```dart
final state = RefreshState();

state.footerMode.addListener(() {
  print(state.footerStatus);
});

state.startLoading();
try {
  await fetchData();
  state.loadComplete();
} catch (_) {
  state.loadFailed();
}

state.dispose();
```

整个过程不需要创建 Widget、pump 帧或绑定控制器。

也可以直接更新 notifier：

```dart
state.headerMode.value = RefreshStatus.refreshing;
state.footerMode.value = LoadStatus.noMore;
```

直接赋值允许使用方设置枚举中的任意状态，不自动校验完整的状态转换路径。需要驱动主动刷新、加载或二楼滚动流程时，仍通过控制器操作。

### 只需要手势刷新

```dart
final refreshState = RefreshState();

SmartRefresher(
  state: refreshState,
  enablePullUp: true,
  onRefresh: () async {
    try {
      await fetchFirstPage();
      if (!mounted) return;
      refreshState.refreshCompleted(resetFooterState: true);
    } catch (_) {
      if (mounted) refreshState.refreshFailed();
    }
  },
  onLoading: () async {
    try {
      await fetchNextPage();
      if (!mounted) return;
      refreshState.loadComplete();
    } catch (_) {
      if (mounted) refreshState.loadFailed();
    }
  },
  child: listView,
)
```

对象在 State 中创建，refreshState 在 State.dispose 中释放。组件已经在手势流程中更新了开始状态，业务回调无需再调用 start 方法。

### 需要主动触发

```dart
final refreshState = RefreshState();
final refreshController = RefreshController();

SmartRefresher(
  state: refreshState,
  controller: refreshController,
  onRefresh: onRefresh,
  child: listView,
)

// 布局完成后，例如点击按钮时。
await refreshController.requestRefresh();

// 业务完成后。
refreshState.refreshCompleted();
```

使用方分别释放控制器和状态。二楼主动关闭使用 refreshController.twoLevelComplete()。

## 5. 状态通知与业务回调分离

现有实现从“状态进入 refreshing/loading”直接调用业务回调。此次必须解除该耦合，否则 startLoading 会重复发起业务请求。

| 来源 | 更新状态 | 更新指示器及动画钩子 | 调用业务回调 |
|---|---|---|---|
| state.startRefresh / startLoading | 是 | 是，存在 UI 时 | 否 |
| 直接修改 state.headerMode.value / footerMode.value | 是 | 是，存在 UI 时 | 否 |
| 手势触发 | 是 | 是 | 是 |
| controller.requestRefresh / requestLoading | 是 | 是 | 默认是 |
| controller 请求且 needCallback: false | 是 | 是 | 否 |
| 组件挂载，读取已有 refreshing/loading | 保留已有状态 | 是 | 否 |

由 UI 操作流程显式调用业务回调，状态监听只负责指示器响应。needCallback 只控制 onRefresh/onLoading，不再屏蔽 notifier 通知或自定义指示器的 onModeChange。

手势流程仍保留 readyToRefresh / readyToLoad 等准备动画；进入业务状态并确认操作仍有效后，最多调用一次对应业务回调。不要简单把业务回调搬进通用状态监听器的其他位置。

如果业务自行调用 startRefresh/startLoading 再执行请求，即使 UI 正在挂载，也只显示其状态，不追加第二个请求。

## 6. UI 时序与防重复触发

当前 loadComplete/loadFailed/loadNoData 在帧结束后更新状态，是为了等新增数据完成布局。独立 RefreshState 不能继续持有这段帧调度。

重构后的行为：

1. RefreshState 立即发布完成状态，业务层立即可以读取。
2. 指示器收到通知，立即清除本次手势触发资格。
3. 组件保留必要的结束动画与布局过渡，等待下一次布局后重新判断滚动边界。
4. 完成前的手势、旧惯性和旧准备动画不能在同一轮交互中再次发起加载。
5. 后续新的有效交互仍可再次加载。

尤其需要测试“onLoading 内立即 loadComplete，且数据没有增长”的场景，不能依赖网络延时避免重复触发。

旧动画结束时也要检查状态身份与操作版本，避免在业务已经开始新请求后，把新状态覆盖为 idle。

## 7. 绑定与生命周期

绑定约束：一个 RefreshState 同时绑定一个 SmartRefresher，可以有任意数量的业务监听者；一个 RefreshController 同时绑定一个 SmartRefresher。

| 场景 | 行为 |
|---|---|
| 未挂载 UI | 状态正常更新和监听，控制器不能执行 UI 请求 |
| 首次挂载 | 读取外部状态并恢复视觉，不无条件重置 header 为 idle，不发起额外业务请求 |
| 替换控制器 | 解除旧绑定、绑定新控制器；保留同一个 RefreshState，不复制状态 |
| 替换 RefreshState | 解除旧监听、使用新状态自身的值；不把旧值复制到新状态 |
| 卸载组件 | 移除状态和位置监听；不 dispose 外部状态或控制器 |
| 重新挂载已有状态 | 使用已有状态，挂载本身不触发业务请求 |
| dispose 控制器 | 停止其后续请求，不影响 RefreshState |
| dispose 状态 | 释放监听资源；使用方不得继续更新或挂载该状态 |

释放操作可重复调用；状态释放后调用更新方法报 StateError。组件解绑时需要使旧延时、准备动画和滚动动画的后续处理失效，而不仅检查 mounted。

组件内部应保存自己的 ScrollPosition，RefreshPhysics 从组件的状态与位置访问能力读取信息，不再要求存在外部控制器。

二楼的手势关闭必须走组件内部操作流程，因此没有外部控制器也能关闭。controller.twoLevelComplete 只是向该流程发出主动请求。

## 8. 代码组织与迁移范围

新增 lib/src/refresh_state.dart，放置 RefreshState、RefreshStatus、LoadStatus 与 RefreshNotifier。通过 pull_to_refresh.dart 导出公开接口。

内部指示器直接通过状态对象的 notifier 更新 canRefresh、canLoading、二楼过渡等状态。业务回调仍由 UI 操作流程负责。

主要迁移范围：

- smart_refresher.dart：必填状态、可选控制器、绑定管理、组件内部请求流程。
- indicator_wrap.dart：状态监听、内部过渡、业务回调分离、完成时序。
- refresh_physics.dart：消除对必填外部控制器的依赖。
- slivers.dart 与指示器：从 RefreshState 读取状态。
- example：为刷新组件提供状态，把结果更新和查询移到状态，补齐释放逻辑。
- test：迁移既有回归测试并增加拆分行为测试。
- 中英文文档：更新 API、示例、生命周期和破坏性迁移说明。

## 9. API 迁移对照

| 旧接口 | 新接口 |
|---|---|
| RefreshController(initialRefresh: true) | SmartRefresher(initialRefresh: true) |
| 控制器 initialRefreshStatus / initialLoadStatus | RefreshState 构造参数 |
| controller.headerMode / footerMode | state.headerMode / footerMode |
| controller.headerStatus / footerStatus | state.headerStatus / footerStatus |
| controller.isRefresh / isLoading / isTwoLevel | state.isRefresh / isLoading / isTwoLevel |
| controller.refreshCompleted / refreshFailed / refreshToIdle | state 的同名方法 |
| controller.loadComplete / loadFailed / loadNoData / resetNoData | state 的同名方法 |
| controller.headerMode.value = refreshing | state.headerMode.value = refreshing，或 state.startRefresh() |
| controller.footerMode.value = loading | state.footerMode.value = loading，或 state.startLoading() |
| controller.footerMode.value = noMore | state.footerMode.value = noMore，或 state.loadNoData() |
| controller 的四个 UI 请求 | 继续使用 controller |
| 必填 controller | 必填 state，可选 controller |

## 10. 验收标准

### 状态单元测试

- 不挂载 UI 即可创建、开始、完成、失败、重置和监听。
- 所有更新同步可读，重复状态不重复通知。
- headerMode/footerMode 与现有字段一致，直接修改 value 会通知监听者。
- 初始化状态和派生查询正确，resetNoData 不覆盖 loading。
- 释放行为明确，不依赖 UI 帧调度。

### 组件与控制器测试

- 不传控制器，手势刷新、加载与二楼关闭仍正常。
- state.startRefresh/startLoading 更新指示器、调用动画钩子，但不触发业务回调。
- 直接修改 headerMode.value/footerMode.value 同样更新指示器且不触发 onRefresh/onLoading。
- 两种 needMove 分支下，needCallback: false 均不触发业务回调，但状态监听与视觉更新正常。
- 初始刷新、主动刷新、加载和二楼操作正常，各自不重复回调。
- 挂载前开始刷新/加载，挂载后状态保留且不重发请求。
- 替换控制器不丢失状态，替换状态不复制旧状态或保留旧监听。
- 卸载/替换期间旧异步操作不会更新新状态或调用旧回调。
- 即时完成、不增加数据、短列表和惯性场景不会重复加载。
- 完成后立即再次 startRefresh/startLoading，旧结束动画不能覆盖新状态。
- 既有四方向布局、回弹、命中检测、自定义指示器及示例测试通过。

## 11. 实施说明

职责拆分、状态字段原样迁移、可选控制器、直接迁移及状态更新不触发业务回调已确认。实施细节包括：

1. initialRefresh 移到 SmartRefresher，初始状态参数移到 RefreshState。
2. 控制器保留 position，四个操作统一返回非空 Future<void>。
3. 一个状态同时只绑定一个刷新组件，解绑后可以重新挂载。
4. 对无绑定/已释放等无效操作明确报错，释放本身可重复调用。

本次聚焦状态与操作分离。其他既有问题，例如水平二楼尺寸、CustomHeader.onResetValue 和不相关配置通知遗漏，不自动纳入此次修复；若迁移必须触及，应单独说明。
