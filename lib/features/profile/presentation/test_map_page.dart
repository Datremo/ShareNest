import 'package:flutter/material.dart';
import '../../../core/maps/sharenest_map.dart';

class TestMapPage extends StatelessWidget {
  const TestMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenFreeMap Test', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: const ShareNestMap(
        mode: MapMode.explore,
      ),
    );
  }
}
