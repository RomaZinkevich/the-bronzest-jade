import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';

class CharacterCard extends StatefulWidget {
  final Character character;
  final bool isFlipped;
  final bool isSelectionMode;
  final bool doesFlipAnimation;
  final VoidCallback? onFlip;
  final VoidCallback? onSelect;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isFlipped,
    required this.isSelectionMode,
    this.onFlip,
    this.onSelect,
    this.doesFlipAnimation = false,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    );

    if (widget.isFlipped) {
      _flipController.value = 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() async {
    if (!_scrollController.hasClients) return;

    // Wait for the first frame to ensure layout is complete
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted || !_scrollController.hasClients) return;

    if (_scrollController.position.maxScrollExtent == 0) {
      return;
    }

    while (mounted) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
        );
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CharacterCard old) {
    super.didUpdateWidget(old);

    if (widget.isFlipped != old.isFlipped) {
      widget.isFlipped ? _flipController.forward() : _flipController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (widget.isSelectionMode) {
          widget.onSelect?.call();
        } else {
          if (widget.doesFlipAnimation) {
            widget.isFlipped
                ? _flipController.reverse()
                : _flipController.forward();
          }
          widget.onFlip?.call();
        }
      },
      child: widget.doesFlipAnimation
          ? AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * pi;
                final isBack = angle > pi / 2;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: isBack
                      ? _buildCardBack(colorScheme)
                      : _buildCard(colorScheme),
                );
              },
            )
          : _buildCard(colorScheme),
    );
  }

  Widget _buildCardBack(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colorScheme.secondary, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          'assets/guesswhoiconbg.png',
          fit: BoxFit.cover,
          colorBlendMode: BlendMode.overlay,
          color: Colors.black12,
        ),
      ),
    );
  }

  Widget _buildCard(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: widget.isFlipped ? colorScheme.secondary : colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.secondary, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: AnimatedOpacity(
        opacity: widget.isSelectionMode
            ? (widget.isFlipped ? 1.0 : 0.3)
            : (widget.isFlipped ? 0.3 : 1.0),
        duration: const Duration(milliseconds: 150),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 0.85,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox.expand(
                  child: Image.network(
                    widget.character.imageUrl,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                          strokeCap: StrokeCap.round,
                          strokeWidth: 5,
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => Container(
                      color: colorScheme.secondary.withAlpha(
                        (255 * 0.3).toInt(),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    widget.character.name,
                    style: TextStyle(fontSize: 14, color: colorScheme.tertiary),
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
