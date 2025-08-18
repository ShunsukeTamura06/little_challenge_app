
import 'package:flutter/material.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ストック'),
      ),
      body: const Center(
        child: Text('ストック画面'),
      ),
    );
  }
}
