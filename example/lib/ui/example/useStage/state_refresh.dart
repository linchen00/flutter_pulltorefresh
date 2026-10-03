import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// Drive indicators with RefreshState alone, keeping each operation pending
/// until the user chooses its result so the UI can be inspected.
class StateRefreshExample extends StatefulWidget {
  const StateRefreshExample({super.key});

  @override
  State<StateRefreshExample> createState() => _StateRefreshExampleState();
}

class _StateRefreshExampleState extends State<StateRefreshExample> {
  final RefreshState _refreshState = RefreshState();
  late final Listenable _statusChanges = Listenable.merge([
    _refreshState.headerMode!,
    _refreshState.footerMode!,
  ]);
  int _refreshCallbacks = 0;
  int _loadingCallbacks = 0;
  int _revision = 0;
  int _itemCount = 20;

  void _completeRefresh() {
    setState(() {
      _revision++;
      _itemCount = 20;
    });
    _refreshState.refreshCompleted(resetFooterState: true);
  }

  void _completeLoading() {
    setState(() => _itemCount += 10);
    _refreshState.loadComplete();
  }

  @override
  void dispose() {
    _refreshState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('State 驱动刷新')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedBuilder(
                animation: _statusChanges,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('仅使用 RefreshState，不传 RefreshController。\n'
                        '下拉刷新、上拉加载或点击开始，再手动选择结果。\n'
                        'State 按钮不触发业务回调，也不自动滚动；'
                        '查看头部/底部时请滚动到对应位置。'),
                    const SizedBox(height: 8),
                    Text('headerStatus: ${_refreshState.headerStatus!.name}',
                        key: const ValueKey('header-status')),
                    Text('footerStatus: ${_refreshState.footerStatus!.name}',
                        key: const ValueKey('footer-status')),
                    Text('isRefresh: ${_refreshState.isRefresh}  '
                        'isLoading: ${_refreshState.isLoading}'),
                    Text('onRefresh: $_refreshCallbacks 次  '
                        'onLoading: $_loadingCallbacks 次'),
                    Text('数据版本: $_revision  条目数: $_itemCount'),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _refreshState.isRefresh
                              ? null
                              : _refreshState.startRefresh,
                          child: const Text('开始刷新'),
                        ),
                        TextButton(
                          onPressed:
                              _refreshState.isRefresh ? _completeRefresh : null,
                          child: const Text('刷新成功'),
                        ),
                        TextButton(
                          onPressed: _refreshState.isRefresh
                              ? _refreshState.refreshFailed
                              : null,
                          child: const Text('刷新失败'),
                        ),
                        TextButton(
                          onPressed: _refreshState.refreshToIdle,
                          child: const Text('刷新归位'),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _refreshState.isLoading
                              ? null
                              : _refreshState.startLoading,
                          child: const Text('开始加载'),
                        ),
                        TextButton(
                          onPressed:
                              _refreshState.isLoading ? _completeLoading : null,
                          child: const Text('加载成功'),
                        ),
                        TextButton(
                          onPressed: _refreshState.isLoading
                              ? _refreshState.loadFailed
                              : null,
                          child: const Text('加载失败'),
                        ),
                        TextButton(
                          onPressed: _refreshState.loadNoData,
                          child: const Text('没有更多'),
                        ),
                        TextButton(
                          onPressed: _refreshState.resetNoData,
                          child: const Text('重置无更多'),
                        ),
                      ],
                    ),
                    const Text('刷新成功/失败的提示结束后，header 会自动回到 idle。'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SmartRefresher(
                state: _refreshState,
                enablePullUp: true,
                header: const ClassicHeader(
                  idleText: '下拉刷新 · idle',
                  releaseText: '松开刷新 · canRefresh',
                  refreshingText: '刷新中 · refreshing',
                  completeText: '刷新成功 · completed',
                  failedText: '刷新失败 · failed',
                  completeDuration: Duration(seconds: 2),
                ),
                footer: const ClassicFooter(
                  loadStyle: LoadStyle.ShowAlways,
                  idleText: '上拉加载 · idle',
                  canLoadingText: '松开加载 · canLoading',
                  loadingText: '加载中 · loading',
                  failedText: '加载失败 · failed',
                  noDataText: '没有更多 · noMore',
                ),
                onRefresh: () => setState(() => _refreshCallbacks++),
                onLoading: () => setState(() => _loadingCallbacks++),
                child: ListView.builder(
                  itemCount: _itemCount,
                  itemExtent: 56,
                  itemBuilder: (context, index) => ListTile(
                    title: Text('条目 ${index + 1}'),
                    trailing: Text('版本 $_revision'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
