import 'Test1.dart';
import 'Test2.dart';
import 'Test3.dart';
import 'Test4.dart';
import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  TestPage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _TestPageState createState() => new _TestPageState();
}

class _TestPageState extends State<TestPage>
    with SingleTickerProviderStateMixin {
  int tabIndex = 0;
  PageController? _pageController;
  late List<Widget> views;
  GlobalKey<Test3State> example3Key = GlobalKey();
  GlobalKey<Test1State> example1Key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: views,
            onPageChanged: (index) {
              tabIndex = index;
              if (mounted) setState(() {});
            },
          ),
        ),
        BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.home,
                    color: tabIndex == 0 ? Colors.blue : Colors.grey),
                label: 'Example1'),
            BottomNavigationBarItem(
                icon: Icon(Icons.cloud,
                    color: tabIndex == 1 ? Colors.blue : Colors.grey),
                label: 'Example2'),
            BottomNavigationBarItem(
                icon: Icon(Icons.call,
                    color: tabIndex == 2 ? Colors.blue : Colors.grey),
                label: 'Example3'),
            BottomNavigationBarItem(
                icon: Icon(Icons.transform,
                    color: tabIndex == 3 ? Colors.blue : Colors.grey),
                label: 'Example4'),
          ],
          onTap: (index) {
            _pageController!.jumpToPage(index);
          },
          currentIndex: tabIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        )
      ],
    );
  }

  @override
  void initState() {
    _pageController = PageController();
    views = [
      Test1(key: example1Key),
      Test2(),
      Test3(key: example3Key),
      Test4()
    ];
    super.initState();
  }
}
