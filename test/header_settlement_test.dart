import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:pull_to_refresh/src/internals/slivers.dart';

import 'refresh_state_widget_test.dart' show buildStateRefresher;

Offset pullDelta(Axis axis, bool reverse, double distance) =>
    axis == Axis.vertical
        ? Offset(0, reverse ? -distance : distance)
        : Offset(reverse ? -distance : distance, 0);

Future<void> pullToRefresh(WidgetTester tester, Axis axis, bool reverse) async {
  final gesture = await tester.startGesture(const Offset(400, 300));
  for (var step = 0; step < 8; step++) {
    await gesture.moveBy(pullDelta(axis, reverse, 50));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await gesture.up();
}

void main() {
  for (final axis in Axis.values) {
    testWidgets('skipCanRefresh settles after the original drag $axis',
        (tester) async {
      final state = RefreshState();
      final scroll = ScrollController();
      addTearDown(state.dispose);
      addTearDown(scroll.dispose);
      var callbacks = 0;
      await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: RefreshConfiguration(
              skipCanRefresh: true,
              child: SmartRefresher(
                  state: state,
                  onRefresh: () => callbacks++,
                  header: CustomHeader(
                      builder: (_, mode) => SizedBox(
                          width: mode == RefreshStatus.refreshing ? 200 : 40,
                          height: mode == RefreshStatus.refreshing ? 200 : 40)),
                  child: ListView.builder(
                      controller: scroll,
                      scrollDirection: axis,
                      itemCount: 20,
                      itemExtent: 100,
                      itemBuilder: (_, index) => Text('Item $index'))))));
      final drag = await tester.startGesture(const Offset(400, 300));
      for (var step = 0; step < 8; step++) {
        await drag.moveBy(pullDelta(axis, false, 50));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(state.isRefresh, isTrue);
      await drag.up();
      await tester.pumpAndSettle();
      expect(scroll.offset, closeTo(scroll.position.minScrollExtent, 0.01));
      expect(callbacks, 1);
      expect(tester.takeException(), isNull);
    });

    for (final reverse in [false, true]) {
      for (final movement in ['jump', 'animate', 'loading']) {
        for (final beforeFirstTick in [false, true]) {
          testWidgets(
              '$movement replaces settlement $axis $reverse beforeFirstTick=$beforeFirstTick',
              (tester) async {
            final state = RefreshState();
            final scroll = ScrollController();
            final controller = RefreshController();
            addTearDown(state.dispose);
            addTearDown(scroll.dispose);
            addTearDown(controller.dispose);
            var loads = 0;
            await tester.pumpWidget(buildStateRefresher(state,
                scrollDirection: axis,
                reverse: reverse,
                scrollController: scroll,
                controller: controller,
                onLoading: () => loads++,
                header: CustomHeader(
                    builder: (_, mode) => SizedBox(
                        width: mode == RefreshStatus.refreshing ? 200 : 40,
                        height: mode == RefreshStatus.refreshing ? 200 : 40))));
            await pullToRefresh(tester, axis, reverse);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 16));
            expect(state.isRefresh, isTrue);
            expect(scroll.position.activity, isA<BallisticScrollActivity>());
            if (!beforeFirstTick) {
              await tester.pump(const Duration(milliseconds: 64));
            }
            if (movement == 'jump') {
              scroll.jumpTo(400);
            } else if (movement == 'animate') {
              final animation = scroll.animateTo(400,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear);
              await tester.pumpAndSettle();
              await animation;
            } else {
              final loading = controller.requestLoading();
              await tester.pumpAndSettle();
              await loading;
            }
            await tester.pumpAndSettle();
            expect(scroll.offset,
                movement == 'loading' ? scroll.position.maxScrollExtent : 400);
            expect(state.isRefresh, isTrue);
            expect(loads, movement == 'loading' ? 1 : 0);
            expect(tester.takeException(), isNull);
          });
        }
      }

      testWidgets(
          'resize after a jump preserves the new body anchor $axis $reverse',
          (tester) async {
        final state = RefreshState();
        final scroll = ScrollController();
        final size = ValueNotifier<double>(200);
        addTearDown(state.dispose);
        addTearDown(scroll.dispose);
        addTearDown(size.dispose);
        await tester.pumpWidget(buildStateRefresher(state,
            scrollDirection: axis,
            reverse: reverse,
            scrollController: scroll,
            header: CustomHeader(
                builder: (_, mode) => ValueListenableBuilder<double>(
                    valueListenable: size,
                    builder: (_, extent, __) => SizedBox(
                        width: mode == RefreshStatus.refreshing ? extent : 40,
                        height:
                            mode == RefreshStatus.refreshing ? extent : 40)))));
        await pullToRefresh(tester, axis, reverse);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        scroll.jumpTo(400);
        await tester.pump();
        final anchor = tester.getTopLeft(find.text('Item 4'));
        size.value = 300;
        await tester.pumpAndSettle();
        expect(scroll.offset, 500);
        expect(tester.getTopLeft(find.text('Item 4')), anchor);
        expect(tester.takeException(), isNull);
      });

      testWidgets('content can grow during settlement $axis $reverse',
          (tester) async {
        final state = RefreshState();
        final scroll = ScrollController();
        final size = ValueNotifier<double>(200);
        addTearDown(state.dispose);
        addTearDown(scroll.dispose);
        addTearDown(size.dispose);
        await tester.pumpWidget(buildStateRefresher(state,
            scrollDirection: axis,
            reverse: reverse,
            scrollController: scroll,
            header: CustomHeader(
                builder: (_, mode) => ValueListenableBuilder<double>(
                    valueListenable: size,
                    builder: (_, extent, __) => SizedBox(
                        width: mode == RefreshStatus.refreshing ? extent : 40,
                        height:
                            mode == RefreshStatus.refreshing ? extent : 40)))));
        await pullToRefresh(tester, axis, reverse);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(state.isRefresh, isTrue);
        size.value = 300;
        await tester.pumpAndSettle();
        final header = tester.renderObject<RenderSliverRefresh>(
            find.byType(SliverRefresh, skipOffstage: false));
        expect(header.layoutResult!.effectiveExtent, 300);
        expect(scroll.offset, closeTo(scroll.position.minScrollExtent, 0.01));
        expect(tester.takeException(), isNull);
      });

      for (final style in RefreshStyle.values) {
        for (final activeExtent in [0.0, 40.0, 200.0]) {
          testWidgets(
              'gesture settles at the active header edge $axis $reverse $style extent=$activeExtent',
              (tester) async {
            final state = RefreshState();
            final scroll = ScrollController();
            addTearDown(state.dispose);
            addTearDown(scroll.dispose);
            var callbacks = 0;
            await tester.pumpWidget(buildStateRefresher(state,
                scrollDirection: axis,
                reverse: reverse,
                scrollController: scroll,
                onRefresh: () => callbacks++,
                header: CustomHeader(
                    refreshStyle: style,
                    builder: (_, mode) => SizedBox(
                        width: mode == RefreshStatus.refreshing
                            ? activeExtent
                            : 40,
                        height: mode == RefreshStatus.refreshing
                            ? activeExtent
                            : 40))));
            await pullToRefresh(tester, axis, reverse);
            double? previousPixels;
            for (var frame = 0; frame < 60; frame++) {
              await tester.pump(const Duration(milliseconds: 16));
              final header = tester.renderObject<RenderSliverRefresh>(
                  find.byType(SliverRefresh, skipOffstage: false));
              if (activeExtent == 200 &&
                  style != RefreshStyle.Front &&
                  state.isRefresh &&
                  header.layoutResult?.contentExtent == activeExtent) {
                // Expansion rebases overscroll into the header. It must move
                // toward the new edge, rather than recoil toward the body.
                if (previousPixels != null) {
                  expect(
                      scroll.offset, lessThanOrEqualTo(previousPixels + 0.01));
                }
                previousPixels = scroll.offset;
              }
            }
            expect(state.isRefresh, isTrue);
            expect(callbacks, 1);
            expect(
                scroll.offset, closeTo(scroll.position.minScrollExtent, 0.01));
            final header = tester.renderObject<RenderSliverRefresh>(
                find.byType(SliverRefresh, skipOffstage: false));
            expect(header.layoutResult!.effectiveExtent, activeExtent);
            expect(header.geometry!.scrollExtent,
                style == RefreshStyle.Front ? 0 : activeExtent);
            expect(tester.takeException(), isNull);
          });
        }
      }

      testWidgets('a new drag interrupts header settlement $axis $reverse',
          (tester) async {
        final state = RefreshState();
        final scroll = ScrollController();
        addTearDown(state.dispose);
        addTearDown(scroll.dispose);
        await tester.pumpWidget(buildStateRefresher(state,
            scrollDirection: axis,
            reverse: reverse,
            scrollController: scroll,
            header: CustomHeader(
                builder: (_, mode) => SizedBox(
                    width: mode == RefreshStatus.refreshing ? 200 : 40,
                    height: mode == RefreshStatus.refreshing ? 200 : 40))));
        await pullToRefresh(tester, axis, reverse);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(state.isRefresh, isTrue);
        expect(scroll.position.activity, isA<BallisticScrollActivity>());
        final drag = await tester.startGesture(const Offset(400, 300));
        await drag.moveBy(pullDelta(axis, reverse, -100));
        await tester.pump(const Duration(milliseconds: 300));
        final offset = scroll.offset;
        await drag.up();
        await tester.pumpAndSettle();
        expect(scroll.offset, closeTo(offset, 0.01));
        expect(scroll.offset, greaterThan(0));
        expect(state.isRefresh, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
