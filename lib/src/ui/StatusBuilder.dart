import 'package:flutter/cupertino.dart';
import 'package:flutter_chats/src/models/Status.dart';
import 'package:flutter_chats/src/ui/ElementBuilder.dart';

typedef ValuedWidgetBuilder<T> = Widget Function(BuildContext, T);

class StatusBuilder<T> extends StatelessWidget {
  const StatusBuilder({
    Key? key,
    required this.statusNotifier,
    required this.onSuccess,
    required this.onError,
    required this.onEmpty,
    required this.onLoading,
  }) : super(key: key);

  final ValueNotifier<Status> statusNotifier;
  final WidgetBuilder onEmpty;
  final WidgetBuilder onLoading;
  final ValuedWidgetBuilder<T> onSuccess;
  final ErrorBuilder onError;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Status>(
      valueListenable: statusNotifier,
      builder: (context, status, _) {
        if (status.isError) {
          return onError(context, status.error);
        } else if (status.isEmpty) {
          return onEmpty(context);
        } else if (status.isLoading) {
          return onLoading(context);
        } else if (status.isSuccess) {
          return onSuccess(context, status.value!);
        }
        throw ArgumentError("invalid Status");
      });
}
