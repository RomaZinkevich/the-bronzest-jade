import 'package:flutter/material.dart';
import 'package:guess_who/widgets/common/retro_icon_button.dart';

class InnerShadowInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  final String iconPath;
  final String hintText;
  final String submitTooltip;
  final bool showIcon;
  final bool disableShadows;

  final double? width;

  const InnerShadowInput({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.hintText = "Set name...",
    this.submitTooltip = "Submit",
    this.iconPath = "assets/icons/join_submit.png",
    this.showIcon = true,
    this.disableShadows = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalMargin = constraints.maxWidth > 600
            ? constraints.maxWidth * 0.1
            : 40.0;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: width ?? horizontalMargin),
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(100),
            color: Theme.of(context).colorScheme.tertiary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 6, right: showIcon ? 0 : 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: disableShadows
                        ? Theme.of(context).colorScheme.secondary
                        : null,
                    boxShadow: disableShadows
                        ? null
                        : [
                            const BoxShadow(color: Color(0xFF5B7B76)),
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary,
                              blurRadius: 4,
                              spreadRadius: -2,
                            ),
                          ],
                  ),
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    cursorColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : null,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiary.withAlpha(200),
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              if (showIcon) ...[
                const SizedBox(width: 4),

                // Keep your existing button widget
                RetroIconButton(
                  onPressed: onSubmit,
                  tooltip: "Submit",
                  imagePath: iconPath,
                  iconSize: 64,
                  padding: 0,
                  margin: const EdgeInsets.only(top: 2, bottom: 2, right: 4),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  borderWidth: 0,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
