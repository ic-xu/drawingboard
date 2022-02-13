import 'package:flutter/cupertino.dart';

class BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double eWidth = size.width / 50;
    final double eHeight = size.height / 50;

    //網格背景
    var paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill //填充
      ..color = const Color(0xfff6f6f6); //背景为纸黄色
    canvas.drawRect(Offset.zero & size, paint);

    //網格風格
    paint
      ..style = PaintingStyle.stroke //线
      ..color = const Color(0xffe1e9f0)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 1000; ++i) {
      final double dy = eHeight * i;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }

    for (int i = 0; i <= 1000; ++i) {
      final double dx = eWidth * i;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}