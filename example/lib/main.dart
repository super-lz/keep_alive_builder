import 'package:flutter/material.dart';
import 'package:keep_alive_builder/keep_alive_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _count1 = 1;
  int _count2 = 1;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 40);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          gap,
          FutureBuilder<int>(
            future: Future(() async {
              await Future.delayed(
                const Duration(seconds: 1),
              );
              return _count1;
            }),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('error');
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const Text('loading...');
              }

              return Text('future builder: ${snapshot.data}');
            },
          ),
          gap,
          KeepAliveFutureBuilder<int>(
              needLoadingForSubsequentRequests: false,
              refreshKey: ValueKey(_count2),
              futureGenerator: () => Future(() async {
                    await Future.delayed(
                      const Duration(seconds: 1),
                    );
                    return _count2;
                  }),
              loading: const Text('loading...'),
              builder: (value) {
                return Text('keep alive future builder: $value');
              }),
          gap,
          TextButton(
              onPressed: () {
                setState(() {
                  _count1++;
                  _count2++;
                });
              },
              child: const Text('rebuild')),
        ]),
      ),
    );
  }
}
