import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';

class CharacterCard extends StatefulWidget {
  final Character character;
  final bool isFlipped;
  final bool isSelectionMode;
  final VoidCallback? onFlip;
  final VoidCallback? onSelect;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isFlipped,
    required this.isSelectionMode,
    this.onFlip,
    this.onSelect,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() async {
    if (!_controller.hasClients) return;

    while (mounted) {
      await _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      await _controller.animateTo(
        0,
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
      );

      await Future.delayed(const Duration(milliseconds: 500));
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
          widget.onFlip?.call();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: widget.isFlipped ? colorScheme.secondary : colorScheme.primary,
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
        child: AnimatedOpacity(
          opacity: widget.isSelectionMode
              ? (widget.isFlipped ? 1.0 : 0.3)
              : (widget.isFlipped ? 0.3 : 1.0),
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //* CHARACTER IMAGE
              AspectRatio(
                aspectRatio: 0.85,
                child: Container(
                  color: colorScheme.secondary,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    clipBehavior: Clip.hardEdge,
                    child: Image.network(
                      widget.character.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(error.toString());
                        return Container(
                          color: colorScheme.secondary.withAlpha(100),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colorScheme.secondary.withAlpha(100),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.tertiary,
                              ),
                              strokeCap: StrokeCap.round,
                              strokeWidth: 5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              //* CHARACTER NAME
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                child: SingleChildScrollView(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    widget.character.name,
                    style: TextStyle(fontSize: 14, color: colorScheme.tertiary),
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
