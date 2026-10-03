# flutter_pulltorefresh
<a href="https://pub.dev/packages/pull_to_refresh">
  <img src="https://img.shields.io/pub/v/pull_to_refresh.svg"/>
</a>
<a href="https://flutter.dev/">
  <img src="https://img.shields.io/badge/flutter-%3E%3D%203.32.0-green.svg"/>
</a>
<a href="https://opensource.org/licenses/MIT">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg"/>
</a>

## 介绍
一个提供上拉加载和下拉刷新的组件,同时支持Android和Ios<br>



## 特性

* 提供上拉加载和下拉刷新
* 支持 ListView、GridView、CustomScrollView 及普通内容，特殊滚动结构需要适配
* 提供全局设置默认指示器和属性
* 提供多种比较常用的指示器
* 支持Android和iOS默认滑动引擎,可限制越界距离,打造自定义弹性动画,速度,阻尼等。
* 支持水平和垂直刷新,同时支持翻转列表(四个方向)
* 提供多种刷新指示器风格:跟随,不跟随,位于背部,位于前部, 提供多种加载更多风格
* 提供二楼刷新,可实现类似淘宝二楼,微信二楼,携程二楼
* 允许关联指示器存放在Viewport外部,即朋友圈刷新效果

## 环境要求

本仓库要求 **Dart ≥3.0、Flutter ≥3.32**，见 [pubspec.yaml](pubspec.yaml)。版本字段仍为 2.0.0；使用本仓库修改后的实现时，可通过 path 或 Git 依赖接入，pub.dev 同版本的发布内容不一定与本仓库相同。

## 用法

使用本地仓库：

```yaml
dependencies:
  flutter:
    sdk: flutter
  pull_to_refresh:
    path: ../flutter_pulltorefresh
```

