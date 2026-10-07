import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:pull_to_refresh/src/internals/slivers.dart';

import 'refresh_state_widget_test.dart' show buildStateRefresher;

void main() {
  testWidgets('loading without movement preserves offset with taller content',
      (tester) async {
    final state = RefreshState();
    final controller = RefreshController();
    addTearDown(state.dispose);
    addTearDown(controller.dispose);
    var callbacks = 0;
    await tester.pumpWidget(buildStateRefresher(state,
        controller: controller,
        onLoading: () => callbacks++,
        footer: CustomFooter(
            builder: (_, mode) =>
                SizedBox(height: mode == LoadStatus.loading ? 100 : 20))));
    controller.position!.jumpTo(400);
    await tester.pump();
    await controller.requestLoading(needMove: false, needCallback: false);
    await tester.pumpAndSettle();
    expect(controller.position!.pixels, 400);
    expect(state.isLoading, isTrue);
    expect(callbacks, 0);
  });

  testWidgets('a mode hook can cancel loading before final positioning',
      (tester) async {
    final state = RefreshState();
    final controller = RefreshController();
    addTearDown(state.dispose);
    addTearDown(controller.dispose);
    var callbacks = 0;
    await tester.pumpWidget(buildStateRefresher(state,
        controller: controller,
        onLoading: () => callbacks++,
        footer: CustomFooter(
            onModeChange: (mode) {
              if (mode == LoadStatus.loading) state.loadComplete();
            },
            builder: (_, mode) =>
                SizedBox(height: mode == LoadStatus.loading ? 100 : 20))));
    final request = controller.requestLoading();
    await tester.pumpAndSettle();
    await request;
    expect(state.footerStatus, LoadStatus.idle);
    expect(callbacks, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading callback completion does not reposition added items',
      (tester) async {
    final state = RefreshState();
    final controller = RefreshController();
    final count = ValueNotifier(20);
    addTearDown(state.dispose);
    addTearDown(controller.dispose);
    addTearDown(count.dispose);
    var callbackOffset = 0.0;
    await tester.pumpWidget(ValueListenableBuilder<int>(
        valueListenable: count,
        builder: (_, items, __) => buildStateRefresher(state,
                controller: controller, count: items, onLoading: () {
              callbackOffset = controller.position!.pixels;
              count.value += 10;
              state.loadComplete();
            },
                footer: CustomFooter(
                    builder: (_, mode) => SizedBox(
                        height: mode == LoadStatus.loading ? 100 : 20)))));
    final request = controller.requestLoading();
    await tester.pumpAndSettle();
    await request;
    expect(callbackOffset, greaterThan(0));
    expect(controller.position!.pixels, callbackOffset);
    expect(controller.position!.pixels,
        lessThan(controller.position!.maxScrollExtent));
    expect(state.footerStatus, LoadStatus.idle);
    expect(tester.takeException(), isNull);
  });

  testWidgets('controller requests accept a completed zero-sized layout',
      (tester) async {
    final state = RefreshState();
    final controller = RefreshController();
    addTearDown(state.dispose);
    addTearDown(controller.dispose);
    var refreshes = 0;
    var loads = 0;
    await tester.pumpWidget(buildStateRefresher(state,
        controller: controller,
        onRefresh: () => refreshes++,
        onLoading: () => loads++,
        header: CustomHeader(builder: (_, mode) => const SizedBox.shrink()),
        footer: CustomFooter(builder: (_, mode) => const SizedBox.shrink())));
    final refresh = controller.requestRefresh();
    await tester.pumpAndSettle();
    await refresh;
    expect(state.isRefresh, isTrue);
    expect(refreshes, 1);
    state.refreshToIdle();
    await tester.pumpAndSettle();
    final loading = controller.requestLoading();
    await tester.pumpAndSettle();
    await loading;
    expect(state.isLoading, isTrue);
    expect(loads, 1);
  });

  for (final axis in Axis.values) {
    for (final reverse in [false, true]) {
      testWidgets('Front paints at the viewport edge $axis $reverse',
          (tester) async {
        final state =
            RefreshState(initialRefreshStatus: RefreshStatus.refreshing);
        addTearDown(state.dispose);
        const key = ValueKey('front-content');
        await tester.pumpWidget(buildStateRefresher(state,
            scrollDirection: axis,
            reverse: reverse,
            header: CustomHeader(
                refreshStyle: RefreshStyle.Front,
                builder: (_, mode) =>
                    const SizedBox(key: key, width: 80, height: 80))));
        final rect = tester.getRect(find.byKey(key));
        if (axis == Axis.vertical) {
          expect(reverse ? rect.bottom : rect.top, reverse ? 600 : 0);
        } else {
          expect(reverse ? rect.right : rect.left, reverse ? 800 : 0);
        }
        final header = tester.renderObject<RenderSliverRefresh>(
            find.byType(SliverRefresh, skipOffstage: false));
        expect(header.geometry!.scrollExtent, 0);
        expect(header.geometry!.hitTestExtent, 80);
        expect(tester.takeException(), isNull);
      });

      for (final style in [LoadStyle.ShowAlways, LoadStyle.ShowWhenLoading]) {
        for (final idleExtent in [0.0, 20.0]) {
          testWidgets(
              'loading request reveals active extent $axis $reverse $style idle=$idleExtent',
              (tester) async {
            final state = RefreshState();
            final controller = RefreshController();
            addTearDown(state.dispose);
            addTearDown(controller.dispose);
            var callbacks = 0;
            var callbackAtEnd = false;
            await tester.pumpWidget(buildStateRefresher(state,
                controller: controller,
                scrollDirection: axis,
                reverse: reverse, onLoading: () {
              callbacks++;
              callbackAtEnd = controller.position!.pixels ==
                  controller.position!.maxScrollExtent;
            },
                footer: CustomFooter(
                    loadStyle: style,
                    builder: (_, mode) => mode == LoadStatus.loading
                        ? const SizedBox(
                            width: 100,
                            height: 100,
                            child: Center(child: Text('active footer')))
                        : SizedBox(width: idleExtent, height: idleExtent))));
            final request = controller.requestLoading();
            await tester.pumpAndSettle();
            await request;
            expect(state.isLoading, isTrue);
            expect(find.text('active footer').hitTestable(), findsOneWidget);
            expect(callbacks, 1);
            expect(callbackAtEnd, isTrue);
            expect(tester.takeException(), isNull);
          });
        }
      }
      for (final style in [
        RefreshStyle.Follow,
        RefreshStyle.Behind,
        RefreshStyle.UnFollow
      ]) {
        testWidgets('content header anchors $axis $reverse $style',
            (tester) async {
          final state = RefreshState();
          final scroll = ScrollController();
          final size = ValueNotifier<double>(60);
          addTearDown(state.dispose);
          addTearDown(scroll.dispose);
          addTearDown(size.dispose);
          await tester.pumpWidget(buildStateRefresher(state,
              scrollController: scroll,
              scrollDirection: axis,
              reverse: reverse,
              header: CustomHeader(
                  refreshStyle: style,
                  builder: (_, mode) => ValueListenableBuilder<double>(
                      valueListenable: size,
                      builder: (_, extent, __) =>
                          SizedBox(width: extent, height: extent)))));
          final header = tester.renderObject<RenderSliverRefresh>(
              find.byType(SliverRefresh, skipOffstage: false));
          expect(header.layoutResult!.effectiveExtent, 60);
          expect(header.geometry!.scrollExtent, 0);
          state.startRefresh();
          await tester.pumpAndSettle();
          expect(header.geometry!.scrollExtent, 60);
          scroll.jumpTo(30);
          await tester.pump();
          size.value = 120;
          await tester.pumpAndSettle();
          expect(scroll.offset, 60);
          expect(header.layoutResult!.effectiveExtent, 120);
          scroll.jumpTo(400);
          await tester.pump();
          final anchor = tester.getTopLeft(find.text('Item 4'));
          size.value = 40;
          await tester.pumpAndSettle();
          expect(scroll.offset, 320);
          expect(tester.getTopLeft(find.text('Item 4')), anchor);
          state.refreshToIdle();
          await tester.pumpAndSettle();
          expect(scroll.offset, 280);
          expect(tester.getTopLeft(find.text('Item 4')), anchor);
          expect(tester.takeException(), isNull);
        });
      }
      for (final style in LoadStyle.values) {
        testWidgets('footer natural extent $axis $reverse $style',
            (tester) async {
          final state = RefreshState(initialLoadStatus: LoadStatus.loading);
          final scroll = ScrollController();
          final size = ValueNotifier<double>(24);
          addTearDown(state.dispose);
          addTearDown(scroll.dispose);
          addTearDown(size.dispose);
          await tester.pumpWidget(buildStateRefresher(state,
              scrollController: scroll,
              scrollDirection: axis,
              reverse: reverse,
              footer: CustomFooter(
                  loadStyle: style,
                  builder: (_, mode) => ValueListenableBuilder<double>(
                      valueListenable: size,
                      builder: (_, extent, __) =>
                          SizedBox(width: extent, height: extent)))));
          final footer = tester.renderObject<RenderSliverLoading>(
              find.byType(SliverLoading, skipOffstage: false));
          expect(footer.layoutResult!.effectiveExtent, 24);
          expect(footer.geometry!.scrollExtent,
              style == LoadStyle.HideAlways ? 0 : 24);
          scroll.jumpTo(400);
          await tester.pump();
          final anchor = tester.getTopLeft(find.text('Item 4'));
          size.value = 100;
          await tester.pumpAndSettle();
          expect(footer.layoutResult!.effectiveExtent, 100);
          expect(footer.geometry!.scrollExtent,
              style == LoadStyle.HideAlways ? 0 : 100);
          expect(scroll.offset, 400);
          expect(tester.getTopLeft(find.text('Item 4')), anchor);
          expect(state.isLoading, isTrue);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('zero idle header can trigger under finite default budget',
      (tester) async {
    final state = RefreshState();
    addTearDown(state.dispose);
    var callbacks = 0;
    await tester.pumpWidget(RefreshConfiguration(
        maxOverScrollExtent: 60,
        child: buildStateRefresher(state,
            onRefresh: () => callbacks++,
            header: CustomHeader(
                builder: (_, mode) => mode == RefreshStatus.refreshing
                    ? const SizedBox(height: 72)
                    : const SizedBox.shrink()))));
    final header = tester.renderObject<RenderSliverRefresh>(
        find.byType(SliverRefresh, skipOffstage: false));
    expect(header.layoutResult!.effectiveExtent, 0);
    await tester.drag(find.byType(Viewport), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(state.isRefresh, isTrue);
    expect(callbacks, 1);
    expect(header.geometry!.scrollExtent, 72);
  });

  testWidgets(
      'hidden footer keeps natural extent and removes hits and semantics',
      (tester) async {
    final state = RefreshState();
    addTearDown(state.dispose);
    var taps = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(RefreshConfiguration(
        hideFooterWhenNotFull: true,
        child: buildStateRefresher(state,
            count: 1,
            hideFooterWhenNotFull: true,
            footer: CustomFooter(
                onClick: () => taps++,
                builder: (_, mode) => const SizedBox(
                    height: 88, child: Text('hidden footer'))))));
    final footer = tester.renderObject<RenderSliverLoading>(
        find.byType(SliverLoading, skipOffstage: false));
    expect(footer.layoutResult!.effectiveExtent, 88);
    expect(footer.layoutResult!.hidden, isTrue);
    expect(footer.geometry!.scrollExtent, 0);
    expect(find.text('hidden footer').hitTestable(), findsNothing);
    expect(find.bySemanticsLabel('hidden footer'), findsNothing);
    expect(taps, 0);
    state.loadNoData();
    await tester.pumpAndSettle();
    expect(footer.layoutResult!.hidden, isFalse);
    expect(find.text('hidden footer').hitTestable(), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('explicit zero and content size have distinct meanings',
      (tester) async {
    final state = RefreshState(initialRefreshStatus: RefreshStatus.refreshing);
    addTearDown(state.dispose);
    Future<void> build(double? configured) async {
      await tester.pumpWidget(buildStateRefresher(state,
          header: CustomHeader(
              height: configured,
              builder: (_, mode) => const SizedBox(height: 84))));
      await tester.pump();
    }

    await build(0);
    final header = tester.renderObject<RenderSliverRefresh>(
        find.byType(SliverRefresh, skipOffstage: false));
    expect(header.layoutResult!.contentExtent, 84);
    expect(header.layoutResult!.effectiveExtent, 0);
    expect(header.geometry!.scrollExtent, 0);
    await build(null);
    expect(header.layoutResult!.effectiveExtent, 84);
    expect(header.geometry!.scrollExtent, 84);
    await build(60);
    expect(header.layoutResult!.effectiveExtent, 60);
    expect(header.geometry!.scrollExtent, 60);
  });

  testWidgets('Front is visible with zero body occupation', (tester) async {
    final state = RefreshState(initialRefreshStatus: RefreshStatus.refreshing);
    addTearDown(state.dispose);
    await tester.pumpWidget(buildStateRefresher(state,
        header: CustomHeader(
            refreshStyle: RefreshStyle.Front,
            builder: (_, mode) =>
                const SizedBox(height: 80, child: Text('front header')))));
    final header = tester.renderObject<RenderSliverRefresh>(
        find.byType(SliverRefresh, skipOffstage: false));
    expect(header.layoutResult!.occupiedExtent, 0);
    expect(header.geometry!.scrollExtent, 0);
    expect(header.geometry!.paintExtent, 80);
    expect(find.text('front header').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(find.text('Item 0')).dy, 0);
  });

  testWidgets('switching Front and Follow preserves the body anchor',
      (tester) async {
    final state = RefreshState(initialRefreshStatus: RefreshStatus.refreshing);
    final scroll = ScrollController();
    addTearDown(state.dispose);
    addTearDown(scroll.dispose);
    Future<void> build(RefreshStyle style) async {
      await tester.pumpWidget(buildStateRefresher(state,
          scrollController: scroll,
          header: CustomHeader(
              refreshStyle: style,
              builder: (_, mode) => const SizedBox(height: 80))));
      await tester.pumpAndSettle();
    }

    await build(RefreshStyle.Follow);
    scroll.jumpTo(400);
    await tester.pump();
    final anchor = tester.getTopLeft(find.text('Item 4'));
    await build(RefreshStyle.Front);
    expect(scroll.offset, 320);
    expect(tester.getTopLeft(find.text('Item 4')), anchor);
    await build(RefreshStyle.Follow);
    expect(scroll.offset, 400);
    expect(tester.getTopLeft(find.text('Item 4')), anchor);
  });

  testWidgets('padding and text scale determine the actual content extent',
      (tester) async {
    final state = RefreshState(initialRefreshStatus: RefreshStatus.refreshing);
    addTearDown(state.dispose);
    Future<void> build(double scale) async {
      await tester.pumpWidget(MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: buildStateRefresher(state,
              header: CustomHeader(
                  builder: (_, mode) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('refresh content',
                          style: TextStyle(fontSize: 20)))))));
      await tester.pumpAndSettle();
    }

    await build(1);
    final header =
        tester.renderObject<RenderSliverRefresh>(find.byType(SliverRefresh));
    final first = header.layoutResult!.effectiveExtent;
    expect(first, greaterThan(24));
    await build(2);
    expect(header.layoutResult!.effectiveExtent, greaterThan(first));
    expect(header.geometry!.scrollExtent, header.layoutResult!.contentExtent);
  });
}
