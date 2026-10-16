// Bingo 5x5 board — Square, tap-to-mark, marked/dimmed/sunken/disabled states.
import 'package:flutter/material.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';

class BingoBoardView extends StatelessWidget {
  const BingoBoardView({
    super.key,
    required this.board,
    required this.marked,
    required this.calledNumbers,
    this.recentlyMarked = const <int>[],
    this.recentlyCompletedLines = const <int>[],
    this.enabled = true,
    this.onTapNumber,
  });

  final List<int> board;
  final List<bool> marked;
  final List<int> calledNumbers;
  final List<int> recentlyMarked;
  final List<int> recentlyCompletedLines;
  final bool enabled;
  final ValueChanged<int>? onTapNumber;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double side = constraints.maxWidth;
        return SizedBox(
          width: side,
          height: side,
          child: Stack(
            children: [
              // Column headers
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: List.generate(5, (i) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          _colLabel(i),
                          style: ZenTypography.labelSm
                              .copyWith(color: ZenText.muted),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 25,
                  itemBuilder: (_, idx) {
                    final int value = board[idx];
                    final bool isMarked = marked.length > idx && marked[idx];
                    final bool isRecent =
                        recentlyMarked.contains(idx);
                    final bool isCalled = calledNumbers.contains(value);
                    return _Cell(
                      value: value,
                      marked: isMarked,
                      recent: isRecent,
                      called: isCalled,
                      enabled: enabled,
                      onTap: () => onTapNumber?.call(value),
                    );
                  },
                ),
              ),
              if (recentlyCompletedLines.isNotEmpty)
                IgnorePointer(
                  child: CustomPaint(
                    size: Size(side - 16, side - 16),
                    painter: _LinePainter(recentlyCompletedLines),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _colLabel(int i) => String.fromCharCode('B'.codeUnitAt(0) + i);
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.marked,
    required this.recent,
    required this.called,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final bool marked;
  final bool recent;
  final bool called;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late Color borderColor;
    if (marked) {
      bg = recent ? ZenAccent.winSurface : const Color(0x33D1FAE5);
      fg = ZenAccent.winText;
      borderColor = ZenAccent.success;
    } else if (called) {
      bg = ZenSurfaces.containerLow;
      fg = ZenText.muted;
      borderColor = ZenOutline.variant;
    } else {
      bg = ZenSurfaces.card;
      fg = ZenText.primary;
      borderColor = ZenOutline.hairline;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled && !marked ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          alignment: Alignment.center,
          child: Stack(
            children: [
              Center(
                child: Text(
                  value < 10 ? '0$value' : '$value',
                  style: ZenTypography.headlineSm.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (marked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: ZenAccent.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        size: 11, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.lines);
  final List<int> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = ZenAccent.secondary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final int idx in lines) {
      _drawLine(canvas, size, p, idx);
    }
  }

  void _drawLine(Canvas canvas, Size size, Paint p, int line) {
    final List<Offset> coords = _lineCoords(line, size);
    if (coords.length < 2) return;
    canvas.drawLine(coords.first, coords.last, p);
    for (final c in coords) {
      canvas.drawCircle(c, 3, p);
    }
  }

  List<Offset> _lineCoords(int line, Size size) {
    final double cell = size.width / 5;
    Offset pt(int r, int c) => Offset(c * cell + cell / 2, r * cell + cell / 2);
    switch (line) {
      case 0:
        return [pt(0, 0), pt(0, 1), pt(0, 2), pt(0, 3), pt(0, 4)];
      case 1:
        return [pt(1, 0), pt(1, 1), pt(1, 2), pt(1, 3), pt(1, 4)];
      case 2:
        return [pt(2, 0), pt(2, 1), pt(2, 2), pt(2, 3), pt(2, 4)];
      case 3:
        return [pt(3, 0), pt(3, 1), pt(3, 2), pt(3, 3), pt(3, 4)];
      case 4:
        return [pt(4, 0), pt(4, 1), pt(4, 2), pt(4, 3), pt(4, 4)];
      case 5:
        return [pt(0, 0), pt(1, 0), pt(2, 0), pt(3, 0), pt(4, 0)];
      case 6:
        return [pt(0, 1), pt(1, 1), pt(2, 1), pt(3, 1), pt(4, 1)];
      case 7:
        return [pt(0, 2), pt(1, 2), pt(2, 2), pt(3, 2), pt(4, 2)];
      case 8:
        return [pt(0, 3), pt(1, 3), pt(2, 3), pt(3, 3), pt(4, 3)];
      case 9:
        return [pt(0, 4), pt(1, 4), pt(2, 4), pt(3, 4), pt(4, 4)];
      case 10:
        return [pt(0, 0), pt(1, 1), pt(2, 2), pt(3, 3), pt(4, 4)];
      case 11:
        return [pt(0, 4), pt(1, 3), pt(2, 2), pt(3, 1), pt(4, 0)];
    }
    return const [];
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.lines.toString() != lines.toString();
}