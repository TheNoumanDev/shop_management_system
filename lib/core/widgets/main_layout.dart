import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../constants/routes.dart';
import '../constants/app_constants.dart';
import '../../features/auth/providers/auth_provider.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Always visible sidebar
          SizedBox(
            width: 280,
            child: _buildSidebar(context),
          ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _getPageTitle(currentRoute),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          
          // Profile menu
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              return PopupMenuButton(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
                itemBuilder: (context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.person_outline),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                    onTap: () => context.go(AppRoutes.profile),
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.settings_outlined),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                    onTap: () => context.go(AppRoutes.settings),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                    onTap: () => _handleSignOut(context),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.store,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Business Management',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: AppRoutes.dashboard,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory',
                  route: AppRoutes.inventory,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.point_of_sale,
                  title: 'Sales',
                  route: AppRoutes.sales,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.build_outlined,
                  title: 'Services',
                  route: AppRoutes.services,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.account_balance,
                  title: 'Udhar',
                  route: AppRoutes.udhar,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Expenses',
                  route: AppRoutes.expenses,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Reports',
                  route: AppRoutes.reports,
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  route: AppRoutes.settings,
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      child: Text(
                        (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey[800],
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.8),
      onTap: () {
        context.go(route);
      },
    );
  }

  String _getPageTitle(String route) {
    switch (route) {
      case AppRoutes.dashboard:
        return 'Dashboard';
      case AppRoutes.inventory:
        return 'Inventory';
      case AppRoutes.sales:
        return 'Sales';
      case AppRoutes.services:
        return 'Services';
      case AppRoutes.udhar:
        return 'Udhar';
      case AppRoutes.expenses:
        return 'Expenses';
      case AppRoutes.reports:
        return 'Reports';
      case AppRoutes.settings:
        return 'Settings';
      default:
        return AppConstants.appName;
    }
  }

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
              context.go(AppRoutes.login);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}