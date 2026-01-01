import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/ride_entity.dart';
import '../providers/ride_provider.dart';
import 'package:intl/intl.dart';
import 'ride_detail_page.dart';

class FindRidePage extends StatefulWidget {
  const FindRidePage({super.key});

  @override
  State<FindRidePage> createState() => _FindRidePageState();
}

class _FindRidePageState extends State<FindRidePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RideProvider>(context, listen: false).loadAvailableRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Ride'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<RideProvider>(context, listen: false).loadAvailableRides();
            },
          ),
        ],
      ),
      body: Consumer<RideProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.availableRides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No rides available at the moment.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.availableRides.length,
            itemBuilder: (context, index) {
              final ride = provider.availableRides[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ride.type == RideType.offer
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Icon(
                      ride.type == RideType.offer
                          ? Icons.directions_car
                          : Icons.hail,
                      color: ride.type == RideType.offer
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(ride.from.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_right_alt, size: 16),
                      ),
                      Text(ride.to.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(DateFormat.yMMMd().add_jm().format(ride.dateTime)),
                      Text('By: ${ride.hostName} • ${ride.seats} seats available'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${ride.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Text('per seat', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                  onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RideDetailPage(
                            ride: ride,
                          ),
                        ),
                      );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create_ride');
        },
        label: const Text('Offer / Request'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
