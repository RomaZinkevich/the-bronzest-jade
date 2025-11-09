import "package:flutter/material.dart";
import "package:guess_who/services/game_state_manager.dart";
import "package:guess_who/widgets/retro_button.dart";

class AskingPhaseUI extends StatelessWidget {
  final GameStateManager gameState;
  final bool isWaitingForAnswer;
  final TextEditingController questionController;
  final VoidCallback onSendQuestion;
  final VoidCallback onMakeGuess;

  const AskingPhaseUI({
    super.key,
    required this.gameState,
    required this.isWaitingForAnswer,
    required this.questionController,
    required this.onSendQuestion,
    required this.onMakeGuess,
  });

  @override
  Widget build(BuildContext context) {
    final canAct = gameState.isMyTurn && !isWaitingForAnswer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Question input
        if (canAct) ...[
          _buildQuestionInput(context),
          const SizedBox(height: 12),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canAct)
              RetroButton(
                text: "Make Guess",
                onPressed: onMakeGuess,
                fontSize: 16,
                iconSize: 24,
                iconAtEnd: false,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 50,
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.tertiary,
                icon: Icons.lightbulb_rounded,
              )
            else
              Expanded(child: _buildWaitingIndicator(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: questionController,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              decoration: InputDecoration(
                hintText: "Ask a question...",
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary.withAlpha(150),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ),
          IconButton(
            onPressed: onSendQuestion,
            icon: Icon(
              Icons.send_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingIndicator(BuildContext context) {
    return Container(
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
        isWaitingForAnswer
            ? "Waiting for opponent's answer..."
            : "Opponent's cooking...",
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
