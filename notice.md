# 接入与生命周期注意事项

## 状态与控制器生命周期

- 在 build 之外创建 RefreshState 和可选 RefreshController；每个对象同时绑定一个 SmartRefresher。
- 使用方分别释放状态和控制器。组件卸载只移除 UI 监听与绑定，不释放外部对象；状态可独立于 UI 存活并重新挂载。
- 异步 UI 业务返回后检查 mounted，再更新数据；通过 RefreshState 报告完成或失败。组件不会等待业务回调的 Future，也不代为处理业务异常。
- startRefresh/startLoading 和直接修改状态只更新状态与指示器；需要业务回调或主动滚动时使用控制器请求。
- position 在指示器挂载后可用，解绑后为 null。主动请求在布局完成后调用，或使用 SmartRefresher(initialRefresh: true)。
- 控制器操作均返回 Future<void>；两个 needMove 分支下，needCallback: false 都保留状态通知，见 [API](propertys.md#refreshcontroller)。

## 滚动结构

ListView、GridView、CustomScrollView 直接作为 child。背景、Scrollbar、NotificationListener 和 ScrollConfiguration 放在 SmartRefresher 外部。普通 child 使用 SliverRefreshBody；不要再包装 SingleChildScrollView。示例见 [README](README_CN.md#child)。

header/footer 可以是组合组件，但最终必须构建为 sliver，不能直接传普通 Container。builder 构造方式需要自行插入指示器并传递 RefreshPhysics。直接传 Scrollable 时，viewportBuilder 必须返回 Viewport，不能返回单子项或 shrink-wrapping viewport。

重建 ScrollView 会继承部分属性而非完整复制；shrinkWrap 不会透传。BoxScrollView 的自动系统 padding 也不会保留，需要时显式设置 padding 或使用 SafeArea。

## 短列表与 footer

hideFooterWhenNotFull 默认 false。设置 true 时，内容不足一屏会隐藏 footer 并禁用手势加载；noMore 状态仍可显示。默认 noMore 跟随内容，其他状态位于视口末端，可通过 shouldFooterFollowWhenNotFull 调整。

内部根据 precedingScrollExtent 并扣除刷新头部的 scrollExtent 判断内容是否超过一屏。复杂 sliver 的 scrollExtent 与实际占位可能不同；必要时关闭自动隐藏，自己计算 enablePullUp，参考 [手动隐藏](example/lib/ui/example/useStage/hidefooter_bycontent.dart) 和 [填充剩余空间](example/lib/ui/example/useStage/force_full_one_page.dart)。

LoadStyle 控制占位：ShowAlways 保留占位，HideAlways 不保留，ShowWhenLoading 只在加载期间保留；它们不等于直接开关绘制。短列表 footer 的 scrollExtent 还有额外处理。点击 footer 只调用 onClick，重试需要自行调用 requestLoading()。

## 特殊场景

- NestedScrollView 需要单独验证嵌套位置、主动请求和快速反向拖动，见 [示例](example/lib/ui/example/useStage/Nested.dart)。
- SliverAppBar / 持续头部与 UnFollow 的位置关系需要验证；示例在内容前加 SliverToBoxAdapter，见 [基础示例](example/lib/ui/example/useStage/basic.dart)。
- DraggableScrollableSheet 示例只启用上拉加载，并使用其提供的 ScrollController；见 [示例](example/lib/ui/example/otherwidget/draggable_bottomsheet_loadmore.dart)。
- 二楼目前按视口高度占位，水平二楼不应假定与垂直场景相同。直接 Scrollable 路径只启用 enableTwoLevel 不会插入 header。
- 自定义动画要自行 dispose AnimationController。LinkHeader/LinkFooter 的 linkKey 必须是已挂载 GlobalKey，外置 State 分别实现 RefreshProcessor/LoadingProcessor。

## 当前实现边界

部分配置变化不会自动通知子树，见 [配置说明](propertys.md#refreshconfiguration)。CustomHeader 的 onResetValue 目前未被调用；需要重置动画时继承 RefreshIndicatorState 重写 resetValue，或监听 onModeChange，见 [自定义指示器](custom_indicator.md)。

这些说明对应当前源码，不表示上述边界已经修复。
