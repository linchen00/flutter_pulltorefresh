// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:pull_to_refresh/src/internals/slivers.dart';

import 'test_indicator.dart';

Widget buildStateRefresher(
  RefreshState state, {
  RefreshController? controller,
  ScrollController? scrollController,
  VoidCallback? onRefresh,
  VoidCallback? onLoading,
  OnTwoLevel? onTwoLevel,
  bool enablePullDown = true,
  bool enablePullUp = true,
  bool enableTwoLevel = false,
  bool initialRefresh = false,
  bool builder = false,
  Axis scrollDirection = Axis.vertical,
  bool reverse = false,
  int count = 20,
  Widget header = const TestHeader(),
  Widget footer = const TestFooter(),
}) {
  final child = builder
      ? SmartRefresher.builder(
          state: state,
          controller: controller,
          onRefresh: onRefresh,
          onLoading: onLoading,
          initialRefresh: initialRefresh,
          enablePullDown: enablePullDown,
          enablePullUp: enablePullUp,
          builder: (context, physics) => CustomScrollView(
            scrollDirection: scrollDirection,
            reverse: reverse,
            controller: scrollController,
            physics: physics,
            slivers: [
              header,
              SliverList(
                  delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          SizedBox(height: 100, child: Text('Item $index')),
                      childCount: count)),
              footer
            ],
          ),
        )
      : SmartRefresher(
          state: state,
          controller: controller,
          initialRefresh: initialRefresh,
          enablePullDown: enablePullDown,
          enablePullUp: enablePullUp,
          enableTwoLevel: enableTwoLevel,
          onRefresh: onRefresh,
          onLoading: onLoading,
          onTwoLevel: onTwoLevel,
          header: header,
          footer: footer,
          child: ListView.builder(
              scrollDirection: scrollDirection,
              reverse: reverse,
              controller: scrollController,
              itemCount: count,
              itemExtent: 100,
              itemBuilder: (context, index) => Text('Item $index')),
        );
  return Directionality(
      textDirection: TextDirection.ltr,
      child: RefreshConfiguration(
          maxOverScrollExtent: enableTwoLevel ? 180 : null, child: child));
}

