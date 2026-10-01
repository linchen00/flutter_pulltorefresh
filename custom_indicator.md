# 自定义指示器

header/footer 最终必须构建为 sliver。可以直接使用库中的指示器，也可以把 CustomHeader、ClassicHeader 等封装在普通 StatelessWidget/StatefulWidget 中组合使用。

## 使用 CustomHeader / CustomFooter

把以下片段放在 SmartRefresher 的 header/footer 参数中：

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

builder 的状态参数可空。位移回调现在位于指示器上，SmartRefresher.onOffsetChange 已移除。

| 生命周期 | CustomHeader | CustomFooter |
|---|---|---|
| 构建内容 | builder(context, RefreshStatus?) | builder(context, LoadStatus?) |
| 位移变化 | onOffsetChange(double) | onOffsetChange(double) |
| 状态变化 | onModeChange(RefreshStatus?) | onModeChange，接收 LoadStatus |
| 准备动画 | readyToRefresh，返回 Future<void> | readyLoading，返回 Future<void> |
| 结束动画 | endRefresh，返回 Future<void> | endLoading，返回 Future<void> |

准备动画在普通手势流程进入业务状态之前执行；结束动画在业务调用成功/失败结束方法后执行。替换 endRefresh 会覆盖默认 completeDuration 延时，如果需要停留时间，需在自定义 Future 内实现。

CustomHeader 声明了 onResetValue，但当前 State 没有调用它。需要可靠重置时，可使用 onModeChange 在 idle/canRefresh 时重置，或采用下面的继承方式。

onOffsetChange 本身不会自动触发你的外层组件重建。使用 AnimationController、AnimatedBuilder 或自行 setState 驱动界面；父类的 onOffsetChange 默认是空实现。

## 继承指示器 State

下面是可直接使用的头部指示器。业务回调仍配置在 SmartRefresher.onRefresh，不放在指示器构造函数里：

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

RefreshIndicatorState 已负责位置监听、状态机与 sliver 包装。可重写 buildContent、onOffsetChange、onModeChange、readyToRefresh、endRefresh 和 resetValue。floating 表示刷新流程保留占位，不能简单当成可见性开关；Front 样式有单独的布局处理。

footer 继承 LoadIndicator 和 LoadIndicatorState，可重写 readyToLoad、endLoading 等方法。CustomFooter 对应的构造参数名称是 readyLoading，不是 readyToLoad。点击 footer 只触发 onClick，加载重试需自己调用控制器。

动画控制器由自定义组件负责释放。主动 requestRefresh/requestLoading 与手势准备流程不完全相同，尤其 needCallback: false 会跳过状态通知，详见 [API](propertys.md#refreshcontroller)。

## 样式与组合

- Follow：随内容移动。
- UnFollow：完全露出后不再继续跟随。
- Behind：根据越界距离伸展，位于内容后方。
- Front：悬浮在内容前方。

footer 的 ShowAlways、HideAlways、ShowWhenLoading 控制占位，详见 [指示器属性](indicator_attribute.md)。

组合示例：[贝塞尔与圆形动画](lib/src/indicator/bezier_indicator.dart)、[二楼](lib/src/indicator/twolevel_indicator.dart)、[GIF](example/lib/ui/example/customindicator/gif_indicator_example1.dart)、[SpinKit](example/lib/ui/example/customindicator/spinkit_header.dart)。

## 外置指示器

LinkHeader/LinkFooter 留在滚动结构中，把事件转发到 linkKey 指向的外部 State。linkKey 虽声明为 Key，实际必须传入已挂载的 GlobalKey。外部 State 分别混入 RefreshProcessor/LoadingProcessor。

LinkHeader 转发位移、状态、准备、结束和重置；LinkFooter 当前只转发位移和状态。使用时保证外置 State 已挂载，并自行释放动画资源。参考 [外置 header 示例](example/lib/ui/example/customindicator/link_header_example.dart)。
