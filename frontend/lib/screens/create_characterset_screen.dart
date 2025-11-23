import 'package:flutter/material.dart';
import 'package:guess_who/widgets/retro_icon_button.dart';

class CreateCharactersetScreen extends StatefulWidget {
  const CreateCharactersetScreen({super.key});

  @override
  State<CreateCharactersetScreen> createState() =>
      _CreateCharactersetScreenState();
}

class _CreateCharactersetScreenState extends State<CreateCharactersetScreen> {
  bool _isExpanded = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create character set",
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.tertiary,
        actions: [
          RetroIconButton(
            onPressed: () {},
            margin: EdgeInsets.zero,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            borderWidth: 4,
            borderColor: Theme.of(context).colorScheme.tertiary,

            icon: Icons.add,
            iconSize: 30,
            iconColor: Theme.of(context).colorScheme.tertiary,

            tooltip: "Create draft",
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image(
              image: AssetImage("assets/main_menu.png"),
              fit: BoxFit.cover,
            ),
          ),

          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          }),
                        },
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: _isExpanded ? 0 : 0.5,
                              duration: const Duration(milliseconds: 150),
                              child: Icon(
                                Icons.expand_circle_down_outlined,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Text(
                              "Character Drafts",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: AnimatedContainer(
                    decoration: BoxDecoration(color: Colors.black38),
                    padding: EdgeInsets.all(4),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _isExpanded
                        ? MediaQuery.of(context).size.height * 0.5
                        : 0,
                    child: ClipRect(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: 20,
                        itemBuilder: (context, index) {
                          return Container(
                            color: Theme.of(context).colorScheme.tertiary,
                            padding: EdgeInsets.all(4),
                            margin: EdgeInsets.all(4),
                            child: Text(
                              "Item ${index.toString()}",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          );
                        },
                      ),
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
