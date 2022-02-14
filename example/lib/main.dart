import 'dart:io';
import 'dart:typed_data';

import 'package:drawingboard/drawingboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bacground.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode) {
      exit(1);
    }
  };

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ///绘制控制器
  final DrawingController _drawingController = DrawingController(
    ///配置
    config: DrawConfig(
      paintType: PaintType.simpleLine,
      color: Colors.red,
      thickness: 0.2,
      angle: 0,
      text: '输入文本',
    ),
  );

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }

  ///获取画板数据 `getImageData()`
  Future<void> _getImageData() async {
    final Uint8List? data =
        (await _drawingController.getImageData())?.buffer.asUint8List();
    if (data == null) {
      print('获取图片数据失败');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (BuildContext c) {
        return Material(
          color: Colors.transparent,
          child:
              InkWell(onTap: () => Navigator.pop(c), child: Image.memory(data)),
        );
      },
    );
  }
  /// 构建绘制层
  Widget get _buildBgPainter {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: CustomPaint(
        painter: BgPainter(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey,
      body: DrawingBoard(
        controller: _drawingController,
        background: _buildBgPainter,
        // background: Container(width: 1920, height: 1080, color: Colors.white),
        showDefaultActions: true,
        showDefaultTools: true,
      ),
      // Column(
      //   children: <Widget>[
      //     Expanded(
      //   child: ,
      //     ),
      //   ],
      // ),
    );
  }
}
