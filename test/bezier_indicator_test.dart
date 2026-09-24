import 'package:flutter/material.dart' hide RefreshIndicator;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() {
  testWidgets('BezierCircleHeader builds as a sliver', (tester) async {
    final controller = RefreshController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SmartRefresher(
          controller: controller,
          header: BezierCircleHeader(
            dismissType: BezierDismissType.ScaleToCenter,
          ),
          child: ListView.builder(
            itemCount: 15,
            itemExtent: 100,
            itemBuilder: (context, index) => Text('Item $index'),
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    final viewport = tester.renderObject<RenderViewport>(find.byType(Viewport));
    expect(viewport.firstChild, isA<RenderSliver>());
  });
}
