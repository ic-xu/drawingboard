import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:drawingboard/src/helper/ex_paint.dart';

import 'drawing_controller.dart';
import 'paint_contents/custom_text.dart';
import 'paint_contents/eraser.dart';
import 'paint_contents/paint_content.dart';
import 'paint_contents/rectangle.dart';
import 'paint_contents/simple_line.dart';
import 'paint_contents/smooth_line.dart';
import 'paint_contents/straight_line.dart';

/// 绘图板
class Painter extends StatefulWidget {
  const Painter({
    Key? key,
    required this.drawingController,
    this.drawingCallback,
  }) : super(key: key);

  @override
  _PainterState createState() => _PainterState();

  /// 绘制控制器
  final DrawingController drawingController;

  /// 绘制状态回调
  final Function(bool isDrawing)? drawingCallback;
}

class _PainterState extends State<Painter> with WidgetsBindingObserver {
  ///触摸点数量
  ///记录以消除多指触摸引起的问题
  final ValueNotifier<int> _fingerCount = ValueNotifier<int>(0);

  @override
  void dispose() {
    _fingerCount.dispose();
    super.dispose();
  }

//   ///生命周期变化时回调
// //  resumed:应用可见并可响应用户操作
// //  inactive:用户可见，但不可响应用户操作
// //  paused:已经暂停了，用户不可见、不可操作
// //  suspending：应用被挂起，此状态IOS永远不会回调
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     _fingerCount.value = 0;
//   }
//
//   ///当前系统改变了一些访问性活动的回调
//   @override
//   void didChangeAccessibilityFeatures() {
//     super.didChangeAccessibilityFeatures();
//     _fingerCount.value = 0;
//   }

  ///手指落下
  void _onPanStart(DragStartDetails dsd) {
    // if (_fingerCount.value > 1) {
    //   return;
    // }
    // widget.drawingController.startDraw(dsd.localPosition);
    // widget.drawingController.drawing(dsd.localPosition);
    // widget.drawingCallback?.call(true);
  }

  ///手指落下
  void _onPanDown(DragDownDetails dsd) {
    if (_fingerCount.value > 1) {
      return;
    }
    // var position = dsd.localPosition;
    // print("手指落下位置是：$position");
    // var config = widget.drawingController.getColor!.value;
    // print("配置是 ：$config");
    widget.drawingController.startDraw(dsd.localPosition);
    // widget.drawingController.drawing(dsd.localPosition);
    widget.drawingCallback?.call(true);
  }

  ///手指移动
  void _onPanUpdate(DragUpdateDetails dud) {
    if (_fingerCount.value > 1) {
      return;
    }
    // var position = dud.localPosition;
    // print("手指滑动位置是：$position");
    // var config = widget.drawingController.getColor!.value;
    // print("配置是 ：$config");
    widget.drawingController.drawing(dud.localPosition);
    widget.drawingCallback?.call(true);
  }

  ///手指抬起
  void _onPanEnd(DragEndDetails ded) {
    if (_fingerCount.value > 1) {
      return;
    }
    // var position = ded.velocity.pixelsPerSecond;
    // print("手指抬起位置是：$position");
    // var config = widget.drawingController.getColor!.value;
    // print("配置是 ：$config");
    widget.drawingController.endDraw();
    widget.drawingCallback?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent pde) => _fingerCount.value++,
      onPointerUp: (PointerUpEvent pue) => _fingerCount.value = 0,
      child: ValueListenableBuilder<int>(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CustomPaint(
                  painter: _DeepPainter(
                      drawingController: widget.drawingController)),
              CustomPaint(
                  painter:
                      _UpPainter(drawingController: widget.drawingController)),
            ],
          ),
        ),
        valueListenable: _fingerCount,
        builder: (_, int? count, Widget? child) {
          return GestureDetector(
            child: child,
            onPanDown: count! <= 1 ? _onPanDown : null,
            // onPanStart: count <= 1 ? _onPanStart : null,
            onPanUpdate: count <= 1 ? _onPanUpdate : null,
            onPanEnd: count <= 1 ? _onPanEnd : null,
          );
        },
      ),
    );
  }
}

