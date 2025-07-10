import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import 'sample_item.dart';

/// Displays detailed information about a SampleItem.
class SampleItemDetailsView extends StatelessWidget {
  const SampleItemDetailsView({super.key, this.item});

  static const routeName = AppRoutes.sampleItemDetails;

  final SampleItem? item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
      ),
      body: const Center(
        child: Text('More Information Here'),
      ),
    );
  }
}
