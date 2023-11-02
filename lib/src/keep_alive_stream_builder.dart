import 'package:flutter/material.dart';
import 'package:keep_alive_builder/src/keep_alive_future_builder.dart';

class KeepAliveStreamBuilder<T> extends StatefulWidget {
  final Stream<T?>? stream;
  final WidgetBuilderByValue<T> builder;
  final Widget? loading;
  final Widget? empty;
  final ErrorWidgetBuilderByValue? errorBuilder;
  final Key? refreshKey;

  const KeepAliveStreamBuilder({
    super.key,
    this.stream,
    required this.builder,
    this.loading,
    this.empty,
    this.errorBuilder,
    this.refreshKey,
  });

  @override
  State<KeepAliveStreamBuilder> createState() =>
      _KeepAliveStreamBuilderState<T>();
}

class _KeepAliveStreamBuilderState<T> extends State<KeepAliveStreamBuilder<T>> {
  Stream<T?>? _stream;

  @override
  void didUpdateWidget(covariant KeepAliveStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _stream = widget.stream;
    }
  }

  @override
  void initState() {
    super.initState();
    _stream = widget.stream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return widget.errorBuilder?.call(snapshot.error) ??
                Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return widget.loading ?? const SizedBox();
          }

          if ((snapshot.connectionState == ConnectionState.active ||
                  snapshot.connectionState == ConnectionState.done) &&
              snapshot.data is T) {
            return widget.builder.call(snapshot.data as T);
          }

          return widget.empty ?? const SizedBox();
        });
  }
}
