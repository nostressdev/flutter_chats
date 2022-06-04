class Status<T> {
  final bool isLoading;
  final bool isError;
  final bool isSuccess;
  final bool isEmpty;
  final bool isLoadingMore;
  final Object? error;
  final T? value;

  Status._({
    this.isEmpty = false,
    this.isLoading = false,
    this.isError = false,
    this.isSuccess = false,
    this.error,
    this.isLoadingMore = false,
    this.value,
  });

  factory Status.loading() {
    return Status._(isLoading: true);
  }

  factory Status.loadingMore() {
    return Status._(isSuccess: true, isLoadingMore: true);
  }

  factory Status.success(T? value) {
    return Status._(isSuccess: true, value: value);
  }

  factory Status.error([Object? error]) {
    return Status._(isError: true, error: error);
  }

  factory Status.empty() {
    return Status._(isEmpty: true);
  }
}
