
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'drawing_controller.dart';
import 'helper/color_pic.dart';
import 'helper/edit_text.dart';
import 'helper/ex_value_builder.dart';
import 'helper/safe_state.dart';
import 'helper/safe_value_notifier.dart';
import 'paint_contents/paint_content.dart';
import 'painter.dart';

/// 画板
class DrawingBoard extends StatefulWidget {
  const DrawingBoard({
    Key? key,
    required this.background,
    this.controller,
    this.showDefaultActions = false,
    this.showDefaultTools = false,
    this.drawingCallback,
  }) : super(key: key);

  @override
  _DrawingBoardState createState() => _DrawingBoardState();

  /// 画板背景控件
  final Widget background;

  /// 画板控制器
  final DrawingController? controller;

  /// 显示默认样式的操作栏
  final bool showDefaultActions;

  /// 显示默认样式的工具栏
  final bool showDefaultTools;

  /// 绘制状态回调
  final Function(bool isDrawing)? drawingCallback;
}

class _DrawingBoardState extends State<DrawingBoard>
    with SafeState<DrawingBoard> {
  ///线条粗细进度
  late SafeValueNotifier<double> _indicator;

  ///画板控制器
  late DrawingController _drawingController;

  List<Widget> contentList = [];

  Size size = Size.zero;

  @override
  void initState() {
    super.initState();
    _indicator = SafeValueNotifier<double>(1);
    _drawingController = widget.controller ?? DrawingController();
  }

  @override
  void dispose() {
    _indicator.dispose();
    if (widget.controller == null) {
      _drawingController.dispose();
    }
    super.dispose();
  }

  /// 选择颜色
  Future<void> _pickColor() async {
    final Color? newColor = await showModalBottomSheet<Color?>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (_) => ColorPic(nowColor: _drawingController.getColor),
    );
    if (newColor == null) {
      return;
    }

    if (newColor != _drawingController.getColor) {
      _drawingController.setColor = newColor;
    }
  }

  /// 编辑文字
  Future<void> _editText() async {
    _drawingController.setType = PaintType.text;
    final String? text = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => EditText(defaultText: _drawingController.getText));

    if (text != _drawingController.getText) {
      _drawingController.setText = text;
    }
  }

  Widget createContent() {
    return SizedBox(
      width: size.width,
      height: size.height,
      // child:_buildBoard,
      child: ExValueBuilder<DrawConfig>(
        valueListenable: _drawingController.drawConfig,
        shouldRebuild: (DrawConfig? p, DrawConfig? n) => p!.angle != n!.angle,
        child:
            Container(child: AspectRatio(aspectRatio: 1, child: _buildBoard)),
        builder: (_, DrawConfig? dc, Widget? child) {
          return InteractiveViewer(
            maxScale: 40,
            minScale: 0.1,
            alignPanAxis: true,
            boundaryMargin: const EdgeInsets.all(0),
            child: child!,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    if (contentList.isEmpty) {
      contentList.add(createContent());
    }
    return Stack(
      children: [
        createContent(),
        // ListView.builder(itemCount: contentList.length,itemBuilder: (context,index) =>contentList[index]),
        Positioned(
          bottom: 5.0,
          // child: Column(
          //   children: [
          // if (widget.showDefaultActions) _buildDefaultActions,
          // if (widget.showDefaultTools)
          child: _buildDefaultTools,
          // ],
          // ),
        ),
      ],
    );
  }

  /// 构建画板
  Widget get _buildBoard {
    return Center(
      child: RepaintBoundary(
        key: _drawingController.painterKey,
        child: ExValueBuilder<DrawConfig>(
          valueListenable: _drawingController.drawConfig,
          shouldRebuild: (DrawConfig? p, DrawConfig? n) => p!.angle != n!.angle,
          child: Stack(children: <Widget>[_buildImage, _buildPainter]),
          builder: (_, DrawConfig? dc, Widget? child) {
            return RotatedBox(
              quarterTurns: dc!.angle!,
              child: child,
            );
          },
        ),
      ),
    );
  }

  /// 构建背景
  Widget get _buildImage => widget.background;

  /// 构建绘制层
  Widget get _buildPainter {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: Painter(
        drawingController: _drawingController,
        drawingCallback: widget.drawingCallback,
      ),
    );
  }

  /// 构建默认操作栏
  Widget get _buildDefaultActions {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: Row(
          children: <Widget>[
            SizedBox(
              height: 24,
              width: 160,
              child: ExValueBuilder<double>(
                valueListenable: _indicator,
                builder: (_, double? ind, ___) {
                  return Slider(
                    value: ind!,
                    max: 10,
                    min: 0.1,
                    onChanged: (double v) => _indicator.value = v,
                    onChangeEnd: (double v) =>
                        _drawingController.setThickness = v,
                  );
                },
              ),
            ),
            SizedBox(
              // width: 24,
              // height: 24,
              child: ExValueBuilder<DrawConfig?>(
                valueListenable: _drawingController.drawConfig,
                shouldRebuild: (DrawConfig? p, DrawConfig? n) =>
                    p!.color != n!.color,
                builder: (_, DrawConfig? dc, ___) {
                  return TextButton(
                    onPressed: _pickColor,
                    style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.zero),
                        //圆角
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                        //边框
                        side: MaterialStateProperty.all(
                          const BorderSide(
                              color: Colors.tealAccent, width: 0.67),
                        ),
                        overlayColor:
                            MaterialStateProperty.all(const Color(0x695E6573)),
                        //背景
                        backgroundColor: MaterialStateProperty.all(dc!.color)),
                    child: Container(color: dc.color),
                  );
                },
              ),
            ),
            buildCircular(const Icon(CupertinoIcons.arrow_turn_up_left),
                () => _drawingController.undo()),
            buildCircular(const Icon(CupertinoIcons.arrow_turn_up_right),
                () => _drawingController.redo()),
            buildCircular(const Icon(CupertinoIcons.rotate_right),
                () => _drawingController.turn()),
            buildCircular(const Icon(CupertinoIcons.trash),
                () => _drawingController.clear()),
          ],
        ),
      ),
    );
  }

  /// 构建默认工具栏
  Widget get _buildDefaultTools {
    return Container(
      child: Scrollbar(
       child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: <Widget>[
              SizedBox(
                height: 24,
                width: 160,
                child: ExValueBuilder<double>(
                  valueListenable: _indicator,
                  builder: (_, double? ind, ___) {
                    return Slider(
                      value: ind!,
                      max: 10,
                      min: 0.1,
                      onChanged: (double v) => _indicator.value = v,
                      onChangeEnd: (double v) =>
                          _drawingController.setThickness = v,
                    );
                  },
                ),
              ),
              SizedBox(
                // width: 24,
                // height: 24,
                child: ExValueBuilder<DrawConfig?>(
                  valueListenable: _drawingController.drawConfig,
                  shouldRebuild: (DrawConfig? p, DrawConfig? n) =>
                      p!.color != n!.color,
                  builder: (_, DrawConfig? dc, ___) {
                    return TextButton(
                      onPressed: _pickColor,
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                          //圆角
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          //边框
                          side: MaterialStateProperty.all(
                            const BorderSide(
                                color: Colors.tealAccent, width: 0.67),
                          ),
                          overlayColor: MaterialStateProperty.all(
                              const Color(0x695E6573)),
                          //背景
                          backgroundColor:
                              MaterialStateProperty.all(dc!.color)),
                      child: Container(color: dc.color),
                    );
                  },
                ),
              ),
              buildCircular(const Icon(CupertinoIcons.arrow_turn_up_left),
                  () => _drawingController.undo()),
              buildCircular(const Icon(CupertinoIcons.arrow_turn_up_right),
                  () => _drawingController.redo()),
              buildCircular(const Icon(CupertinoIcons.rotate_right),
                  () => _drawingController.turn()),
              buildCircular(const Icon(CupertinoIcons.trash),
                  () => _drawingController.clear()),
              _buildToolItem(PaintType.simpleLine, CupertinoIcons.pencil,
                  () => _drawingController.setType = PaintType.simpleLine),
              _buildToolItem(PaintType.smoothLine, CupertinoIcons.infinite,
                  () => _drawingController.setType = PaintType.smoothLine),
              _buildToolItem(PaintType.straightLine, Icons.show_chart,
                  () => _drawingController.setType = PaintType.straightLine),
              _buildToolItem(PaintType.rectangle, CupertinoIcons.stop,
                  () => _drawingController.setType = PaintType.rectangle),
              _buildToolItem(
                  PaintType.text, CupertinoIcons.text_cursor, _editText),
              _buildToolItem(PaintType.eraser, CupertinoIcons.bandage,
                  () => _drawingController.setType = PaintType.eraser),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建工具项
  Widget _buildToolItem(PaintType type, IconData icon, Function() onTap) {
    return ExValueBuilder<DrawConfig>(
      valueListenable: _drawingController.drawConfig,
      shouldRebuild: (DrawConfig? p, DrawConfig? n) =>
          p!.paintType == type || n!.paintType == type,
      builder: (_, DrawConfig? dc, __) {
        return buildCircular(
            Icon(
              icon,
              color: dc?.paintType == type ? Colors.blue : null,
            ),
            onTap);
      },
    );
  }

  Widget buildCircular(Widget dChild, Function() onTap) {
    return ElevatedButton(
      child: dChild,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Color(0xffffffff)),
        //背景颜色
        foregroundColor: MaterialStateProperty.all(Color(0xff5E6573)),
        //字体颜色
        overlayColor: MaterialStateProperty.all(Color(0x695E6573)),
        // 高亮色
        shadowColor: MaterialStateProperty.all(Color(0xffffffff)),
        //阴影颜色
        elevation: MaterialStateProperty.all(0),
        //阴影值
        textStyle: MaterialStateProperty.all(TextStyle(fontSize: 12)),
        //字体
        side: MaterialStateProperty.all(
            const BorderSide(width: 1, color: Color(0xffCAD0DB))),
        //边框
        shape: MaterialStateProperty.all(const CircleBorder(
            side: BorderSide(
          //设置 界面效果
          color: Colors.green,
          style: BorderStyle.none,
        ))), //圆角弧度
      ),
      onPressed: onTap,
    );

    // return ElevatedButton(
    //   child: dChild,
    //   style: ButtonStyle(
    //     backgroundColor: MaterialStateProperty.all(Color(0xffFFF8E5)),
    //     //背景颜色
    //     foregroundColor: MaterialStateProperty.all(Color(0xffB85F23)),
    //     //字体颜色
    //     overlayColor: MaterialStateProperty.all(Color(0xffFFF8E5)),
    //     // 高亮色
    //     shadowColor: MaterialStateProperty.all(Color(0xffffffff)),
    //     //阴影颜色
    //     elevation: MaterialStateProperty.all(0),
    //     //阴影值
    //     textStyle: MaterialStateProperty.all(TextStyle(fontSize: 12)),
    //     //字体
    //     side: MaterialStateProperty.all(
    //         BorderSide(width: 1, color: Color(0xffffffff))),
    //     //边框
    //     shape: MaterialStateProperty.all(BeveledRectangleBorder(
    //         borderRadius: BorderRadius.circular(8))), //圆角弧度
    //   ),
    //   onPressed: onTap,
    // );
  }
}
