import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

typedef PerformLayoutCallback = Function();

class ViewportWithPerformLayoutCallback extends Viewport {
  ViewportWithPerformLayoutCallback({
    Key? key,
    required ViewportOffset offset,
    required this.callback,
    double? cacheExtent,
    AxisDirection axisDirection = AxisDirection.down,
    double anchor = 1.0,
    List<Widget> slivers = const [],
  }) : super(
          key: key,
          offset: offset,
          cacheExtent: cacheExtent,
          axisDirection: axisDirection,
          anchor: anchor,
          slivers: slivers,
        );

  final PerformLayoutCallback callback;

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return RenderViewportPerformLayoutCallback(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      clipBehavior: clipBehavior,
      callback: callback,
    );
  }
}

class RenderViewportPerformLayoutCallback extends RenderViewport {
  RenderViewportPerformLayoutCallback({
    AxisDirection axisDirection = AxisDirection.down,
    required this.callback,
    required AxisDirection crossAxisDirection,
    required ViewportOffset offset,
    double anchor = 0.0,
    List<RenderSliver>? children,
    RenderSliver? center,
    double? cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
    Clip clipBehavior = Clip.hardEdge,
  }) : super(
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          offset: offset,
          anchor: anchor,
          children: children,
          center: center,
          cacheExtent: cacheExtent,
          cacheExtentStyle: cacheExtentStyle,
          clipBehavior: clipBehavior,
        );

  final PerformLayoutCallback callback;

  @override
  void performLayout() {
    super.performLayout();
    callback();
  }
}
