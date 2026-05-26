import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/active_trip_provider.dart';

class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(activeTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trip'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tripState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tripState.error!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              
              _buildStatusCard(tripState),
              const SizedBox(height: 24),
              _buildLocationDetails(tripState),
              const Spacer(),
              _buildControls(ref, tripState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ActiveTripState state) {
    final isTracking = state.isTracking;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isTracking ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTracking ? Colors.green.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isTracking ? Icons.gps_fixed : Icons.gps_off,
            size: 48,
            color: isTracking ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isTracking ? 'Tracking Active' : 'Not Tracking',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isTracking ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
          if (isTracking && state.routeId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Route: ${state.routeId}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationDetails(ActiveTripState state) {
    if (!state.isTracking || state.lastPosition == null) {
      return const SizedBox.shrink();
    }

    final pos = state.lastPosition!;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(Icons.speed, 'Speed', '${(pos.speed * 3.6).toStringAsFixed(1)} km/h'),
            const Divider(),
            _buildDetailRow(Icons.explore, 'Heading', '${pos.heading.toStringAsFixed(1)}°'),
            const Divider(),
            _buildDetailRow(Icons.location_on, 'Lat/Lng', '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'),
            const Divider(),
            _buildDetailRow(Icons.my_location, 'Accuracy', '±${pos.accuracy.toStringAsFixed(1)} m'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 16)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(WidgetRef ref, ActiveTripState state) {
    if (state.isTracking) {
      return ElevatedButton(
        onPressed: () {
          ref.read(activeTripProvider.notifier).stopTrip();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('END TRIP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
    } else {
      return ElevatedButton(
        onPressed: () {
          // Dummy data for testing. In a real scenario, these would come from
          // a previous "Select Route" screen.
          ref.read(activeTripProvider.notifier).startTrip(
                tripId: 'trip-${DateTime.now().millisecondsSinceEpoch}',
                busId: 'BUS-02',
                routeId: 'route-2',
              );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('START TRIP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
    }
  }
}
