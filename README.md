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

## Intro
a widget provided to the flutter scroll component drop-down refresh and pull up load.support android and ios.
[中文文档](README_CN.md)



## Features

* pull up load and pull down refresh
* Supports ListView, GridView, CustomScrollView and ordinary content; special scroll structures need adaptation
* provide global setting of default indicator and property
* provide some most common indicators
* Support Android and iOS default ScrollPhysics,the overScroll distance can be controlled,custom spring animate,damping,speed.
* horizontal and vertical refresh,support reverse ScrollView also(four direction)
* provide more refreshStyle: Behind,Follow,UnFollow,Front,provide more loadmore style
* Support twoLevel refresh,implments just like TaoBao twoLevel,Wechat TwoLevel
* enable link indicator which placing other place,just like Wechat FriendCircle refresh effect

## Requirements

This checkout requires **Dart ≥3.0 and Flutter ≥3.32**; see [pubspec.yaml](pubspec.yaml). Its version field remains 2.0.0. Use a path or Git dependency for this checkout's changes; the pub.dev release with the same version may differ.

## Usage

For a local checkout:

```yaml
dependencies:
  flutter:
    sdk: flutter
  pull_to_refresh:
    path: ../flutter_pulltorefresh
```

Adjust the path to your checkout. Place this complete widget inside a MaterialApp Scaffold. ListView must be the direct child of SmartRefresher; see [integration](#child).

```dart
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RefreshList extends StatefulWidget {
  const RefreshList({super.key});

  @override
  State<RefreshList> createState() => _RefreshListState();
}

class _RefreshListState extends State<RefreshList> {
  final RefreshController _controller = RefreshController();
  List<String> _items = List.generate(8, (index) => '${index + 1}');

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _items = List.generate(8, (index) => '${index + 1}'));
    _controller.refreshCompleted(resetFooterState: true);
  }

  Future<void> _onLoading() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _items.add('${_items.length + 1}'));
    _controller.loadComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
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

The delay simulates a request. Update your own data and finish the status explicitly: refreshFailed() for refresh errors, loadFailed() for loading errors, and loadNoData() when there is no more data. Use resetFooterState: true after refreshing to clear noMore. Create the controller in State, dispose it with the State, and check mounted after asynchronous work.

### Global configuration

RefreshConfiguration configures its subtree. Explicit header/footer values take precedence over global builders. copyAncestor inherits ancestor configuration and overrides selected values. See [all defaults](propertys_en.md).

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

### Localization

Add the flutter_localizations SDK dependency and import `package:flutter_localizations/flutter_localizations.dart`. The library provides 13 languages and falls back to English without localization.

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

## ScreenShots



### Examples

|Style| [basic](example/lib/ui/example/useStage/basic.dart) | [header in other place](example/lib/ui/example/customindicator/link_header_example.dart) | [reverse + horizontal](example/lib/ui/example/useStage/horizontal+reverse.dart) |
|:---:|:---:|:---:|:---:|
|| ![](arts/example1.gif) | ![](arts/example2.gif) |![](arts/example3.gif) |

|Style|  [twoLevel](example/lib/ui/example/useStage/twolevel_refresh.dart) |[use with other widgets](example/lib/ui/example/otherwidget) |  [chat](example/lib/ui/example/useStage/qq_chat_list.dart) |
|:---:|:---:|:---:|:---:|
||  ![](arts/example4.gif) |![](arts/example5.gif) | ![](arts/example6.gif) |


|Style| [simple custom header(使用SpinKit)](example/lib/ui/example/customindicator/spinkit_header.dart)| [dragableScrollSheet+LoadMore](example/lib/ui/example/otherwidget/draggable_bottomsheet_loadmore.dart)|[Gif Indicator](example/lib/ui/example/customindicator/gif_indicator_example1.dart) |
|:---:|:---:|:---:|:---:|
|| ![](arts/example7.gif) | ![](arts/example8.gif) | ![](arts/gifindicator.gif) |



### Indicator


| refresh style |   |pull up load style| |
|:---:|:---:|:---:|:---:|
| RefreshStyle.Follow <br>![Follow](example/images/refreshstyle1.gif)|RefreshStyle.UnFollow <br> ![不跟随](example/images/refreshstyle2.gif)| LoadStyle.ShowAlways <br>  ![始终占位](example/images/loadstyle1.gif) | LoadStyle.HideAlways<br> ![不占位](example/images/loadstyle2.gif)|
| RefreshStyle.Behind <br> ![背部](example/images/refreshstyle3.gif)| RefreshStyle.Front <br> ![前面悬浮](example/images/refreshstyle4.gif)| LoadStyle.ShowWhenLoading<br>  ![加载时占位](example/images/loadstyle3.gif) | |

|Style| [ClassicIndicator](lib/src/indicator/classic_indicator.dart) | [WaterDropHeader](lib/src/indicator/waterdrop_header.dart) | [MaterialClassicHeader](lib/src/indicator/material_indicator.dart) |
|:---:|:---:|:---:|:---:|
|| ![](example/images/classical_follow.gif) | ![](example/images/warterdrop.gif) | ![](example/images/material_classic.gif) |

|Style|  [WaterDropMaterialHeader](lib/src/indicator/material_indicator.dart) | [Shimmer Indicator](example/lib/ui/example/customindicator/shimmer_indicator.dart) |[Bezier+Circle](lib/src/indicator/bezier_indicator.dart) |
|:---:|:---:|:---:|:---:|
||  ![](example/images/material_waterdrop.gif) |![](example/images/shimmerindicator.gif) | ![](example/images/bezier.gif) |


<a name="child"></a>

## Child integration

SmartRefresher selects an integration path using the actual child type:

- **ListView / GridView**: extracts the content sliver, preserves explicit padding and inserts indicators. Automatic BoxScrollView system padding is not retained; use SafeArea or explicit padding when needed.
- **CustomScrollView and other ScrollViews**: extracts slivers and rebuilds a CustomScrollView. Only selected scroll properties are inherited; the child's shrinkWrap is not forwarded.
- **Ordinary widgets / empty views**: wraps content in SliverRefreshBody; content that expands to its constraints is laid out again using the viewport's main-axis extent.
- **Scrollable**: rebuilds the Scrollable, requires viewportBuilder to return a Viewport, and inserts indicators into its children. This path currently inserts the header only when enablePullDown is true; use a ScrollView or builder for two-level-only integration.
- **SmartRefresher.builder**: assemble slivers yourself and apply the supplied RefreshPhysics.

Do not place Container, Scrollbar, NotificationListener or a custom widget that returns a ListView between SmartRefresher and the target ScrollView. It would use the ordinary-widget path and create nested scrollables. Put decoration and listeners outside SmartRefresher:

```dart
Scrollbar(
  child: SmartRefresher(
    controller: controller,
    child: ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => Text(items[index]),
    ),
  ),
)
```

This fragment assumes controller and items are defined in State. Use [SliverAnimatedList](example/lib/ui/example/otherwidget/refresh_animatedlist_example.dart) for animated lists and the [adapter example](example/lib/ui/example/otherwidget/refresh_recordable_listview_example.dart) for reordering. Pass SingleChildScrollView's content directly instead of nesting the scroll view. For paging, see [PageScrollPhysics + SliverFillViewport](example/lib/ui/example/otherwidget/refresh_pageView_example.dart).

## More

- [Property Document](propertys_en.md) or [Api/Doc](https://pub.dev/documentation/pull_to_refresh/latest/pulltorefresh/SmartRefresher-class.html)
- [Custom Indicator](custom_indicator_en.md)
- [Inner Attribute Of Indicators](indicator_attribute_en.md)
- [Update Log](CHANGELOG.md)
- [Notice](notice_en.md)
- [FAQ](problems_en.md)


## Integration limits

- Validate NestedScrollView positions and overscroll behavior separately, especially quick direction changes; see the [example](example/lib/ui/example/useStage/Nested.dart).
- Two-level layout currently uses viewport height; horizontal two-level scenarios need separate validation.
- Some dynamic configuration changes do not notify dependents automatically. Explicit requests and custom callbacks also have implementation limits; see [API](propertys_en.md) and [notice](notice_en.md).

## Thanks

[SmartRefreshLayout](https://github.com/scwang90/SmartRefreshLayout)

## LICENSE


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
