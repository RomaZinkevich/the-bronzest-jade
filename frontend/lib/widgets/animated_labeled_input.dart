import 'package:flutter/material.dart';

class AnimatedLabeledInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const AnimatedLabeledInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  State<AnimatedLabeledInput> createState() => _AnimatedLabeledInputState();
}

class _AnimatedLabeledInputState extends State<AnimatedLabeledInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocusedOrFilled = false;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(_updateLabelState);
    widget.controller.addListener(_updateLabelState);
  }

  void _updateLabelState() {
    final bool newState =
        _focusNode.hasFocus || widget.controller.text.isNotEmpty;

    if (newState != _isFocusedOrFilled) {
      setState(() => _isFocusedOrFilled = newState);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_updateLabelState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(width: 4, color: theme.secondary),
              borderRadius: BorderRadius.circular(12),
              color: theme.tertiary,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.secondary,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: theme.secondary.withAlpha(140),
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: _isFocusedOrFilled ? -10 : 35,
            left: 14,
            child: AnimatedOpacity(
              opacity: _isFocusedOrFilled ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                color: theme.tertiary,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.secondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
