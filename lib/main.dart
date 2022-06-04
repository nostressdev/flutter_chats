import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chats/src/core/BidirectionalPagedLoader.dart';
import 'package:flutter_chats/src/models/Pair.dart';
import 'package:flutter_chats/src/models/Triple.dart';
import 'package:flutter_chats/src/ui/BidirectionalScrollPagination.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BidirectionalPagedLoader<int, int> loader =
      BidirectionalPagedLoader<int, int>(
    delegate: BidirectionalPagedLoaderDelegateBuilder(
        loadPageBelowFunction: (int key) {
      if (key < -10) {
        return Future.delayed(
            const Duration(seconds: 2), () => Future.error('Далеко умотал'));
      }
      return Future.delayed(const Duration(seconds: 2), () {
        return Pair(
            first: List.generate(20, (index) => key - index - 1), second: true);
      });
    }, loadPageAboveFunction: (int key) {
      if (key > 10) {
        return Future.delayed(
            const Duration(seconds: 2), () => Future.error('Далеко умотал'));
      }
      return Future.delayed(const Duration(seconds: 2), () {
        return Pair(
            first: List.generate(20, (index) => key + index + 1), second: true);
      });
    }, loadFirstPageFunction: (int key, bool up) {
      if (up) {
        return Future.delayed(
          const Duration(seconds: 2),
          () => Triple(
            first: List.generate(20, (index) => key - index),
            second: true,
            third: true,
          ),
        );
      } else {
        return Future.delayed(
          const Duration(seconds: 2),
          () => Triple(
            first: List.generate(20, (index) => key + index),
            second: true,
            third: true,
          ),
        );
      }
    }),
    keyFunction: (value) => value,
  );

  @override
  void initState() {
    loader.loadFirstPage(0, false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: () {
          //loader.scrollUpTo(1000);
          loader.scrollDownTo(-1000);
        },
        child: Container(
          color: Colors.red,
          width: 50,
          height: 50,
        ),
      ),
      body: BidirectionalScrollPagination<int, int>.builder(
        axisDirection: AxisDirection.up,
        itemBuilder: (BuildContext context, int value) =>
            Text("Item #${value}"),
        pagedLoader: loader,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        bottomPageLoadingError: (_, Object? error) => Text(error.toString()),
        topPageLoadingError: (_, Object? error) => Text(error.toString()),
        firstPageLoadingError: (_, Object? error) => Text(error.toString()),
        firstPageLoadingIndicator: (_) => const CircularProgressIndicator(),
        topPageLoadingIndicator: (_) => const CircularProgressIndicator(),
        bottomPageLoadingIndicator: (_) => const CircularProgressIndicator(),
        emptyWidgetBuilder: (_) => const Center(
          child: Text("Здесь пока пусто"),
        ),
      ),
    );
  }
}
