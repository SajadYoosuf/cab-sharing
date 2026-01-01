import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../ride/presentation/providers/ride_provider.dart';
import '../../../ride/domain/entities/ride_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final rideProvider = Provider.of<RideProvider>(context, listen: false);
        
        rideProvider.loadAvailableRides();
        if (authProvider.currentUser != null) {
          rideProvider.loadMyRides(authProvider.currentUser!.id);
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('EcoRide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.pushNamed(context, '/admin');
            },
          ),
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.red),
            onPressed: () {
               showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('SOS ALERT'),
                  content: const Text('Use this feature only in emergencies.\n\nSimulating sending help request...'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Signal Sent!')));
                      },
                      child: const Text('CONFIRM SOS'),
                    ),
                  ],
                ),
               );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Hello, ${user?.name ?? "User"}! 👋',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Eco Stats Card
            _buildEcoCard(),
            const SizedBox(height: 24),

            // Offer/Request Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Find a Ride',
                    Icons.search_rounded,
                    AppColors.primary,
                    () {
                      Navigator.pushNamed(context, '/find_ride');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Offer a Ride',
                    Icons.directions_car,
                    AppColors.secondary,
                    () {
                      Navigator.pushNamed(context, '/create_ride');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent/Available Rides
            Text(
              'Available Rides Nearby',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Consumer<RideProvider>(
              builder: (context, rideProvider, _) {
                if (rideProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (rideProvider.availableRides.isEmpty) {
                  return const Center(child: Text('No rides available right now.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rideProvider.availableRides.length,
                  itemBuilder: (context, index) {
                    final ride = rideProvider.availableRides[index];
                    return _buildRideCard(ride);
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEcoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total CO₂ Saved',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Consumer<RideProvider>(
                builder: (context, provider, _) {
                  return Text(
                    '${provider.totalCo2Saved.toStringAsFixed(1)} kg',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(RideEntity ride) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                 CircleAvatar(
                   backgroundColor: Colors.grey.shade200,
                   child: const Icon(Icons.person, color: Colors.grey),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         ride.hostName,
                         style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                       Row(
                         children: [
                           const Icon(Icons.star, size: 14, color: Colors.amber),
                           const Text(' 4.8', style: TextStyle(fontSize: 12)),
                         ],
                       ),
                     ],
                   ),
                 ),
                 Text(
                   '\$${ride.price}',
                   style: const TextStyle(
                     fontWeight: FontWeight.bold,
                     fontSize: 18,
                     color: AppColors.primary,
                   ),
                 ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, size: 10, color: AppColors.primary),
                    Container(
                      height: 20,
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                    const Icon(Icons.location_on, size: 12, color: AppColors.secondary),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.from.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Text(ride.to.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${ride.dateTime.hour}:${ride.dateTime.minute}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${ride.seats} seats'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
