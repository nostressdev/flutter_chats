import 'package:flutter/foundation.dart';
import 'package:flutter_chats/src/models/PageLoadingState.dart';
import 'package:flutter_chats/src/models/Status.dart';
import 'package:flutter_chats/src/models/Pair.dart';
import 'package:flutter_chats/src/models/Triple.dart';
import 'package:async/async.dart';

typedef KeyFunction<ElementType, KeyType> = KeyType Function(ElementType);

class BidirectionalPagedLoader<ElementType, KeyType> {
  BidirectionalPagedLoaderDelegate<ElementType, KeyType> delegate;

  BidirectionalPagedLoader({
    required this.delegate,
    required KeyFunction keyFunction,
  }) : _keyFunction = keyFunction;

  final KeyFunction _keyFunction;
  final List<ElementType> _negativeElements = [];
  final List<ElementType> _nonNegativeElements = [];

  final ValueNotifier<Status<double>> firstPageLoading =
      ValueNotifier(Status.loading());
  final ValueNotifier<PageLoadingState> topElementsState =
      ValueNotifier(PageLoadingState());
  final ValueNotifier<PageLoadingState> bottomElementsState =
      ValueNotifier(PageLoadingState());

  final List<CancelableOperation> _cancelables = [];

  Pair<KeyType, ElementType> getElement(int index) {
    if (index >= _nonNegativeElements.length ||
        index < -_negativeElements.length) {
      throw RangeError.range(
          index, -_negativeElements.length, _nonNegativeElements.length - 1);
    } else {
      ElementType element = index >= 0
          ? _nonNegativeElements[index]
          : _negativeElements[-index - 1];
      return Pair(
        first: _keyFunction(element),
        second: element,
      );
    }
  }

  void _clear() {
    for (final cancelable in _cancelables) {
      cancelable.cancel();
    }
    _cancelables.clear();
    firstPageLoading.value = Status.loading();
    topElementsState.value = PageLoadingState();
    bottomElementsState.value = PageLoadingState();
    _nonNegativeElements.clear();
    _negativeElements.clear();
  }

  void scrollDownTo(KeyType firstElementKey) {
    _clear();
    loadFirstPage(firstElementKey, false);
  }

  void scrollUpTo(KeyType firstElementKey) {
    _clear();
    loadFirstPage(firstElementKey, true);
  }

  void loadFirstPage(KeyType firstElementKey, bool up) {
    CancelableOperation? cancelable;
    cancelable = CancelableOperation.fromFuture(
      delegate.loadFirstPage(firstElementKey, up).then((value) {
        if (cancelable!.isCanceled) {
          return;
        }
        if (value.first.isEmpty) {
          firstPageLoading.value = Status.empty();
        } else {
          double anchor = 0.0;
          if (up) {
            _negativeElements.addAll(value.first);
          } else {
            _nonNegativeElements.addAll(value.first);
            anchor = 1.0;
          }
          topElementsState.value = PageLoadingState(
            hasMorePages: value.second,
            itemCount: _nonNegativeElements.length,
          );
          bottomElementsState.value = PageLoadingState(
            hasMorePages: value.third,
            itemCount: _negativeElements.length,
          );
          firstPageLoading.value = Status.success(anchor);
        }
      }).catchError((err) {
        if (cancelable!.isCanceled) {
          return;
        }
        firstPageLoading.value = Status.error(err);
      }),
    );
    _cancelables.add(cancelable);
  }

  void loadPageAbove() {
    assert(_negativeElements.length + _nonNegativeElements.length > 0);
    CancelableOperation? cancelable;
    KeyType key = _keyFunction(
      _nonNegativeElements.isEmpty
          ? _negativeElements.first
          : _nonNegativeElements.last,
    );
    cancelable = CancelableOperation.fromFuture(
      delegate.loadPageAbove(key).then((value) {
        if (cancelable!.isCanceled) {
          return;
        }
        _nonNegativeElements.addAll(value.first);
        topElementsState.value = PageLoadingState(
          hasMorePages: value.second,
          itemCount: _nonNegativeElements.length,
        );
      }).catchError((err) {
        if (cancelable!.isCanceled) {
          return;
        }
        topElementsState.value = PageLoadingState(
          hasMorePages: false,
          error: err,
          itemCount: _nonNegativeElements.length,
        );
      }),
    );
    _cancelables.add(cancelable);
  }

  void loadPageBelow() {
    assert(_negativeElements.length + _nonNegativeElements.length > 0);
    CancelableOperation? cancelable;
    KeyType key = _keyFunction(_negativeElements.isEmpty
        ? _nonNegativeElements.first
        : _negativeElements.last);
    cancelable = CancelableOperation.fromFuture(
      delegate.loadPageBelow(key).then((value) {
        if (cancelable!.isCanceled) {
          return;
        }
        _negativeElements.addAll(value.first);
        bottomElementsState.value = PageLoadingState(
          hasMorePages: value.second,
          itemCount: _negativeElements.length,
        );
      }).catchError(
        (err) {
          if (cancelable!.isCanceled) {
            return;
          }
          bottomElementsState.value = PageLoadingState(
            hasMorePages: false,
            error: err,
            itemCount: _negativeElements.length,
          );
        },
      ),
    );
    _cancelables.add(cancelable);
  }
}

typedef LoadPageFunction<ElementType, KeyType>
    = Future<Pair<List<ElementType>, bool>> Function(KeyType key);

typedef LoadFirstPageFunction<ElementType, KeyType>
    = Future<Triple<List<ElementType>, bool, bool>> Function(
        KeyType firstElementKey, bool up);

abstract class BidirectionalPagedLoaderDelegate<ElementType, KeyType> {
  Future<Triple<List<ElementType>, bool, bool>> loadFirstPage(
      KeyType firstElementKey, bool up);

  Future<Pair<List<ElementType>, bool>> loadPageBelow(KeyType lastElementKey);

  Future<Pair<List<ElementType>, bool>> loadPageAbove(KeyType lastElementKey);
}

class BidirectionalPagedLoaderDelegateBuilder<ElementType, KeyType>
    extends BidirectionalPagedLoaderDelegate<ElementType, KeyType> {
  BidirectionalPagedLoaderDelegateBuilder({
    required LoadPageFunction<ElementType, KeyType> loadPageAboveFunction,
    required LoadPageFunction<ElementType, KeyType> loadPageBelowFunction,
    required LoadFirstPageFunction<ElementType, KeyType> loadFirstPageFunction,
  })  : _loadPageAboveFunction = loadPageAboveFunction,
        _loadPageBelowFunction = loadPageBelowFunction,
        _loadFirstPageFunction = loadFirstPageFunction;

  final LoadPageFunction<ElementType, KeyType> _loadPageAboveFunction;
  final LoadPageFunction<ElementType, KeyType> _loadPageBelowFunction;
  final LoadFirstPageFunction<ElementType, KeyType> _loadFirstPageFunction;

  @override
  Future<Triple<List<ElementType>, bool, bool>> loadFirstPage(
          KeyType firstElementKey, bool up) =>
      _loadFirstPageFunction(firstElementKey, up);

  @override
  Future<Pair<List<ElementType>, bool>> loadPageAbove(KeyType lastElementKey) =>
      _loadPageAboveFunction(lastElementKey);

  @override
  Future<Pair<List<ElementType>, bool>> loadPageBelow(KeyType lastElementKey) =>
      _loadPageBelowFunction(lastElementKey);
}
