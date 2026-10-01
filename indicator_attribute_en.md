# Indicator properties

Configure trigger distances, ballistic behavior and overscroll limits on RefreshConfiguration, and business callbacks on SmartRefresher. See [API](propertys_en.md).

## Common properties and styles

RefreshIndicator defaults: height 60.0 (retained main-axis layout extent during refresh), offset 0.0 (paint offset), completeDuration 500ms (delay in the default finish flow), and refreshStyle Follow. Individual indicators can override these defaults.

| RefreshStyle | Behavior |
|---|---|
| Follow | Moves with content |
| UnFollow | Stops following once fully exposed |
| Behind | Stretches with overscroll behind content |
| Front | Overlays content with special layout and painting |

LoadIndicator defaults: height 60.0, nullable onClick (a callback only), and loadStyle ShowAlways.

| LoadStyle | Layout behavior |
|---|---|
| ShowAlways | Retains layout space |
| HideAlways | Does not retain layout space; can still paint during overscroll |
| ShowWhenLoading | Retains layout space while loading, retracting after the finish animation |

Short-list footer scrollExtent has additional handling; RefreshConfiguration controls following content and hiding. Give custom horizontal content an appropriate width too.

## ClassicHeader / ClassicFooter

Both support status text/icons, spacing (15.0), textStyle and iconPos (left/right/top/bottom). outerBuilder can add a background, padding or change content size; the wrapper then determines content layout.

ClassicHeader defaults to height 60.0 and completeDuration 600ms. ClassicFooter defaults to height 60.0 and completeDuration 300ms; endLoading uses that delay, most visibly when ShowWhenLoading retracts. The noMore icon defaults to empty. Loading icons use CupertinoActivityIndicator or CircularProgressIndicator according to platform.

## WaterDropHeader

Uses UnFollow with fixed height 60.0 and default completeDuration 600ms. waterDropColor controls the drop, idleIcon controls its drag icon, and refresh/complete/failed replace status content.

## MaterialClassicHeader / WaterDropMaterialHeader

Both use Front. MaterialClassicHeader defaults to height 80.0 and distance 50.0; WaterDropMaterialHeader has fixed height 80.0 and default distance 60.0. distance controls position while refreshing; offset controls paint offset. Both expose color, backgroundColor, semanticsLabel and semanticsValue. Their finish flow uses a scale animation rather than the base completion delay.

## Bezier, two level and custom indicators

BezierHeader uses UnFollow and defaults rectHeight to 70. Configure color, child overflow, prepare/finish animations and reset callbacks. BezierCircleHeader composes it with Progress/Raidal circle animation and None/RectSpread/ScaleToCenter dismissal.

TwoLevelHeader composes ClassicHeader, defaulting height to 80.0 and completeDuration to 600ms. displayAlignment.fromBottom uses Follow; fromTop/fromCenter use Behind. twoLevelWidget appears in two-level states; decoration supplies the ordinary drag background.

See [custom indicators](custom_indicator_en.md) for CustomHeader/CustomFooter and LinkHeader/LinkFooter lifecycle APIs.
