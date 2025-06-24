import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokemon App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PokemonPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});

  @override
  _PokemonPageState createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage>
    with SingleTickerProviderStateMixin {
  bool _isPokeballOpen = false;
  int _currentPokemonId = 1;
  final Random _random = Random();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePokeball() {
    setState(() {
      _isPokeballOpen = !_isPokeballOpen;
      if (_isPokeballOpen) {
        // Get a random Pokemon ID between 1 and 151 (Gen 1)
        _currentPokemonId = _random.nextInt(151) + 1;
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokemon App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _togglePokeball,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pokeball
                    Image.network(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    // Pokemon (shows when pokeball is open)
                    AnimatedOpacity(
                      opacity: _isPokeballOpen ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: ScaleTransition(
                        scale: _animation,
                        child: Image.network(
                          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$_currentPokemonId.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isPokeballOpen
                  ? 'Pokemon #$_currentPokemonId appeared!'
                  : 'Tap the Pokeball!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_isPokeballOpen)
              ElevatedButton(
                onPressed: _togglePokeball,
                child: const Text('Return Pokemon'),
              ),
          ],
        ),
      ),
    );
  }
}