调整 path 为实际仓库路径。以下完整组件可放在 MaterialApp 的 Scaffold 中。ListView 必须直接作为 SmartRefresher 的 child，详见 [child 接入说明](#child)。

```dart
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RefreshList extends StatefulWidget {
  const RefreshList({super.key});

  @override
  State<RefreshList> createState() => _RefreshListState();
}

class _RefreshListState extends State<RefreshList> {
  final RefreshState _refreshState = RefreshState();
  final RefreshController _controller = RefreshController();
  List<String> _items = List.generate(8, (index) => '${index + 1}');

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _items = List.generate(8, (index) => '${index + 1}'));
    _refreshState.refreshCompleted(resetFooterState: true);
  }

  Future<void> _onLoading() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _items.add('${_items.length + 1}'));
    _refreshState.loadComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    _refreshState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      state: _refreshState,
      controller: _controller,
      enablePullUp: true,
      header: const WaterDropHeader(),
      footer: ClassicFooter(onClick: () => _controller.requestLoading()),
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: ListView.builder(
        itemCount: _items.length,
        itemExtent: 100,
        itemBuilder: (context, index) => Center(child: Text(_items[index])),
      ),
    );
  }
}
```

示例用延时模拟请求。真实业务需要自行更新数据并结束状态：刷新失败调用 refreshFailed()，加载失败调用 loadFailed()，无更多数据调用 loadNoData()。刷新后使用 resetFooterState: true 恢复无更多数据状态。状态和可选控制器在 State 中创建并分别在 dispose 中释放；异步操作完成后先检查 mounted。

RefreshState 必填，controller 可选。状态可脱离 UI 使用；startRefresh/startLoading 和直接修改状态不触发业务回调。initialRefresh 现属于 SmartRefresher。此次 API 直接迁移，见 [状态与控制器 API](propertys.md#refreshstate)。

### 全局配置

RefreshConfiguration 配置整个子树。局部 header/footer 优先于全局 builder；copyAncestor 可继承祖先配置并覆盖指定参数。完整默认值见 [属性文档](propertys.md)。

```dart
RefreshConfiguration(
  headerBuilder: () => const WaterDropHeader(),
  footerBuilder: () => const ClassicFooter(),
  headerTriggerDistance: 80,
  footerTriggerDistance: 15,
  hideFooterWhenNotFull: false,
  enableBallisticLoad: true,
  child: MaterialApp(home: Scaffold(body: const RefreshList())),
)
```

### 国际化

添加 flutter_localizations SDK 依赖，并导入 `package:flutter_localizations/flutter_localizations.dart`。库提供 13 种语言，未设置本地化时文字回退英文。

```dart
MaterialApp(
  localizationsDelegates: const [
    RefreshLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('zh')],
  home: Scaffold(body: const RefreshList()),
)
```

## 截图

### 例子

|Style| [基础用法](example/lib/ui/example/useStage/basic.dart) | [header放在其他位置](example/lib/ui/example/customindicator/link_header_example.dart) | [水平+翻转刷新](example/lib/ui/example/useStage/horizontal+reverse.dart) |
|:---:|:---:|:---:|:---:|
|| ![](arts/example1.gif) | ![](arts/example2.gif) |![](arts/example3.gif) |

|Style|  [二楼刷新](example/lib/ui/example/useStage/twolevel_refresh.dart) |[兼容其他特殊组件](example/lib/ui/example/otherwidget) |  [聊天列表](example/lib/ui/example/useStage/qq_chat_list.dart) |
|:---:|:---:|:---:|:---:|
||  ![](arts/example4.gif) |![](arts/example5.gif) | ![](arts/example6.gif) |


|Style| [简单自定义刷新指示器(使用SpinKit)](example/lib/ui/example/customindicator/spinkit_header.dart)| [dragableScrollSheet+LoadMore](example/lib/ui/example/otherwidget/draggable_bottomsheet_loadmore.dart)|[Gif Indicator](example/lib/ui/example/customindicator/gif_indicator_example1.dart) |
|:---:|:---:|:---:|:---:|
|| ![](arts/example7.gif) | ![](arts/example8.gif) | ![](arts/gifindicator.gif) |

### 各种指示器

| 下拉刷新风格 |   |上拉加载风格| |
|:---:|:---:|:---:|:---:|
| RefreshStyle.Follow <br> ![跟随](example/images/refreshstyle1.gif) |RefreshStyle.UnFollow <br>  ![不跟随](example/images/refreshstyle2.gif)| LoadStyle.ShowAlways <br> ![始终占位](example/images/loadstyle1.gif) | LoadStyle.HideAlways<br>  ![不占位](example/images/loadstyle2.gif)|
| RefreshStyle.Behind <br> ![背部](example/images/refreshstyle3.gif)| RefreshStyle.Front <br> ![前面悬浮](example/images/refreshstyle4.gif)| LoadStyle.ShowWhenLoading<br> ![加载时占位](example/images/loadstyle3.gif) | |

|Style| [ClassicIndicator](lib/src/indicator/classic_indicator.dart) | [WaterDropHeader](lib/src/indicator/waterdrop_header.dart) | [MaterialClassicHeader](lib/src/indicator/material_indicator.dart) |
|:---:|:---:|:---:|:---:|
|| ![](example/images/classical_follow.gif) | ![](example/images/warterdrop.gif) | ![](example/images/material_classic.gif) |

|Style|  [WaterDropMaterialHeader](lib/src/indicator/material_indicator.dart) | [Shimmer 指示器](example/lib/ui/example/customindicator/shimmer_indicator.dart) |[Bezier+Circle](lib/src/indicator/bezier_indicator.dart) |
|:---:|:---:|:---:|:---:|
||  ![](example/images/material_waterdrop.gif) |![](example/images/shimmerindicator.gif) | ![](example/images/bezier.gif) |

<a name="child"></a>

## child 接入说明

SmartRefresher 根据 child 的实际类型处理滚动结构：

- **ListView / GridView**：提取内部 sliver，保留显式 padding，再插入头尾指示器。不会保留 BoxScrollView 自动注入的系统 padding；需要时使用 SafeArea 或显式 padding。
- **CustomScrollView 等 ScrollView**：提取 slivers，重建 CustomScrollView。只继承部分滚动属性，原 child 的 shrinkWrap 不会透传。
- **普通 Widget / 空视图**：包装为 SliverRefreshBody，让内容可滚动；撑满约束的内容会重新按视口主轴尺寸布局。
- **Scrollable**：重建 Scrollable，要求 viewportBuilder 返回 Viewport，再向其 children 插入指示器。此路径目前仅以 enablePullDown 判断是否插入 header；只启用二楼时请使用 ScrollView 或 builder 路径。
- **SmartRefresher.builder**：自行组装 slivers 并使用传入的 RefreshPhysics，适合需要控制滚动结构的场景。

不要在 SmartRefresher 与目标 ScrollView 之间放 Container、Scrollbar、NotificationListener 或返回 ListView 的自定义组件，否则目标列表会被当作普通 Widget，产生滚动嵌套。装饰和监听组件放在 SmartRefresher 外部：

```dart
Scrollbar(
  child: SmartRefresher(
    state: refreshState,
    controller: controller,
    child: ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => Text(items[index]),
    ),
  ),
)
```

该片段假定 refreshState、controller 和 items 已在 State 中定义；只需要手势时可省略 controller。AnimatedList 使用 [SliverAnimatedList 示例](example/lib/ui/example/otherwidget/refresh_animatedlist_example.dart)；拖拽排序使用 [适配示例](example/lib/ui/example/otherwidget/refresh_recordable_listview_example.dart)。不要直接嵌入 SingleChildScrollView，直接传入它的内容。分页接入参考 [PageScrollPhysics + SliverFillViewport 示例](example/lib/ui/example/otherwidget/refresh_pageView_example.dart)。

## 更多

- [属性文档](propertys.md) 或者 [Api/Doc](https://pub.dev/documentation/pull_to_refresh/latest/pulltorefresh/SmartRefresher-class.html)
- [自定义指示器](custom_indicator.md)
- [指示器内部属性介绍](indicator_attribute.md)
- [更新日志](CHANGELOG.md)
- [注意地方](notice.md)
- [常见问题](problems.md)

## 接入限制

- NestedScrollView 的嵌套位置与越界回弹需要单独验证，尤其是快速反向拖动；见 [示例](example/lib/ui/example/useStage/Nested.dart)。
- 二楼占位目前取视口高度，水平二楼场景需要单独验证。
- 部分动态配置不会自动通知依赖组件；主动请求及自定义回调也有实现边界，详见 [属性文档](propertys.md) 与 [注意事项](notice.md)。

## 感谢

[SmartRefreshLayout](https://github.com/scwang90/SmartRefreshLayout)


## 开源协议

```

MIT License

Copyright (c) 2018 Jpeng

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


 ```
