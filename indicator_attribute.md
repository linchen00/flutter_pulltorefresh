# 指示器属性

触发距离、惯性行为和越界限制配置在 RefreshConfiguration；业务回调配置在 SmartRefresher。见 [API](propertys.md)。

## 通用属性与样式

头部 RefreshIndicator：height 默认 60.0，表示刷新期间保留的主轴布局范围；offset 默认 0.0，是绘制偏移；completeDuration 默认 500ms，是默认结束流程的停留时间；refreshStyle 默认 Follow。具体指示器可能覆盖这些默认值。

| RefreshStyle | 行为 |
|---|---|
| Follow | 随内容移动 |
| UnFollow | 完全露出后不再继续跟随 |
| Behind | 随越界距离伸展，位于内容后方 |
| Front | 位于内容前方，使用特殊布局与绘制机制 |

底部 LoadIndicator：height 默认 60.0；onClick 可空，只提供点击回调；loadStyle 默认 ShowAlways。

| LoadStyle | 占位行为 |
|---|---|
| ShowAlways | 保留布局空间 |
| HideAlways | 不保留布局空间，仍可能在越界时绘制 |
| ShowWhenLoading | 加载期间保留布局空间，结束动画完成后撤销 |

短列表的 footer scrollExtent 另有处理，跟随内容和自动隐藏由 RefreshConfiguration 决定。横向布局时，自定义内容也要提供合适的宽度。

## ClassicHeader / ClassicFooter

支持状态文字与图标、spacing（默认 15.0）、textStyle、iconPos（left/right/top/bottom）。outerBuilder 可包装背景、padding 或改变内容尺寸；此时布局由包装内容决定。

ClassicHeader 的 height 默认 60.0，completeDuration 默认 600ms。ClassicFooter 的 height 默认 60.0，completeDuration 默认 300ms；它在 endLoading 中使用该延时，ShowWhenLoading 时占位消失最明显。无更多数据的图标默认为空。加载中的图标按平台选择 CupertinoActivityIndicator 或 CircularProgressIndicator。

## WaterDropHeader

使用 UnFollow，height 固定为 60.0，completeDuration 默认 600ms。waterDropColor 控制水滴颜色，idleIcon 控制拖动时的图标，refresh/complete/failed 可替换各状态内容。

## MaterialClassicHeader / WaterDropMaterialHeader

使用 Front。MaterialClassicHeader 的 height 默认 80.0，distance 默认 50.0；WaterDropMaterialHeader 的 height 固定为 80.0，distance 默认 60.0。distance 控制刷新期间的显示位置，offset 控制绘制偏移；还支持 color、backgroundColor、semanticsLabel、semanticsValue。结束流程使用缩放动画，而非基础指示器的完成延时。

## 贝塞尔、二楼与自定义指示器

BezierHeader 使用 UnFollow，rectHeight 默认 70；可设置颜色、子项溢出、准备/结束动画和重置回调。BezierCircleHeader 在此基础上组合圆形进度动画，支持 Progress/Raidal 与 None/RectSpread/ScaleToCenter 消失方式。

TwoLevelHeader 组合 ClassicHeader；height 默认 80.0，completeDuration 默认 600ms。displayAlignment.fromBottom 使用 Follow，fromTop/fromCenter 使用 Behind；二楼状态显示 twoLevelWidget，decoration 用于普通拖动阶段背景。

CustomHeader/CustomFooter 与 LinkHeader/LinkFooter 的生命周期接口见 [自定义指示器](custom_indicator.md)。
