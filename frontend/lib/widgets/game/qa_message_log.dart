import "package:flutter/material.dart";

class QAMessageLog extends StatelessWidget {
  final List<Map<String, String>> qaHistory;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ScrollController scrollController;
  final String currentPlayerId;

  const QAMessageLog({
    super.key,
    required this.qaHistory,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.scrollController,
    required this.currentPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    if (qaHistory.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.tertiary,
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildHeader(context), _buildMessageList(context)],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: onToggleExpanded,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.tertiary,
              width: 2,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.message_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Q&A History (${qaHistory.length})",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.expand_circle_down_rounded,
                size: 25,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return AnimatedSize(
      clipBehavior: Clip.none,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: isExpanded
          ? Container(
              constraints: BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: qaHistory.length,
                itemBuilder: (context, index) {
                  final qa = qaHistory[index];
                  final currentPlayerIdPrefix = currentPlayerId.substring(0, 6);

                  return QAMessageItem(
                    question: qa["question"]!,
                    answer: qa["answer"]!,
                    isMyQuestion: qa["questionerId"] == currentPlayerIdPrefix,
                    isMyAnswer: qa["answererId"] == currentPlayerIdPrefix,
                  );
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class QAMessageItem extends StatelessWidget {
  final String question;
  final String answer;
  final bool isMyQuestion;
  final bool isMyAnswer;

  const QAMessageItem({
    super.key,
    required this.question,
    required this.answer,
    required this.isMyQuestion,
    required this.isMyAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: Theme.of(context).colorScheme.primary,
          ),
          top: BorderSide(
            width: 1,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.question_mark_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    children: [
                      TextSpan(text: "${isMyQuestion ? "You" : "Opponent"}: "),
                      TextSpan(
                        text: question,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_right_rounded,
                  size: 30,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      children: [
                        TextSpan(text: "${isMyAnswer ? "You" : "Opponent"}: "),
                        TextSpan(
                          text: answer,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
