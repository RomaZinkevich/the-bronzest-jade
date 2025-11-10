import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 500;

        // On mobile or narrow screens, use full screen
        if (!isWideScreen) {
          return child;
        }

        // On wide screens (desktop/tablet), show phone frame
        return Scaffold(
          backgroundColor: const Color(0xFF1a1a1a),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0a0a0a),
                  const Color(0xFF1a1a1a),
                  const Color(0xFF2a2a2a),
                ],
              ),
            ),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500, // Max width for the phone
                  maxHeight: constraints.maxHeight * 0.95,
                ),
                child: Stack(
                  children: [
                    // Phone shadow
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Phone frame with app inside
                    Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: const Color(0xFF3a3a3a),
                          width: 8,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(42),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
