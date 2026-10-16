// 6-pin alphanumeric code input — used for join-room flow.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';

class RoomCodeInput extends StatefulWidget {
  const RoomCodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onSubmit,
  });
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onSubmit;

  @override
  State<RoomCodeInput> createState() => _RoomCodeInputState();
}

class _RoomCodeInputState extends State<RoomCodeInput> {
  late final FocusNode _focus;
  String get _text => widget.controller.text.toUpperCase();

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    widget.controller.addListener(_onChange);
  }

  void _onChange() {
    final String normalized = widget.controller.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-HJ-KL-NP-Z2-9]'), '');
    if (normalized != widget.controller.text) {
      widget.controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    setState(() {});
    if (normalized.length >= widget.length) {
      widget.onSubmit?.call(normalized);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              final String? c = i < _text.length ? _text[i] : null;
              final bool focused = _focus.hasFocus && i == _text.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 44,
                  height: 56,
                  decoration: BoxDecoration(
                    color: focused ? ZenSurfaces.card : ZenSurfaces.tile,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: focused ? ZenAccent.primary : ZenOutline.hairline,
                    ),
                    boxShadow: focused
                        ? ZenShadow.resting
                        : const <BoxShadow>[],
                  ),
                  alignment: Alignment.center,
                  child: (c == null || c.isEmpty)
                      ? (focused
                              ? Container(
                                  width: 1,
                                  height: 24,
                                  color: ZenAccent.primary,
                                )
                              : Text('·',
                                  style: ZenTypography.headlineMd
                                      .copyWith(color: ZenText.muted)))
                      : Text(c,
                          style: ZenTypography.headlineMd
                              .copyWith(color: ZenAccent.primary)),
                ),
              );
            }),
          ),
          // Hidden text field captures input.
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                maxLength: widget.length,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-HJ-KL-NP-Z2-9a-hj-kl-np-z]')),
                  _UpperCaseFormatter(),
                ],
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}