/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time:  2019-08-29 09:41
 */

import 'package:flutter/material.dart' hide RefreshIndicator;
import 'classic_indicator.dart';
import '../smart_refresher.dart';

enum TwoLevelDisplayAlignment { fromTop, fromCenter, fromBottom }

/// this header help you implements twoLevel function easyily,
/// the behaviour just like TaoBao,XieCheng(携程) App TwoLevel
///
/// just a example
///
/// ```dart
///
///TwoLevelHeader(
///  textStyle: TextStyle(color: Colors.white),
///  displayAlignment: TwoLevelDisplayAlignment.fromTop,
///  decoration: BoxDecoration(
///  image: DecorationImage(
///  image: AssetImage("images/secondfloor.jpg"),
///  fit: BoxFit.cover,
///  // 很重要的属性,这会影响你打开二楼和关闭二楼的动画效果
///  alignment: Alignment.topCenter),
///),
///twoLevelWidget: Container(
///   decoration: BoxDecoration(
///   image: DecorationImage(
///   image: AssetImage("images/secondfloor.jpg"),
//    很重要的属性,这会影响你打开二楼和关闭二楼的动画效果,关联到TwoLevelHeader,如果背景一致的情况,请设置相同
///   alignment: Alignment.topCenter,
///   fit: BoxFit.cover),
///   ),
///   Container(
///     height: 60.0,
///     child: GestureDetector(
///     child: Icon(
///       Icons.arrow_back_ios,
///     color: Colors.white,
///    ),
///   onTap: () {
///     SmartRefresher.of(context).controller.twoLevelComplete();
///   },
///   ),
///   alignment: Alignment.bottomLeft,
///),
///),
///);
///
/// ```
class TwoLevelHeader extends ClassicHeader {
  final BoxDecoration? decoration;
  final Widget? twoLevelWidget;
  final TwoLevelDisplayAlignment displayAlignment;

  const TwoLevelHeader({
    Key? key,
    double height = 80.0,
    this.decoration,
    this.twoLevelWidget,
    this.displayAlignment = TwoLevelDisplayAlignment.fromBottom,
    Duration completeDuration = const Duration(milliseconds: 600),
    TextStyle textStyle = const TextStyle(color: Color(0xff555555)),
    String? releaseText,
    refreshingText,
    canTwoLevelText,
    completeText,
    failedText,
    idleText,
    Widget? canTwoLevelIcon,
    refreshingIcon,
    Widget? failedIcon = const Icon(Icons.error, color: Colors.grey),
    Widget? completeIcon = const Icon(Icons.done, color: Colors.grey),
    Widget? idleIcon = const Icon(Icons.arrow_downward, color: Colors.grey),
    Widget? releaseIcon = const Icon(Icons.refresh, color: Colors.grey),
    IconPosition iconPos = IconPosition.left,
    double spacing = 15.0,
  }) : super(
          key: key,
          height: height,
          completeDuration: completeDuration,
          refreshStyle: displayAlignment == TwoLevelDisplayAlignment.fromBottom
              ? RefreshStyle.Follow
              : RefreshStyle.Behind,
          textStyle: textStyle,
          releaseText: releaseText,
          refreshingText: refreshingText,
          canTwoLevelText: canTwoLevelText,
          completeText: completeText,
          failedText: failedText,
          idleText: idleText,
          canTwoLevelIcon: canTwoLevelIcon,
          refreshingIcon: refreshingIcon,
          failedIcon: failedIcon,
          completeIcon: completeIcon,
          idleIcon: idleIcon,
          releaseIcon: releaseIcon,
          iconPos: iconPos,
          spacing: spacing,
        );

  @override
  Widget wrapContent(BuildContext context, Widget child, RefreshStatus? mode) {
    final isTwoLevel = mode == RefreshStatus.twoLevelClosing ||
        mode == RefreshStatus.twoLeveling ||
        mode == RefreshStatus.twoLevelOpening;
    return Container(
      height:
          isTwoLevel ? SmartRefresher.ofState(context)!.viewportExtent : height,
      decoration: isTwoLevel
          ? null
          : decoration ?? const BoxDecoration(color: Colors.redAccent),
      alignment: isTwoLevel
          ? null
          : displayAlignment == TwoLevelDisplayAlignment.fromTop
              ? Alignment.topCenter
              : displayAlignment == TwoLevelDisplayAlignment.fromCenter
                  ? Alignment.center
                  : Alignment.bottomCenter,
      child: isTwoLevel
          ? twoLevelWidget
          : Padding(padding: const EdgeInsets.only(bottom: 15), child: child),
    );
  }
}