void main() {
  for (final builder in [false, true]) {
    for (final style in [
      RefreshStyle.Follow,
      RefreshStyle.Behind,
      RefreshStyle.UnFollow,
    ]) {
      for (final direction in Axis.values) {
        for (final reverse in [false, true]) {
          testWidgets(
              'header resizing preserves header and body anchors '
              '(builder=$builder, style=$style, axis=$direction, reverse=$reverse)',
              (tester) async {
            final state = RefreshState();
            final scroll = ScrollController();
            addTearDown(state.dispose);
            addTearDown(scroll.dispose);
            var callbacks = 0;

            Future<void> buildHeader(double extent) async {
              await tester.pumpWidget(buildStateRefresher(state,
                  builder: builder,
                  scrollController: scroll,
                  scrollDirection: direction,
                  reverse: reverse,
                  onRefresh: () => callbacks++,
                  onLoading: () => callbacks++,
                  header: CustomHeader(
                      height: extent,
                      refreshStyle: style,
                      builder: (_, mode) => SizedBox(
                          width: extent,
                          height: extent,
                          child: Text('header $mode')))));
              await tester.pumpAndSettle();
            }

            void expectVisibleHeader() {
              final header =
                  tester.renderObject<RenderSliver>(find.byType(SliverRefresh));
              expect(header.geometry!.paintExtent, greaterThan(0));
              expect(state.isRefresh, isTrue);
              expect(callbacks, 0);
            }

            await buildHeader(60);
            state.startRefresh();
            await tester.pumpAndSettle();
            expect(scroll.offset, 0);
            expectVisibleHeader();
            scroll.jumpTo(30);
            await tester.pump();
            await buildHeader(120);
            expect(scroll.offset, 60);
            expectVisibleHeader();
            await buildHeader(40);
            expect(scroll.offset, 20);
            expectVisibleHeader();
            state.refreshToIdle();
            await tester.pumpAndSettle();
            expect(scroll.offset, 0);

            state.startRefresh();
            await tester.pumpAndSettle();
            scroll.jumpTo(400);
            await tester.pump();
            final itemPosition = tester.getTopLeft(find.text('Item 4'));
            await buildHeader(120);
            expect(scroll.offset, 480);
            expect(tester.getTopLeft(find.text('Item 4')), itemPosition);
            state.refreshToIdle();
            await tester.pumpAndSettle();
            expect(scroll.offset, 360);
            expect(tester.getTopLeft(find.text('Item 4')), itemPosition);
            expect(callbacks, 0);
          });
        }
      }
    }

    testWidgets(
        'startRefresh renders a visible header at the top (builder=$builder)',
        (tester) async {
      final state = RefreshState();
      addTearDown(state.dispose);
      var callbacks = 0;
      await tester.pumpWidget(buildStateRefresher(state,
          builder: builder, onRefresh: () => callbacks++));
      state.startRefresh();
      await tester.pumpAndSettle();
      expect(find.text('refreshing').hitTestable(), findsOneWidget);
      expect(callbacks, 0);
      state.refreshCompleted();
      await tester.pump();
      expect(find.text('completed').hitTestable(), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      expect(state.headerStatus, RefreshStatus.idle);
      expect(tester.getTopLeft(find.text('Item 0')).dy, 0);
      expect(callbacks, 0);
      state.headerMode!.value = RefreshStatus.refreshing;
      await tester.pumpAndSettle();
      expect(find.text('refreshing').hitTestable(), findsOneWidget);
      state.refreshFailed();
      await tester.pump();
      expect(find.text('failed').hitTestable(), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      expect(state.headerStatus, RefreshStatus.idle);
      expect(tester.getTopLeft(find.text('Item 0')).dy, 0);
      expect(callbacks, 0);
    });

    testWidgets(
        'every assigned status updates indicator content without scrolling (builder=$builder)',
        (tester) async {
      final state = RefreshState();
      final scroll = ScrollController();
      addTearDown(state.dispose);
      addTearDown(scroll.dispose);
      var callbacks = 0;
      await tester.pumpWidget(buildStateRefresher(state,
          builder: builder,
          scrollController: scroll,
          onRefresh: () => callbacks++,
          onLoading: () => callbacks++,
          header: CustomHeader(builder: (_, mode) => Text('header $mode')),
          footer: CustomFooter(builder: (_, mode) => Text('footer $mode'))));
      scroll.jumpTo(400);
      await tester.pump();
      final itemPosition = tester.getTopLeft(find.text('Item 4'));

      for (final status in RefreshStatus.values) {
        state.headerMode!.value = status;
        await tester.pump();
        expect(
            find.text('header $status', skipOffstage: false), findsOneWidget);
        expect(state.headerStatus, status);
        expect(tester.getTopLeft(find.text('Item 4')), itemPosition);
        expect(callbacks, 0);
      }
      state.refreshToIdle();
      for (final status in LoadStatus.values) {
        state.footerMode!.value = status;
        await tester.pump();
        expect(
            find.text('footer $status', skipOffstage: false), findsOneWidget);
        expect(state.footerStatus, status);
        expect(tester.getTopLeft(find.text('Item 4')), itemPosition);
        expect(callbacks, 0);
      }
      state.loadComplete();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'state methods update content and completion returns to idle (builder=$builder)',
        (tester) async {
      final state = RefreshState();
      final scroll = ScrollController();
      addTearDown(state.dispose);
      addTearDown(scroll.dispose);
      var callbacks = 0;
      const resultDuration = Duration(milliseconds: 600);
      await tester.pumpWidget(buildStateRefresher(state,
          builder: builder,
          scrollController: scroll,
          onRefresh: () => callbacks++,
          onLoading: () => callbacks++,
          header: CustomHeader(
              completeDuration: resultDuration,
              builder: (_, mode) => Text('header $mode')),
          footer: CustomFooter(builder: (_, mode) => Text('footer $mode'))));
      scroll.jumpTo(400);
      await tester.pump();
      final itemPosition = tester.getTopLeft(find.text('Item 4'));

      Future<void> checkHeader(RefreshStatus status) async {
        await tester.pump();
        expect(
            find.text('header $status', skipOffstage: false), findsOneWidget);
        expect(state.headerStatus, status);
        expect(tester.getTopLeft(find.text('Item 4')), itemPosition);
        expect(callbacks, 0);
      }

      Future<void> checkFooter(LoadStatus status) async {
        await tester.pump();
        expect(
            find.text('footer $status', skipOffstage: false), findsOneWidget);
        expect(state.footerStatus, status);
        expect(tester.getTopLeft(find.text('Item 4')).dy,
            closeTo(itemPosition.dy, 0.001));
        expect(callbacks, 0);
      }

      for (final failed in [false, true]) {
        state.startRefresh();
        await checkHeader(RefreshStatus.refreshing);
        if (failed) {
          state.refreshFailed();
        } else {
          state.loadNoData();
          state.refreshCompleted(resetFooterState: true);
          await checkFooter(LoadStatus.idle);
        }
        await checkHeader(
            failed ? RefreshStatus.failed : RefreshStatus.completed);
        await tester.pump(const Duration(milliseconds: 599));
        expect(state.headerStatus,
            failed ? RefreshStatus.failed : RefreshStatus.completed);
        await tester.pump(const Duration(milliseconds: 1));
        await checkHeader(RefreshStatus.idle);
      }
      state.startRefresh();
      state.refreshToIdle();
      await checkHeader(RefreshStatus.idle);
      state.startLoading();
      await checkFooter(LoadStatus.loading);
      state.loadFailed();
      await checkFooter(LoadStatus.failed);
      state.loadNoData();
      await checkFooter(LoadStatus.noMore);
      state.resetNoData();
      await checkFooter(LoadStatus.idle);
      state.startLoading();
      state.loadComplete();
      await checkFooter(LoadStatus.idle);
      await tester.pumpAndSettle();
    });

    testWidgets(
        'mount remount and replacement render every existing status (builder=$builder)',
        (tester) async {
      var callbacks = 0;
      final states = <RefreshState>[];
      addTearDown(() {
        for (final state in states) {
          state.dispose();
        }
      });
      for (final header in RefreshStatus.values) {
        for (final footer in LoadStatus.values) {
          final state = RefreshState(
              initialRefreshStatus: header, initialLoadStatus: footer);
          states.add(state);
          for (var mount = 0; mount < 2; mount++) {
            await tester.pumpWidget(buildStateRefresher(state,
                builder: builder,
                onRefresh: () => callbacks++,
                onLoading: () => callbacks++,
                header:
                    CustomHeader(builder: (_, mode) => Text('header $mode')),
                footer:
                    CustomFooter(builder: (_, mode) => Text('footer $mode'))));
            await tester.pump();
            expect(find.text('header $header', skipOffstage: false),
                findsOneWidget);
            expect(find.text('footer $footer', skipOffstage: false),
                findsOneWidget);
            expect(state.headerStatus, header);
            expect(state.footerStatus, footer);
            expect(callbacks, 0);
            if (header == RefreshStatus.refreshing) {
              expect(find.text('header $header').hitTestable(), findsOneWidget);
            }
            if (mount == 0) await tester.pumpWidget(const SizedBox());
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('state changes update indicator hooks without business callbacks',
      (tester) async {
    final state = RefreshState();
    addTearDown(state.dispose);
    var callbacks = 0;
    final headerModes = <RefreshStatus?>[];
    final footerModes = <LoadStatus?>[];
    var headerReady = 0;
    var footerReady = 0;
    await tester.pumpWidget(buildStateRefresher(
      state,
      onRefresh: () => callbacks++,
      onLoading: () => callbacks++,
      header: CustomHeader(
          builder: (_, mode) => Text('header $mode'),
          readyToRefresh: () async {
            headerReady++;
          },
          onModeChange: headerModes.add),
      footer: CustomFooter(
          builder: (_, mode) => Text('footer $mode'),
          readyLoading: () async {
            footerReady++;
          },
          onModeChange: (mode) => footerModes.add(mode)),
    ));
    state.startRefresh();
    state.startLoading();
    await tester.pumpAndSettle();
    expect(callbacks, 0);
    expect(headerReady, 1);
    expect(footerReady, 1);
    expect(headerModes, contains(RefreshStatus.refreshing));
    expect(footerModes, contains(LoadStatus.loading));
    expect(find.text('header RefreshStatus.refreshing', skipOffstage: false),
        findsOneWidget);
    expect(find.text('footer LoadStatus.loading', skipOffstage: false),
        findsOneWidget);
    state.headerMode!.value = RefreshStatus.idle;
    state.footerMode!.value = LoadStatus.idle;
    await tester.pumpAndSettle();
    state.headerMode!.value = RefreshStatus.refreshing;
    state.footerMode!.value = LoadStatus.loading;
    await tester.pumpAndSettle();
    expect(callbacks, 0);
  });

  for (final builder in [false, true]) {
    testWidgets(
        'gestures and initial refresh work without a controller (builder=$builder)',
        (tester) async {
      final state = RefreshState();
      final scroll = ScrollController();
      addTearDown(state.dispose);
      addTearDown(scroll.dispose);
      var refreshes = 0;
      var loads = 0;
      await tester.pumpWidget(buildStateRefresher(state,
          builder: builder,
          scrollController: scroll,
          initialRefresh: true,
          onRefresh: () => refreshes++,
          onLoading: () => loads++));
      await tester.pumpAndSettle();
      expect(refreshes, 1);
      state.refreshCompleted();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      await tester.drag(find.byType(Scrollable), const Offset(0, 120));
      await tester.pumpAndSettle();
      expect(refreshes, 2);
      state.refreshCompleted();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      scroll.jumpTo(scroll.position.maxScrollExtent - 30);
      await tester.drag(find.byType(Scrollable), const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(loads, 1);
    });
  }

  for (final needMove in [false, true]) {
    for (final needCallback in [false, true]) {
      testWidgets(
          'controller notifies hooks with needMove=$needMove, needCallback=$needCallback',
          (tester) async {
        final state = RefreshState();
        final controller = RefreshController();
        addTearDown(state.dispose);
        addTearDown(controller.dispose);
        var refreshes = 0;
        var loads = 0;
        final headers = <RefreshStatus?>[];
        final footers = <LoadStatus?>[];
        await tester.pumpWidget(buildStateRefresher(state,
            controller: controller,
            onRefresh: () => refreshes++,
            onLoading: () => loads++,
            header: CustomHeader(
                builder: (_, mode) => Text('$mode'), onModeChange: headers.add),
            footer: CustomFooter(
                builder: (_, mode) => Text('$mode'),
                onModeChange: (mode) => footers.add(mode))));
        final refresh = controller.requestRefresh(
            needMove: needMove, needCallback: needCallback);
        await tester.pumpAndSettle();
        await refresh;
        expect(refreshes, needCallback ? 1 : 0);
        expect(headers, contains(RefreshStatus.refreshing));
        await controller.requestRefresh(needMove: false);
        expect(refreshes, needCallback ? 1 : 0);
        state.refreshCompleted();
        await tester.pumpAndSettle(const Duration(milliseconds: 600));
        final loading = controller.requestLoading(
            needMove: needMove, needCallback: needCallback);
        await tester.pumpAndSettle();
        await loading;
        expect(loads, needCallback ? 1 : 0);
        expect(footers, contains(LoadStatus.loading));
        await controller.requestLoading(needMove: false);
        expect(loads, needCallback ? 1 : 0);
      });
    }
  }

  testWidgets(
      'mount and remount preserve existing state and prepare indicators',
      (tester) async {
    final state = RefreshState(
        initialRefreshStatus: RefreshStatus.refreshing,
        initialLoadStatus: LoadStatus.loading);
    addTearDown(state.dispose);
    var callbacks = 0;
    var preparations = 0;
    final header = CustomHeader(
        builder: (_, mode) => Text('header $mode'),
        readyToRefresh: () async {
          preparations++;
        });
    for (var i = 0; i < 2; i++) {
      await tester.pumpWidget(buildStateRefresher(state,
          header: header,
          onRefresh: () => callbacks++,
          onLoading: () => callbacks++));
      await tester.pumpAndSettle();
      expect(state.isRefresh, isTrue);
      expect(state.isLoading, isTrue);
      expect(callbacks, 0);
      expect(preparations, i + 1);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'replacing controller retains state and detaches the old controller',
      (tester) async {
    final state = RefreshState();
    final first = RefreshController();
    final second = RefreshController();
    addTearDown(state.dispose);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(buildStateRefresher(state, controller: first));
    state.startRefresh();
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildStateRefresher(state, controller: second));
    await tester.pumpAndSettle();
    expect(state.isRefresh, isTrue);
    expect(second.position, isNotNull);
    expect(first.position, isNull);
    await expectLater(first.requestRefresh(), throwsStateError);
    first.dispose();
    state.refreshCompleted();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(state.headerStatus, RefreshStatus.idle);
    await tester.pumpWidget(const SizedBox());
    expect(second.position, isNull);
    state.startLoading();
    expect(state.isLoading, isTrue);
  });

  testWidgets(
      'replacing state rebinds constant indicators and removes old listeners',
      (tester) async {
    final first = RefreshState();
    final second = RefreshState(initialLoadStatus: LoadStatus.noMore);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(buildStateRefresher(first));
    first.startRefresh();
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildStateRefresher(second));
    await tester.pumpAndSettle();
    expect(first.isRefresh, isTrue);
    expect(second.headerStatus, RefreshStatus.idle);
    expect(second.footerStatus, LoadStatus.noMore);
    expect(first.headerMode!.hasListeners, isFalse);
    expect(first.footerMode!.hasListeners, isFalse);
    first.startLoading();
    first.refreshFailed();
    await tester.pumpAndSettle();
    expect(second.headerStatus, RefreshStatus.idle);
    second.startRefresh();
    await tester.pumpAndSettle();
    expect(find.text('refreshing', skipOffstage: false), findsOneWidget);
  });

  for (final replacement in ['state', 'controller', 'unmount', 'dispose']) {
    for (final duringAnimation in [false, true]) {
      testWidgets(
          'pending controller request is invalidated by $replacement (animating=$duringAnimation)',
          (tester) async {
        final state = RefreshState();
        final newState = RefreshState();
        final controller = RefreshController();
        final newController = RefreshController();
        addTearDown(state.dispose);
        addTearDown(newState.dispose);
        addTearDown(controller.dispose);
        addTearDown(newController.dispose);
        var callbacks = 0;
        await tester.pumpWidget(buildStateRefresher(state,
            controller: controller, onRefresh: () => callbacks++));
        if (duringAnimation) {
          controller.position!.jumpTo(400);
          await tester.pump();
        }
        final request = controller.requestRefresh();
        if (duringAnimation) {
          await tester.pump(const Duration(milliseconds: 60));
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (replacement == 'dispose') {
          controller.dispose();
          await tester.pump();
        } else if (replacement == 'unmount') {
          await tester.pumpWidget(const SizedBox());
        } else {
          await tester.pumpWidget(buildStateRefresher(
              replacement == 'state' ? newState : state,
              controller:
                  replacement == 'controller' ? newController : controller,
              onRefresh: () => callbacks++));
        }
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pumpAndSettle();
        await request;
        expect(state.headerStatus, RefreshStatus.idle);
        expect(newState.headerStatus, RefreshStatus.idle);
        expect(callbacks, 0);
        if (replacement != 'unmount') {
          final indicator = tester.state<RefreshIndicatorState>(
              find.byType(TestHeader, skipOffstage: false));
          expect(indicator.floating, isFalse);
        }
      });
    }
  }

  testWidgets(
      'old completion animations cannot reset a newly started operation',
      (tester) async {
    final state = RefreshState();
    addTearDown(state.dispose);
    final headerEnd = Completer<void>();
    final footerEnd = Completer<void>();
    await tester.pumpWidget(buildStateRefresher(state,
        header: CustomHeader(
            builder: (_, mode) => Text('$mode'),
            endRefresh: () => headerEnd.future),
        footer: CustomFooter(
            builder: (_, mode) => Text('$mode'),
            endLoading: () => footerEnd.future)));
    state.startRefresh();
    state.startLoading();
    await tester.pump();
    state.refreshCompleted();
    state.loadComplete();
    state.startRefresh();
    state.startLoading();
    headerEnd.complete();
    footerEnd.complete();
    await tester.pumpAndSettle();
    expect(state.isRefresh, isTrue);
    expect(state.isLoading, isTrue);
    final headerState = tester.state<RefreshIndicatorState>(
        find.byType(CustomHeader, skipOffstage: false));
    final footerState = tester.state<LoadIndicatorState>(
        find.byType(CustomFooter, skipOffstage: false));
    expect(headerState.floating, isTrue);
    expect(footerState.floating, isTrue);
  });

  testWidgets(
      'a stale gesture preparation cannot start work after state replacement',
      (tester) async {
    final first = RefreshState();
    final second = RefreshState();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final ready = Completer<void>();
    final header = CustomHeader(
        builder: (_, mode) => Text('$mode'),
        readyToRefresh: () => ready.future);
    var callbacks = 0;
    await tester.pumpWidget(buildStateRefresher(first,
        header: header, onRefresh: () => callbacks++));
    await tester.drag(find.byType(Scrollable), const Offset(0, 120));
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildStateRefresher(second,
        header: header, onRefresh: () => callbacks++));
    ready.complete();
    await tester.pumpAndSettle();
    expect(callbacks, 0);
    expect(second.headerStatus, RefreshStatus.idle);
  });

  testWidgets(
      'synchronous load completion allows only one callback per interaction',
      (tester) async {
    final state = RefreshState();
    final scroll = ScrollController();
    addTearDown(state.dispose);
    addTearDown(scroll.dispose);
    var calls = 0;
    await tester.pumpWidget(
        buildStateRefresher(state, scrollController: scroll, onLoading: () {
      calls++;
      state.loadComplete();
    }));
    scroll.jumpTo(scroll.position.maxScrollExtent - 30);
    await tester.drag(find.byType(Scrollable), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(state.footerStatus, LoadStatus.idle);
    await tester.drag(find.byType(Scrollable), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets(
      'short content does not repeatedly load when completion adds no data',
      (tester) async {
    final state = RefreshState();
    addTearDown(state.dispose);
    var calls = 0;
    await tester.pumpWidget(buildStateRefresher(state, count: 1, onLoading: () {
      calls++;
      state.loadComplete();
    }));
    await tester.fling(find.byType(Scrollable), const Offset(0, -1000), 3000);
    await tester.pumpAndSettle();
    expect(calls, lessThanOrEqualTo(1));
    expect(state.footerStatus, LoadStatus.idle);
  });

  testWidgets('two-level gestures can open and close without a controller',
      (tester) async {
    final state = RefreshState();
    final scroll = ScrollController();
    addTearDown(state.dispose);
    addTearDown(scroll.dispose);
    final callbacks = <bool>[];
    await tester.pumpWidget(buildStateRefresher(state,
        scrollController: scroll,
        enablePullDown: false,
        enableTwoLevel: true,
        onTwoLevel: callbacks.add,
        header: TwoLevelHeader(
            twoLevelWidget: Container(color: const Color(0xffeeeeee)))));
    await tester.drag(find.byType(Scrollable), const Offset(0, 160),
        touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(state.headerStatus, RefreshStatus.twoLeveling);
    expect(callbacks, [true]);
    await tester.fling(find.byType(Scrollable), const Offset(0, -300), 3000);
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    expect(state.headerStatus, RefreshStatus.idle);
    expect(callbacks, [true, false]);
  });

  testWidgets(
      'unbound, disabled and disposed controller requests report errors',
      (tester) async {
    final state = RefreshState();
    final controller = RefreshController();
    addTearDown(state.dispose);
    addTearDown(controller.dispose);
    await expectLater(controller.requestRefresh(), throwsStateError);
    await tester.pumpWidget(buildStateRefresher(state,
        controller: controller, enablePullDown: false, enablePullUp: false));
    await expectLater(controller.requestRefresh(), throwsStateError);
    await expectLater(controller.requestLoading(), throwsStateError);
    await expectLater(controller.requestTwoLevel(), throwsStateError);
    controller.dispose();
    controller.dispose();
    await expectLater(controller.twoLevelComplete(), throwsStateError);
    state.startRefresh();
    expect(state.isRefresh, isTrue);
  });
  testWidgets(
      'state updates during a controller request cancel its business callback',
      (tester) async {
    final state = RefreshState();
    final controller = RefreshController();
    addTearDown(state.dispose);
    addTearDown(controller.dispose);
    var callbacks = 0;
    await tester.pumpWidget(buildStateRefresher(state,
        controller: controller, onLoading: () => callbacks++));
    final request = controller.requestLoading();
    state.startLoading();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    await request;
    expect(callbacks, 0);
    expect(state.isLoading, isTrue);
  });

  testWidgets('two-level animation cannot overwrite a newer state',
      (tester) async {
    final state = RefreshState();
    final controller = RefreshController();
    addTearDown(state.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildStateRefresher(state,
        controller: controller, enableTwoLevel: true));
    final request = controller.requestTwoLevel();
    await tester.pump();
    state.refreshToIdle();
    state.startRefresh();
    await tester.pumpAndSettle();
    await request;
    expect(state.isRefresh, isTrue);
  });

  testWidgets('a state cannot bind two components simultaneously',
      (tester) async {
    final state = RefreshState();
    addTearDown(state.dispose);
    await tester.pumpWidget(Column(children: [
      Expanded(child: buildStateRefresher(state)),
      Expanded(child: buildStateRefresher(state)),
    ]));
    expect(tester.takeException(), isA<StateError>());
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(buildStateRefresher(state));
    state.startRefresh();
    await tester.pumpAndSettle();
    expect(state.isRefresh, isTrue);
  });
  testWidgets('disposing a pending controller restores gesture refresh',
      (tester) async {
    final state = RefreshState();
    final controller = RefreshController();
    addTearDown(state.dispose);
    addTearDown(controller.dispose);
    var callbacks = 0;
    await tester.pumpWidget(buildStateRefresher(state,
        controller: controller, onRefresh: () => callbacks++));
    final pending = controller.requestRefresh();
    controller.dispose();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    await pending;
    await tester.drag(find.byType(Scrollable), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(state.isRefresh, isTrue);
    expect(callbacks, 1);
  });
  testWidgets('two-level requests require a mounted header in builder mode',
      (tester) async {
    final state = RefreshState();
    final controller = RefreshController();
    addTearDown(state.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SmartRefresher.builder(
            state: state,
            controller: controller,
            enableTwoLevel: true,
            enablePullUp: true,
            builder: (_, physics) =>
                CustomScrollView(physics: physics, slivers: const [
                  SliverToBoxAdapter(child: SizedBox(height: 1000)),
                  TestFooter(),
                ]))));
    await expectLater(controller.requestTwoLevel(), throwsStateError);
    await expectLater(controller.twoLevelComplete(), throwsStateError);
  });
}
