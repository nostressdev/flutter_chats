class PageLoadingState {
  PageLoadingState({
    this.hasMorePages = true,
    this.itemCount = 0,
    this.error,
  });

  bool hasMorePages;
  int itemCount;
  Object? error;
}