///表层画板
class _UpPainter extends CustomPainter {
  _UpPainter({this.drawingController})
      : super(repaint: drawingController?.drawConfig);

  final DrawingController? drawingController;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawingController?.currentContent == null) {
      return;
    }
    try {
      switch (drawingController?.getType) {
        case PaintType.simpleLine:
          _drawPath(canvas, drawingController?.currentContent as SimpleLine);
          break;
        case PaintType.straightLine:
          _drawLine(canvas, drawingController?.currentContent as StraightLine);
          break;
        case PaintType.rectangle:
          _drawRect(canvas, drawingController?.currentContent as Rectangle);
          break;
        case PaintType.text:
          _drawText(
              canvas, size, drawingController?.currentContent as CustomText,
              uper: true);
          break;
        case PaintType.smoothLine:
          _drawSmooth(canvas, drawingController?.currentContent as SmoothLine);
          break;
        case PaintType.eraser:
          _eraser(canvas, size, drawingController?.currentContent as Eraser);
          break;
        default:
          break;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

///底层画板
class _DeepPainter extends CustomPainter {
  _DeepPainter({this.drawingController})
      : super(repaint: drawingController?.realPainter);
  final DrawingController? drawingController;

  @override
  void paint(Canvas canvas, Size size) {
    final List<PaintContent?>? _contents = drawingController?.getHistory;
    if (_contents!.isEmpty) {
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());

    for (int i = 0; i < drawingController!.currentIndex!; i++) {
      final PaintContent item = _contents[i]!;
      switch (item.type) {
        case PaintType.simpleLine:
          _drawPath(canvas, item as SimpleLine);
          break;
        case PaintType.straightLine:
          _drawLine(canvas, item as StraightLine);
          break;
        case PaintType.rectangle:
          _drawRect(canvas, item as Rectangle);
          break;
        case PaintType.text:
          _drawText(canvas, size, item as CustomText);
          break;
        case PaintType.smoothLine:
          _drawSmooth(canvas, item as SmoothLine);
          break;
        case PaintType.eraser:
          _eraser(canvas, size, item as Eraser);
          break;
        default:
          break;
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

///绘制自由线条
void _drawPath(Canvas canvas, SimpleLine line) =>
    canvas.drawPath(line.path, line.paint);

///绘制直线
void _drawLine(Canvas canvas, StraightLine line) =>
    canvas.drawLine(line.startPoint, line.endPoint, line.paint);

///绘制矩形
void _drawRect(Canvas canvas, Rectangle r) => canvas.drawRect(
    Rect.fromLTRB(
        r.startPoint.dx, r.startPoint.dy, r.endPoint.dx, r.endPoint.dy),
    r.paint);

///绘制文本
void _drawText(Canvas canvas, Size size, CustomText text, {bool uper = false}) {
  canvas.save();

  canvas.rotate(-math.pi * 0.5 * text.angle!);

  if (text.angle == 1) {
    canvas.translate(-size.height, 0);
  }

  if (text.angle == 2) {
    canvas.translate(-size.width, -size.height);
  }

  if (text.angle == 3) {
    canvas.translate(0, -size.width);
  }

  if (uper) {
    canvas.drawRect(
      Rect.fromLTWH(
        text.realStart(size)!.dx,
        text.realStart(size)!.dy,
        text.realEnd(size)!.dx - text.realStart(size)!.dx,
        text.size!,
      ),
      text.paint,
    );
  }

  text.textPainter!.layout(maxWidth: text.maxWidth!);
  text.textPainter!.paint(canvas, text.realStart(size)!);

  canvas.restore();
}

///绘制笔触自由线条
void _drawSmooth(Canvas canvas, SmoothLine line) {
  for (int i = 1; i < line.points.length; i++) {
   var strokeWidth =  line.strokeWidthList[i];
   print(" 画笔宽度为 $strokeWidth");
    canvas.drawPath(
      Path()..moveTo(line.points[i - 1].dx, line.points[i - 1].dy)
        ..lineTo(line.points[i].dx, line.points[i].dy),

      line.paint.copyWith(strokeWidth: line.strokeWidthList[i]),
    );
  }
}

///绘制自由线条
void _eraser(Canvas canvas, Size size, Eraser line) =>
    canvas.drawPath(line.path, line.paint);
