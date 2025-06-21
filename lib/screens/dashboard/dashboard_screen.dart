import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/outlet_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_profile.dart';
import '../../models/outlet_model.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final _authService = AuthService();
  final _outletService = OutletService();

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder<UserProfile>(
                future: _authService.getCurrentUserProfile(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.outletId != null) {
                    return FutureBuilder<Outlet>(
                      future: _outletService
                          .getOutletById(snapshot.data!.outletId!),
                      builder: (context, outletSnapshot) {
                        if (outletSnapshot.hasData) {
                          return Text(
                            'Outlet: ${outletSnapshot.data!.name}',
                            style: const TextStyle(fontSize: 14),
                          );
                        }
                        return const Text('Loading outlet...',
                            style: TextStyle(fontSize: 14));
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _authService.getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final userProfile = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${userProfile.fullName ?? 'Sales Representative'}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _QuickActionCard(
                        icon: Icons.store,
                        title: 'Outlets',
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.outlets);
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.inventory,
                        title: 'Stock',
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.stock);
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.point_of_sale,
                        title: 'Sales',
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.sales);
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.analytics,
                        title: 'Reports',
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.reports);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
