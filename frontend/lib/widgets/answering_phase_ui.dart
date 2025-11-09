import "package:flutter/material.dart";
import "package:guess_who/widgets/retro_button.dart";

class AnsweringPhaseUI extends StatelessWidget {
  final bool isMyTurn;
  final String? currentQuestion;
  final Function(String) onSendAnswer;

  const AnsweringPhaseUI({
    super.key,
    required this.isMyTurn,
    required this.currentQuestion,
    required this.onSendAnswer,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMyTurn && currentQuestion != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuestionDisplay(context),
          const SizedBox(height: 12),
          _buildAnswerButtons(context),
        ],
      );
    }

    return _buildWaitingIndicator(context);
  }

  Widget _buildQuestionDisplay(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.question_mark_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Opponent asks:",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentQuestion!,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RetroButton(
            text: "Yes",
            fontSize: 18,
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.tertiary,
            icon: Icons.check_rounded,
            iconSize: 25,
            iconSpacing: 14,

            iconAtEnd: false,
            onPressed: () => onSendAnswer("Yes"),
          ),
        ),
        const SizedBox(width: 26),
        Expanded(
          child: RetroButton(
            text: "No",
            fontSize: 18,
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.tertiary,
            icon: Icons.close_rounded,
            iconSize: 27,
            iconSpacing: 14,
            iconAtEnd: false,
            onPressed: () => onSendAnswer("No"),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingIndicator(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary,
          width: 2,
        ),
      ),
      child: Text(
        "Opponent is thinking...",
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
