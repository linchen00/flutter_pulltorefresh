import 'package:example/other/refresh_recordable_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() {
  testWidgets('starting and moving a reorder drag does not throw',
      (WidgetTester tester) async {
    final RefreshController refreshController = RefreshController();
    final List<(int, int)> reorders = <(int, int)>[];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RefreshReorderableListView(
          refreshController: refreshController,
          enablePullDown: false,
          children: <Widget>[
            for (final String label in <String>['A', 'B', 'C'])
              SizedBox(
                key: ValueKey<String>(label),
                height: 80,
                child: Center(child: Text(label)),
              ),
          ],
          onReorder: (int from, int to) => reorders.add((from, to)),
        ),
      ),
    ));

    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(find.text('A')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);

    await gesture.moveTo(tester.getCenter(find.text('C')));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(reorders, isNotEmpty);
    refreshController.dispose();
  });
}
