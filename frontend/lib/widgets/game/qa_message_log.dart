import "package:flutter/material.dart";

class QAMessageLog extends StatelessWidget {
  final List<Map<String, String>> qaHistory;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ScrollController scrollController;
  final String currentPlayerId;
  final String? myPlayerName;
  final String? opponentPlayerName;

  const QAMessageLog({
    super.key,
    required this.qaHistory,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.scrollController,
    required this.currentPlayerId,
    this.myPlayerName,
    this.opponentPlayerName,
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

  String _getDisplayName(String fullName, bool isMe) {
    return isMe ? "$fullName (You)" : "$fullName (Opponent)";
  }

  Widget _buildMessageList(BuildContext context) {
    return AnimatedSize(
      clipBehavior: Clip.none,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: isExpanded
          ? Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.builder(
                controller: scrollController,
                itemCount: qaHistory.length,
                itemBuilder: (context, index) {
                  final qa = qaHistory[index];

                  final isMyQuestion = qa["isMyQuestion"] == "true";
                  final isMyAnswer = qa["isMyAnswer"] == "true";

                  final questionerName = qa["questionerName"] ?? "Unknown";
                  final answererName = qa["answererName"] ?? "Unknown";

                  return QAMessageItem(
                    question: qa["question"]!,
                    answer: qa["answer"]!,
                    questionerDisplayName: _getDisplayName(
                      questionerName,
                      isMyQuestion,
                    ),
                    answererDisplayName: _getDisplayName(
                      answererName,
                      isMyAnswer,
                    ),
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
  final String questionerDisplayName;
  final String answererDisplayName;

  const QAMessageItem({
    super.key,
    required this.question,
    required this.answer,
    required this.questionerDisplayName,
    required this.answererDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: theme.secondary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: theme.tertiary),
              borderRadius: BorderRadius.circular(10),
              color: theme.secondary,
              boxShadow: [
                BoxShadow(
                  color: theme.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.question_mark_rounded,
                  size: 12,
                  color: theme.tertiary.withAlpha(200),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questionerDisplayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.tertiary.withAlpha(200),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        question,
                        style: TextStyle(fontSize: 14, color: theme.tertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_right_rounded,
                  size: 25,
                  color: theme.tertiary.withAlpha(200),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answererDisplayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.tertiary.withAlpha(200),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        answer,
                        style: TextStyle(fontSize: 14, color: theme.tertiary),
                      ),
                    ],
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
