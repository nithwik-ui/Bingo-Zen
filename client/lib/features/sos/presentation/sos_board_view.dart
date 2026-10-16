// SOS 5x5 board view — empty/S/O/disabled states + SOS line overlay.
import 'package:flutter/material.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';

class SosBoardView extends StatelessWidget {
  const SosBoardView({
    super.key,
    required this.board,
    required this.onTapCell,
    this.enabled = true,
    this.newSosLines = const <List<int>>[],
  });
  final List<int> board;
  final bool enabled;
  final List<List<int>> newSosLines;
  final void Function(int row, int col) onTapCell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final double side = c.maxWidth;
        return SizedBox(
          width: side,
          height: side,
          child: Stack(
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 25,
                itemBuilder: (_, idx) {
                  final int v = board[idx];
                  final int r = idx ~/ 5;
                  final int col = idx % 5;
                  return _Cell(
                    value: v,
                    enabled: enabled && v == 0,
                    onTap: () => onTapCell(r, col),
                    highlight: _cellInList(idx),
                  );
                },
              ),
              if (newSosLines.isNotEmpty)
                IgnorePointer(
                  child: CustomPaint(
                    size: Size(side, side),
                    painter: _SosLinePainter(newSosLines),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _cellInList(int idx) {
    for (final line in newSosLines) {
      if (line.contains(idx)) return true;
    }
    return false;
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.highlight,
  });
  final int value; // 0 empty, 1 S, 2 O
  final bool enabled;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final String letter = value == 1 ? 'S' : (value == 2 ? 'O' : '');
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: highlight ? const Color(0x333B49DF) : ZenSurfaces.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? ZenAccent.primary : ZenOutline.hairline,
              width: highlight ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: letter.isEmpty
              ? null
              : Text(letter,
                  style: ZenTypography.headlineMd.copyWith(
                    color: value == 1
                        ? ZenAccent.primary
                        : ZenAccent.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  )),
        ),
      ),
    );
  }
}

class _SosLinePainter extends CustomPainter {
  _SosLinePainter(this.lines);
  final List<List<int>> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = ZenAccent.secondary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final double cell = size.width / 5;
    Offset pt(int idx) =>
        Offset((idx % 5) * cell + cell / 2, (idx ~/ 5) * cell + cell / 2);
    for (final line in lines) {
      if (line.length < 3) continue;
      canvas.drawLine(pt(line.first), pt(line.last), p);
      for (final idx in line) {
        canvas.drawCircle(pt(idx), 4, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SosLinePainter old) =>
      old.lines.toString() != lines.toString();
}