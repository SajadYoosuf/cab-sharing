import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'admin_ride_detail_page.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Financial Reports', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('rides').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          }

          final rides = snapshot.data?.docs ?? [];
          return _buildDashboard(rides);
        },
      ),
    );
  }

  Widget _buildDashboard(List<QueryDocumentSnapshot> rides) {
    final now = DateTime.now();
    final currentMonthRides = rides.where((doc) {
      final date = (doc['dateTime'] as Timestamp).toDate();
      return date.month == now.month && date.year == now.year;
    }).toList();

    double totalRevenue = 0;
    for (var doc in currentMonthRides) {
      totalRevenue += (doc['price'] ?? 0).toDouble();
    }
    final weeklyRevenue = _getWeeklyRevenue(currentMonthRides);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('MMMM yyyy').format(now)} Overview',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Colors.green, Icons.attach_money)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Total Rides', '${currentMonthRides.length}', Colors.blue, Icons.directions_car)),
            ],
          ),
          const SizedBox(height: 32),
          Text('Revenue Analytics', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (currentMonthRides.isEmpty ? 1000 : (weeklyRevenue.reduce((a, b) => a > b ? a : b) + 500)).toDouble(), // Fixed: Dynamic max based on revenue
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.round()}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'W${val.toInt() + 1}',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide left labels for cleaner look
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: _generateWeeklyData(currentMonthRides),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Recent Transactions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...currentMonthRides.take(10).map((ride) => _buildTransactionTile(ride)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['dateTime'] as Timestamp).toDate();
    final status = data['status'] ?? 'open';
    
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminRideDetailPage(rideData: data, rideId: doc.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.payment_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['hostName'] ?? 'Unknown Host', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(DateFormat('MMM d, h:mm a').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${data['price'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                Text(
                  status.toString().toUpperCase(), 
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: status == 'completed' ? Colors.green : Colors.orange
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Need to bring weeklyRevenue to scope or recalculate
  List<double> _getWeeklyRevenue(List<QueryDocumentSnapshot> rides) {
    final weeklyRevenue = List.filled(5, 0.0);
    for (var doc in rides) {
      final date = (doc['dateTime'] as Timestamp).toDate();
      final weekIndex = (date.day - 1) ~/ 7;
      if (weekIndex < 5) weeklyRevenue[weekIndex] += (doc['price'] ?? 0).toDouble();
    }
    return weeklyRevenue;
  }

  List<BarChartGroupData> _generateWeeklyData(List<QueryDocumentSnapshot> rides) {
    // Determine the week of the month for each ride and sum prices
    final weeklyRevenue = List.filled(5, 0.0); // Up to 5 weeks in a month

    for (var doc in rides) {
       final date = (doc['dateTime'] as Timestamp).toDate();
       // Simple week calculation: (day - 1) / 7
       final weekIndex = (date.day - 1) ~/ 7;
       if (weekIndex < 5) {
         weeklyRevenue[weekIndex] += (doc['price'] ?? 0).toDouble();
       }
    }

    return List.generate(5, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyRevenue[index] == 0 ? 10 : weeklyRevenue[index], // Min height for empty bars
            color: AppColors.primary,
            width: 22,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: (weeklyRevenue.reduce((a, b) => a > b ? a : b) + 500), // Max for background
              color: Colors.grey.shade100,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
