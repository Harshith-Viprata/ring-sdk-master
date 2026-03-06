import 'package:flutter/material.dart';

/// Placeholder health metrics page.
class MetricsPage extends StatelessWidget {
  const MetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Metrics')),
      body: const Center(child: Text('Metrics – coming soon')),
    );
  }
}
