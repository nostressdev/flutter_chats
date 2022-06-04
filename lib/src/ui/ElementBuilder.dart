import 'package:flutter/material.dart';

typedef TypedBuilder<T> = Widget Function(BuildContext context, T data);
typedef ErrorBuilder = Widget Function(BuildContext context, Object? error);