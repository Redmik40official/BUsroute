class RouteModel {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final String busId;
  final String color;
  final List<RouteStopModel> stops;
  final bool isActive;

  RouteModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.busId,
    required this.color,
    required this.stops,
    this.isActive = false,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      description: json['description'] as String,
      busId: json['busId'] as String,
      color: json['color'] as String,
      stops: (json['stops'] as List<dynamic>)
          .map((e) => RouteStopModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

class RouteStopModel {
  final String name;
  final double lat;
  final double lng;
  final int order;

  RouteStopModel({
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      order: json['order'] as int,
    );
  }
}
