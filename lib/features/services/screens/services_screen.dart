import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'photocopy_service_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Services Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your business services',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Services Tabs
        Expanded(
          child: DefaultTabController(
            length: 1, // Only photocopy for now
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.print),
                      text: 'Photocopy Service',
                    ),
                    // Add more tabs here when you add more services
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      const PhotocopyServiceScreen(),
                      // Add more service screens here
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}