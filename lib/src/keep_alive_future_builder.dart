import 'package:flutter/material.dart';

typedef WidgetBuilderByValue<T> = Widget Function(T value);
typedef ErrorWidgetBuilderByValue = Widget Function(Object? error);

///该组件能保证无闪刷新，也就是在重新build时不会在包含中间的loading态
///如果需要主动请求最新的数据，那么必须传入都够区分数据的refreshKey来强制请求新数据
///这里的范型还是要指定的，即便你是自定义的Future，你可以指定范型bool，最后随意返回true或false
///要不然[needLoadingForSubsequentRequests]情况下，第一次请求会出现没有loading的情况，
///这是因为未获取到数据时，会一直loading
class KeepAliveFutureBuilder<T> extends StatefulWidget {
  ///这里使用[futureGenerator]是因为如果直接传入future，
  ///由于Future类似Promise直接在外部build时就会请求，而且每次build如果不在外部做缓存，也会重新执行
  ///这样就导致很多没必要的请求，传入这个[futureGenerator]就能保证可以在该组件内缓存请求和控制何时发生，
  ///无需外部再去做缓存就能保证减少请求
  final Future<T?>? Function() futureGenerator;
  final WidgetBuilderByValue<T> builder;
  final Widget? loading;

  ///是否在加载时无缝衔接，也就是第一次加载完成数据时，后续将不会在请求时有loading状态
  ///能够有效防止闪烁，优化视觉效果
  final bool needLoadingForSubsequentRequests;
  final Widget? empty;
  final ErrorWidgetBuilderByValue? errorBuilder;

  ///oldWidget的[refreshKey]和widget的[refreshKey]不同时会重置init状态
  ///来重新发起请求，这里最好使用[refreshKey]达到这个目的而不是[key]，因为[key]的
  ///不同将导致整个组件内部的所有组件丢失状态，包括FutureBuilder中缓存的data，这样无法做到无缝加载
  ///配合外部状态组件，在initState中构造future，并传入该组件只会在initState时调用请求，后续build并不会再次调用
  final Key? refreshKey;

  const KeepAliveFutureBuilder({
    super.key,
    this.refreshKey,
    required this.futureGenerator,
    required this.builder,
    this.loading,
    this.needLoadingForSubsequentRequests = true,
    this.empty,
    this.errorBuilder,
  });

  @override
  State<KeepAliveFutureBuilder<T>> createState() =>
      _KeepAliveFutureBuilderState<T>();
}

class _KeepAliveFutureBuilderState<T> extends State<KeepAliveFutureBuilder<T>> {
  late Future<T?>? _future;

  @override
  void didUpdateWidget(covariant KeepAliveFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _future = widget.futureGenerator();
    }
  }

  @override
  void initState() {
    super.initState();
    _future = widget.futureGenerator();
  }

  @override
  void dispose() {
    super.dispose();
  }

  ///FutureBuilder会保留了上一次的状态，在一下次请求过程中，snapshot.data携带的是上一次的结果，
  ///因此可以利用这个特性，在请求过程中直接返回builder而不是再返回占位组件，这样就会无缝切换到下一个值的状态
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(snapshot.error) ??
              Text('Error: ${snapshot.error}');
        }

        if (widget.needLoadingForSubsequentRequests) {
          if (snapshot.connectionState != ConnectionState.done) {
            return widget.loading ?? const SizedBox();
          }
        } else {
          // 作用：只有在第一次请求的时候会loading，后面重新请求相同类型的数据时不会有loading状态
          // 原理：FutureBuilder会缓存之前的data，即便future不同时，loading过程中snapshot.data仍是之前的数据
          // 流程：第一次加载时snapshot不是T并且状态也为loading，会返回loading组件
          // 假如后面每一次加载时请求到的最终数据是null，不是T类型，但是状态是done，不会返回loading组件
          // 假如后面每一次加载时请求到的最终数据是T类型，也不会返回loading组件
          // 这样就达到了后续的每一次请求无缝加载的要求
          if (snapshot.data is! T &&
              snapshot.connectionState != ConnectionState.done) {
            return widget.loading ?? const SizedBox();
          }
        }

        if (snapshot.data is T) {
          return widget.builder(snapshot.data as T);
        }

        return widget.empty ?? const SizedBox();
      },
    );
  }
}
