import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/services/game_state_manager.dart';
import 'package:guess_who/widgets/character_card.dart';

class GameBoard extends StatelessWidget {
  final GameStateManager gameState;
  final bool isSelectionMode;
  final bool isCharacterNameRevealed;
  final VoidCallback? onToggleCharacterNameReveal;
  final void Function(Character character)? onFlip;
  final void Function(Character character)? onSelect;

  const GameBoard({
    super.key,
    required this.gameState,
    this.isSelectionMode = false,
    this.isCharacterNameRevealed = false,
    this.onToggleCharacterNameReveal,
    this.onFlip,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final currentFlippedCards = gameState.getCurrentFlippedCards();
    final selectedCharacter = gameState.getCurrentPlayerCharacter();
    final remainingCount = gameState.getRemainingCount();
    final colorScheme = Theme.of(context).colorScheme;

    final playerName = gameState.gameMode == GameMode.online
        ? "You"
        : gameState.getCurrentPlayerName();

    return Column(
      children: [
        //* TOP INFO BAR
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //* Reveal chosen character toggle
              Expanded(
                child: GestureDetector(
                  onTap: onToggleCharacterNameReveal,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCharacterNameRevealed
                          ? colorScheme.tertiary.withAlpha(50)
                          : colorScheme.tertiary.withAlpha(20),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: colorScheme.tertiary.withAlpha(100),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCharacterNameRevealed)
                          Flexible(
                            child: Text(
                              "$playerName chose ${selectedCharacter?.name ?? "Something Strange"}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.tertiary,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else ...[
                          Icon(
                            Icons.visibility_off,
                            size: 14,
                            color: colorScheme.tertiary.withAlpha(200),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Reveal chosen character",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.tertiary.withAlpha(200),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              //* Remaining count
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.tertiary, width: 1),
                ),
                child: Text(
                  "$remainingCount left",
                  style: TextStyle(color: colorScheme.tertiary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        //* MAIN BOARD
        Expanded(
          child: Container(
            color: colorScheme.tertiary,
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: gameState.allCharacters.length,
              itemBuilder: (context, index) {
                final character = gameState.allCharacters[index];
                final isFlipped = currentFlippedCards.contains(character.id);

                return CharacterCard(
                  character: character,
                  isFlipped: isFlipped,
                  isSelectionMode: isSelectionMode,
                  onFlip: () => onFlip?.call(character),
                  onSelect: () => onSelect?.call(character),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
