import 'package:flutter/foundation.dart';

/// header state
enum RefreshStatus {
  /// Initial state, when not being overscrolled into, or after the overscroll
  /// is canceled or after done and the sliver retracted away.
  idle,

  /// Dragged far enough that the onRefresh callback will callback
  canRefresh,

  /// the indicator is refreshing,waiting for the finish callback
  refreshing,

  /// the indicator refresh completed
  completed,

  /// the indicator refresh failed
  failed,

  ///  Dragged far enough that the onTwoLevel callback will callback
  canTwoLevel,

  ///  indicator is opening twoLevel
  twoLevelOpening,

  /// indicator is in twoLevel
  twoLeveling,

  ///  indicator is closing twoLevel
  twoLevelClosing
}

///  footer state
enum LoadStatus {
  /// Initial state, which can be triggered loading more by gesture pull up
  idle,

  canLoading,

  /// indicator is loading more data
  loading,

  /// indicator is no more data to loading,this state doesn't allow to load more whatever
  noMore,

  /// indicator load failed,Initial state, which can be click retry,If you need to pull up trigger load more,you should set enableLoadingWhenFailed = true in RefreshConfiguration
  failed
}

/// Refresh and loading state that can be used without a mounted UI.
/// The caller owns and disposes this object.
class RefreshState {
  RefreshNotifier<RefreshStatus>? headerMode;
  RefreshNotifier<LoadStatus>? footerMode;
  bool _disposed = false;

  RefreshState(
      {RefreshStatus? initialRefreshStatus, LoadStatus? initialLoadStatus}) {
    headerMode = RefreshNotifier(initialRefreshStatus ?? RefreshStatus.idle);
    footerMode = RefreshNotifier(initialLoadStatus ?? LoadStatus.idle);
  }

  bool get isDisposed => _disposed;
  RefreshStatus? get headerStatus => headerMode?.value;
  LoadStatus? get footerStatus => footerMode?.value;
  bool get isRefresh => headerStatus == RefreshStatus.refreshing;
  bool get isLoading => footerStatus == LoadStatus.loading;
  bool get isTwoLevel =>
      headerStatus == RefreshStatus.twoLeveling ||
      headerStatus == RefreshStatus.twoLevelOpening ||
      headerStatus == RefreshStatus.twoLevelClosing;

  void _checkActive() {
    if (_disposed) throw StateError('RefreshState has been disposed.');
  }

  /// Updates the indicator without calling onRefresh or requesting scrolling.
  void startRefresh() {
    _checkActive();
    headerMode?.value = RefreshStatus.refreshing;
  }

  /// Updates the indicator without calling onLoading or requesting scrolling.
  void startLoading() {
    _checkActive();
    footerMode?.value = LoadStatus.loading;
  }

  void refreshCompleted({bool resetFooterState = false}) {
    _checkActive();
    headerMode?.value = RefreshStatus.completed;
    if (resetFooterState) resetNoData();
  }

  void refreshFailed() {
    _checkActive();
    headerMode?.value = RefreshStatus.failed;
  }

  void refreshToIdle() {
    _checkActive();
    headerMode?.value = RefreshStatus.idle;
  }

  void loadComplete() {
    _checkActive();
    footerMode?.value = LoadStatus.idle;
  }

  void loadFailed() {
    _checkActive();
    footerMode?.value = LoadStatus.failed;
  }

  void loadNoData() {
    _checkActive();
    footerMode?.value = LoadStatus.noMore;
  }

  void resetNoData() {
    _checkActive();
    if (footerStatus == LoadStatus.noMore) footerMode?.value = LoadStatus.idle;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    headerMode?.dispose();
    footerMode?.dispose();
    headerMode = null;
    footerMode = null;
  }
}

class RefreshNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  /// Creates a [ChangeNotifier] that wraps this value.
  RefreshNotifier(this._value);
  T _value;

  @override
  T get value => _value;

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  void setValueWithNoNotify(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}
