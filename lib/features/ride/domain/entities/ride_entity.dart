import 'package:equatable/equatable.dart';

enum RideType { offer, request }
enum RideStatus { open, booked, ongoing, completed, cancelled }
enum VehicleType { bike, car }

class RideLocation extends Equatable {
  final String name;
  final double latitude;
  final double longitude;

  const RideLocation({
    required this.name,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  @override
  List<Object?> get props => [name, latitude, longitude];
}

class RideEntity extends Equatable {
  final String id;
  final String hostId;
  final String hostName;
  final RideType type;
  final RideLocation from;
  final RideLocation to;
  final DateTime dateTime;
  final int seats;
  final double price;
  final RideStatus status;
  final VehicleType vehicleType;
  final String note;
  final double? hostLatitude;
  final double? hostLongitude;

  const RideEntity({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.type,
    required this.from,
    required this.to,
    required this.dateTime,
    required this.seats,
    required this.price,
    this.status = RideStatus.open,
    this.vehicleType = VehicleType.car,
    this.note = '',
    this.hostLatitude,
    this.hostLongitude,
  });

  @override
  List<Object?> get props => [
        id,
        hostId,
        type,
        from,
        to,
        dateTime,
        seats,
        price,
        status,
        vehicleType,
        note
      ];
}
