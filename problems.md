# 常见问题

## 如何监听或控制滚动？

把自己的 ScrollController 传给直接作为 child 的 ScrollView，或传入 SmartRefresher.scrollController。RefreshController.position 在指示器挂载后可用于跳转；RefreshController.scrollController 已移除。

## 为什么看不到 header/footer？

先检查 enablePullDown/enablePullUp，再检查 ListView 是否直接作为 child。如果外面套了 Container、Scrollbar 或自定义 Widget，会产生滚动嵌套。AnimatedList 使用 [SliverAnimatedList](example/lib/ui/example/otherwidget/refresh_animatedlist_example.dart)，排序列表参考 [适配示例](example/lib/ui/example/otherwidget/refresh_recordable_listview_example.dart)。

## 为什么刷新或加载一直不结束？

onRefresh/onLoading 是触发回调，组件不会等待业务 Future 来结束状态。请求完成后须调用 refreshCompleted/refreshFailed 或 loadComplete/loadFailed/loadNoData。异常路径也要结束状态；返回页面后先检查 mounted。

## 如何在刷新后恢复加载？

调用 refreshCompleted(resetFooterState: true)，或在 footer 为 noMore 时调用 resetNoData()。默认 enableLoadingWhenNoData 为 false。点击失败提示重试需要配置 footer.onClick 并调用 requestLoading()。

## 短列表如何隐藏或调整 footer？

hideFooterWhenNotFull: true 隐藏短列表 footer 并禁用手势加载，noMore 状态仍可显示。保持 false 时，默认 noMore 跟随内容，其他状态在视口末端；shouldFooterFollowWhenNotFull 可修改。复杂 sliver 可使用 [手动判断](example/lib/ui/example/useStage/hidefooter_bycontent.dart)；需要撑满一屏参考 [填充示例](example/lib/ui/example/useStage/force_full_one_page.dart)。

## 拖到最大距离仍不触发，或希望提前加载？

headerTriggerDistance 是下拉越界距离。footerTriggerDistance 判断 maxScrollExtent - pixels；正数可提前加载，负数要求底部越界。检查 maxOverScrollExtent/maxUnderScrollExtent 是否允许到达阈值，并考虑指示器占位补偿。不是所有物理配置都只由平台决定，见 [默认值](propertys.md#refreshconfiguration)。

## 如何控制弹性与惯性加载？

通过 springDescription 调整 mass、stiffness、damping，通过 dragSpeedRatio 调整越界拖动比例。maxOverScrollExtent/maxUnderScrollExtent 限制拖动越界；topHitBoundary/bottomHitBoundary 限制惯性越界。enableBallisticLoad 默认 true；设为 false 可以要求先拖动到 canLoading 再松手加载。

## 如何接入 PageView 或 SingleChildScrollView？

不要直接嵌套同轴滚动组件。普通内容直接传给 SmartRefresher，布局需有合适约束。分页参考 [PageScrollPhysics + SliverFillViewport](example/lib/ui/example/otherwidget/refresh_pageView_example.dart)。横向子滚动组件需要有限高度；出现 unbounded height 时检查外层约束。

## 如何实现 GIF 或复杂动画？

使用 CustomHeader/CustomFooter 的位移和状态回调，或继承指示器 State。GIF 的 [示例](example/lib/ui/example/customindicator/gif_indicator_example1.dart) 使用 gif_view 切换帧段；随拖动变化可在 onOffsetChange 中调用 GifController.seek。更多见 [自定义指示器](custom_indicator.md)。

## 为什么顶部被遮挡，或状态栏点击不回顶部？

重建后的 CustomScrollView 不保留 BoxScrollView 自动系统 padding，使用 SafeArea 或显式 padding。设置自己的 ScrollController 后，滚动组件可能不再使用 Scaffold 的 PrimaryScrollController；检查 primary、控制器与 Scaffold 层级。

## NestedScrollView 或其他自定义物理规则能否直接兼容？

需要验证具体结构。刷新组件监听 ScrollPosition，并叠加 RefreshPhysics；特殊滚动组件的活动、边界和 Viewport 假设可能不同。参考 [注意事项](notice.md) 与 [NestedScrollView 示例](example/lib/ui/example/useStage/Nested.dart)。

## needCallback: false 为什么仍触发回调？

当前只有 needMove: true 分支处理 needCallback。needMove: false 仍通知状态监听器并触发业务回调，详见 [API](propertys.md#refreshcontroller)。
