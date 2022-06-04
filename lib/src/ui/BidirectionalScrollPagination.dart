import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chats/src/core/BidirectionalPagedLoader.dart';
import 'package:flutter_chats/src/models/PageLoadingState.dart';
import 'package:flutter_chats/src/ui/ElementBuilder.dart';
import 'package:flutter_chats/src/ui/StatusBuilder.dart';
import 'package:flutter_chats/src/ui/ViewportWithExtentChangeCallback.dart';

class BidirectionalScrollPagination<ElementType, KeyType>
    extends StatelessWidget {
  BidirectionalScrollPagination.builder({
    required this.itemBuilder,
    required this.pagedLoader,
    required this.firstPageLoadingError,
    required this.bottomPageLoadingError,
    required this.topPageLoadingError,
    required this.firstPageLoadingIndicator,
    required this.bottomPageLoadingIndicator,
    required this.topPageLoadingIndicator,
    required this.emptyWidgetBuilder,
    this.cacheExtent,
    this.itemExtent,
    this.padding,
    this.axisDirection = AxisDirection.up,
    this.scrollPhysics = const AlwaysScrollableScrollPhysics(),
    Key? key,
  }) : super(key: key);

  final ErrorBuilder firstPageLoadingError;
  final ErrorBuilder topPageLoadingError;
  final ErrorBuilder bottomPageLoadingError;
  final WidgetBuilder topPageLoadingIndicator;
  final WidgetBuilder bottomPageLoadingIndicator;
  final WidgetBuilder firstPageLoadingIndicator;
  final WidgetBuilder emptyWidgetBuilder;
  final BidirectionalPagedLoader<ElementType, KeyType> pagedLoader;
  final TypedBuilder<ElementType> itemBuilder;
  final AxisDirection axisDirection;
  final double? cacheExtent;
  final double? itemExtent;
  final EdgeInsets? padding;
  final ScrollPhysics scrollPhysics;
  final ExternalBoundedScrollController controller =
      ExternalBoundedScrollController();

  @override
  Widget build(BuildContext context) => StatusBuilder<double>(
        statusNotifier: pagedLoader.firstPageLoading,
        onSuccess: _build,
        onError: firstPageLoadingError,
        onEmpty: emptyWidgetBuilder,
        onLoading: firstPageLoadingIndicator,
      );

  Widget _build(BuildContext context, double anchor) => Scrollable(
      axisDirection: axisDirection,
      physics: scrollPhysics,
      controller: controller,
      viewportBuilder: (context, offset) {
        return Builder(builder: (context) {
          final state = Scrollable.of(context)!;

          final negativeOffset = ScrollPositionWithSingleContext(
            physics: scrollPhysics,
            context: state,
            initialPixels: -offset.pixels,
          );

          offset.addListener(() {
            if (negativeOffset.pixels != -offset.pixels) {
              negativeOffset.jumpTo(-offset.pixels);
            }
            print(
                "${controller.position.minScrollExtent} ${controller.position.maxScrollExtent} ${controller.position.pixels}");
          });

          void callback() {
            if (offset is ExternalBoundedScrollPosition &&
                controller.hasClients &&
                controller.position.hasContentDimensions) {
              print(
                  "${controller.position.minScrollExtent} ${controller.position.maxScrollExtent} ${controller.position.pixels}");
              offset.applyMinExtent(-negativeOffset.maxScrollExtent);
            }
          }

          return Stack(
            children: [
              ValueListenableBuilder<PageLoadingState>(
                  valueListenable: pagedLoader.bottomElementsState,
                  builder: (context, state, _) {
                    return ViewportWithPerformLayoutCallback(
                      callback: callback,
                      axisDirection: flipAxisDirection(axisDirection),
                      anchor: anchor,
                      offset: negativeOffset,
                      slivers: [
                        _buildSliver(
                          context,
                          state,
                          negative: true,
                        )
                      ],
                      cacheExtent: cacheExtent,
                    );
                  }),
              ValueListenableBuilder<PageLoadingState>(
                valueListenable: pagedLoader.topElementsState,
                builder: (context, state, _) {
                  return ViewportWithPerformLayoutCallback(
                    callback: callback,
                    axisDirection: axisDirection,
                    anchor: 1.0 - anchor,
                    offset: offset,
                    slivers: [
                      _buildSliver(
                        context,
                        state,
                      )
                    ],
                    cacheExtent: cacheExtent,
                  );
                },
              ),
            ],
          );
        });
      });

  Widget _buildElement(
          BuildContext context, KeyType key, ElementType element) =>
      itemBuilder(context, element);

  SliverChildBuilderDelegate _buildNegativeChildrenDelegate(
          PageLoadingState state) =>
      SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          assert(index >= 0 && index <= state.itemCount);
          if (state.itemCount == index) {
            if (state.error != null) {
              return bottomPageLoadingError(context, state.error);
            } else if (state.hasMorePages) {
              pagedLoader.loadPageBelow();
              return bottomPageLoadingIndicator(context);
            }
          }
          assert(index < state.itemCount);
          final result = pagedLoader.getElement(-index - 1);
          return _buildElement(context, result.first, result.second);
        },
        childCount: state.itemCount +
            (state.error != null || state.hasMorePages ? 1 : 0),
      );

  SliverChildBuilderDelegate _buildNonNegativeChildrenDelegate(
          PageLoadingState state) =>
      SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          assert(index >= 0 && index <= state.itemCount);
          if (state.itemCount == index) {
            if (state.error != null) {
              return topPageLoadingError(context, state.error);
            } else if (state.hasMorePages) {
              pagedLoader.loadPageAbove();
              return topPageLoadingIndicator(context);
            }
          }
          assert(index < state.itemCount);
          final result = pagedLoader.getElement(index);
          return _buildElement(context, result.first, result.second);
        },
        childCount: state.itemCount +
            (state.error != null || state.hasMorePages ? 1 : 0),
      );

  Widget _buildSliver(BuildContext context, PageLoadingState state,
      {bool negative = false}) {
    SliverChildBuilderDelegate delegate = negative
        ? _buildNegativeChildrenDelegate(state)
        : _buildNonNegativeChildrenDelegate(state);
    Widget sliver;
    if (itemExtent != null) {
      var itemExtent = this.itemExtent!;
      sliver = SliverFixedExtentList(
        delegate: delegate,
        itemExtent: itemExtent,
      );
    } else {
      sliver = SliverList(
        delegate: delegate,
      );
    }
    if (padding != null) {
      var padding = this.padding!;
      sliver = SliverPadding(
        padding: negative
            ? padding - EdgeInsets.only(top: padding.top)
            : padding - EdgeInsets.only(bottom: padding.bottom),
        sliver: sliver,
      );
    }
    return sliver;
  }
}

class ExternalBoundedScrollPosition extends ScrollPositionWithSingleContext {
  ExternalBoundedScrollPosition({
    required ScrollPhysics physics,
    required ScrollContext context,
    ScrollPosition? oldPosition,
  }) : super(physics: physics, context: context, oldPosition: oldPosition);

  double _minScrollExtent = 0.0;

  @override
  double get minScrollExtent => _minScrollExtent;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    return super.applyContentDimensions(
      _minScrollExtent,
      maxScrollExtent,
    );
  }

  void applyMinExtent(double minScrollExtent) {
    if (_minScrollExtent == minScrollExtent) {
      return;
    }
    _minScrollExtent = minScrollExtent;
    super.applyContentDimensions(
      min(minScrollExtent, maxScrollExtent),
      maxScrollExtent,
    );
  }
}

class ExternalBoundedScrollController extends ScrollController {
  @override
  ExternalBoundedScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) =>
      ExternalBoundedScrollPosition(
        physics: physics,
        context: context,
        oldPosition: oldPosition,
      );
}
