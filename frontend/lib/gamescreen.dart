import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _counter = 0;
  bool _buttonDisabled = true;
  final TextEditingController _controller = TextEditingController(text: "0");

  void _incrementCounter() {
    setState(() {
      _counter++;
      _buttonDisabled = false;
      _controller.text = _counter.toString();
    });
  }

  void _decrementCounter() {
    setState(() {
      if (_counter > 0) {
        _counter--;
        _controller.text = _counter.toString();
      }

      if (_counter == 0) {
        _buttonDisabled = true;
      }
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
      _buttonDisabled = true;
      _controller.text = "0";
    });
  }

  void _onInputChanged(String value) {
    int parsedValue = int.tryParse(value) ?? 0;

    setState(() {
      _counter = parsedValue;
      _buttonDisabled = _counter == 0;
      _controller.text = parsedValue == 0 ? "0" : parsedValue.toString();
    });
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset Counter"),
          content: const Text("Are you sure you want to reset the counter?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetCounter();
              },
              child: Text(
                "Reset",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Game Screen"),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: const Image(
              image: AssetImage("assets/bg.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _buttonDisabled ? null : _decrementCounter,
                  tooltip: 'Decrement',
                  heroTag: 'decrement',
                  backgroundColor: !_buttonDisabled
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.38),
                  child: const Icon(Icons.remove),
                ),

                const SizedBox(width: 10),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Clicked',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                    SizedBox(
                      width: 75,
                      height: 75,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 3.0,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        onChanged: _onInputChanged,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    Text(
                      _counter > 1 ? "times" : "time",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 10),

                FloatingActionButton(
                  onPressed: _incrementCounter,
                  tooltip: 'Increment',
                  heroTag: 'increment',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _confirmReset,
        tooltip: 'Reset',
        heroTag: 'reset',
        child: const Icon(Icons.restart_alt_rounded),
      ),
    );
  }
}
