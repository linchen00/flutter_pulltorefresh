/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time: 2019/5/3 下午6:13
 */

import 'package:flutter/material.dart';

import 'example/ExamplePage.dart';
import 'indicator/IndicatorPage.dart';
import 'test/TestPage.dart';

class MainActivity extends StatefulWidget {
  final String? title;

  MainActivity({this.title});

  @override
  State<StatefulWidget> createState() {
    return _MainActivityState();
  }
}

class _MainActivityState extends State<MainActivity>
    with TickerProviderStateMixin {
  late List<Widget> views;
  final MenuController _menuController = MenuController();
  TabController? _tabController;
  int _tabIndex = 1;
  PageController? _pageController;

  Widget buildItem(String msg, Widget icon, VoidCallback onTap) {
    return MenuItemButton(
      leadingIcon: icon,
      trailingIcon: const Icon(Icons.arrow_forward, color: Colors.grey),
      onPressed: onTap,
      child: Text(msg),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _pageController = PageController(initialPage: 1);
    views = [
      IndicatorPage(title: "指示器界面"),
      ExamplePage(),
      TestPage(title: "测试界面"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_tabIndex == 0
              ? "指示器界面"
              : _tabIndex == 1
                  ? "例子界面"
                  : _tabIndex == 2
                      ? "测试界面"
                      : _tabIndex == 3
                          ? "样例界面"
                          : "App界面"),
          leading: MenuAnchor(
            controller: _menuController,
            alignmentOffset: const Offset(0, 8),
            menuChildren: [
              SizedBox(
                width: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxHeight: 80, maxWidth: 80),
                        child: const CircleAvatar(
                          backgroundImage: NetworkImage(
                            'https://avatars1.githubusercontent.com/u/19425362?s=400&u=1a30f9fdf71cc9a51e20729b2fa1410c710d0f2f&v=4',
                          ),
                          radius: 40,
                        ),
                      ),
                    ),
                    buildItem("各种指示器",
                        const Icon(Icons.apps, size: 18, color: Colors.grey),
                        () {
                      setState(() => _tabIndex = 0);
                      _pageController!.jumpToPage(0);
                      _menuController.close();
                    }),
                    buildItem("例子", const Icon(Icons.insert_emoticon,
                        size: 18, color: Colors.grey), () {
                      setState(() => _tabIndex = 1);
                      _pageController!.jumpToPage(1);
                      _menuController.close();
                    }),
                    buildItem("测试", const Icon(Icons.airplanemode_active,
                        size: 18, color: Colors.grey), () {
                      setState(() => _tabIndex = 2);
                      _menuController.close();
                      _pageController!.jumpToPage(2);
                    }),
                  ],
                ),
              ),
            ],
            child: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _menuController.isOpen
                  ? _menuController.close()
                  : _menuController.open(),
            ),
          ),
          backgroundColor: Colors.greenAccent,
          bottom: _tabIndex == 3
              ? TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(child: Text("超大数据量性能测试")),
                    Tab(child: Text("SliverAppbar+Sliverheader")),
                    Tab(child: Text("嵌套滚动视图")),
                    Tab(child: Text("动态变化指示器+Navigator")),
                    Tab(child: Text("主动刷新")),
                    Tab(child: Text("四个方向不同风格测试绘制")),
                  ],
                  controller: _tabController,
                )
              : null,
        ),
        body: PageView(
          controller: _pageController,
          children: views,
          physics: NeverScrollableScrollPhysics(),
        ),
    );
  }
}
