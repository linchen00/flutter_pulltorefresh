import 'package:flutter/material.dart' hide RefreshIndicator;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:pull_to_refresh/src/internals/slivers.dart';

void main() {
  testWidgets('BezierCircleHeader builds as a sliver', (tester) async {
    final RefreshState state = RefreshState();
    final controller = RefreshController();
    addTearDown(controller.dispose);
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SmartRefresher(
          state: state,
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
    expect(find.byType(SliverRefresh, skipOffstage: false), findsOneWidget);

    state.startRefresh();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.isRefresh, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    state.refreshCompleted();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final background = tester
        .widgetList<ClipPath>(find.byType(ClipPath))
        .firstWhere((clip) =>
            clip.clipper.runtimeType.toString() == '_BezierDismissPainter');
    // The background stays in place until the circle's 550ms exit finishes.
    expect((background.clipper as dynamic).value, 0.0);
    // The progress widget has an ongoing animation even when its color is
    // transparent; wait for the refresh lifecycle rather than all UI tickers.
    for (var frame = 0;
        frame < 40 && state.headerStatus != RefreshStatus.idle;
        frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(state.headerStatus, RefreshStatus.idle);
    expect(tester.takeException(), isNull);
  });
}
