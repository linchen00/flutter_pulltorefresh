import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/src/refresh_state.dart';

void main() {
  test('state updates and listeners work without a widget or a frame', () {
    final state = RefreshState();
    addTearDown(state.dispose);
    final headers = <RefreshStatus>[];
    final footers = <LoadStatus>[];
    state.headerMode!.addListener(() => headers.add(state.headerStatus!));
    state.footerMode!.addListener(() => footers.add(state.footerStatus!));

    state.startRefresh();
    state.startRefresh();
    expect(state.isRefresh, isTrue);
    state.refreshCompleted();
    state.refreshFailed();
    state.refreshToIdle();
    state.startLoading();
    expect(state.isLoading, isTrue);
    state.loadComplete();
    expect(state.footerStatus, LoadStatus.idle);
    state.loadFailed();
    expect(state.footerStatus, LoadStatus.failed);
    state.loadNoData();
    expect(state.footerStatus, LoadStatus.noMore);
    state.resetNoData();
    expect(headers, [
      RefreshStatus.refreshing,
      RefreshStatus.completed,
      RefreshStatus.failed,
      RefreshStatus.idle
    ]);
    expect(footers, [
      LoadStatus.loading,
      LoadStatus.idle,
      LoadStatus.failed,
      LoadStatus.noMore,
      LoadStatus.idle
    ]);
  });

  test('state fields retain existing declarations and assignment behavior', () {
    final state = RefreshState();
    final original = state.headerMode!;
    final replacement = RefreshNotifier(RefreshStatus.twoLeveling);
    state.headerMode = replacement;
    expect(state.headerMode, same(replacement));
    expect(state.isTwoLevel, isTrue);
    state.headerMode!.value = RefreshStatus.twoLevelClosing;
    expect(state.isTwoLevel, isTrue);
    state.refreshToIdle();
    expect(state.isTwoLevel, isFalse);
    original.dispose();
    state.dispose();
  });

  test('initial values are preserved and footer reset only clears noMore', () {
    final state = RefreshState(
        initialRefreshStatus: RefreshStatus.refreshing,
        initialLoadStatus: LoadStatus.loading);
    addTearDown(state.dispose);
    state.refreshCompleted(resetFooterState: true);
    expect(state.footerStatus, LoadStatus.loading);
    state.loadNoData();
    state.refreshCompleted();
    expect(state.footerStatus, LoadStatus.noMore);
    state.refreshCompleted(resetFooterState: true);
    expect(state.footerStatus, LoadStatus.idle);
  });

  test('state disposal is independent and repeatable', () {
    final state = RefreshState();
    state.dispose();
    state.dispose();
    expect(state.isDisposed, isTrue);
    expect(state.headerMode, isNull);
    expect(state.footerMode, isNull);
    expect(state.startRefresh, throwsStateError);
    expect(state.loadComplete, throwsStateError);
  });
}
