import 'package:geolocator/geolocator.dart';

class StationCoord {
  final String name;
  final double lat;
  final double lng;

  const StationCoord({
    required this.name,
    required this.lat,
    required this.lng,
  });

  double distanceTo(double userLat, double userLng) {
    return Geolocator.distanceBetween(lat, lng, userLat, userLng);
  }
}

const List<String> blueLineStations = [
  'Wimco Nagar Depot Metro', 'Wimco Nagar Metro', 'Thiruvottriyur Metro',
  'Thiruvottriyur Theradi Metro', 'Kaladipet Metro', 'Tollgate Metro',
  'New Washermenpet Metro', 'Thondiarpet Metro', 'Sri Theagaraya College Metro',
  'Washermenpet Metro', 'Mannadi', 'Highcourt', 'Chennai Central Metro',
  'Government Estate', 'LIC', 'Thousand Lights', 'AG-DMS', 'Teynampet',
  'Nandanam', 'Saidapet Metro', 'Little Mount', 'Guindy',
  'Arignar Anna Alandur Metro', 'OTA-Nanganallur Road', 'Meenambakkam',
  'Chennai International Airport',
];

const List<String> greenLineStations = [
  'Chennai Central Metro', 'Egmore', 'Nehru Park', 'Kilpauk',
  'Pachaiyappa\'s College', 'Shenoy Nagar', 'Anna Nagar East',
  'Anna Nagar Tower', 'Thirumangalam', 'Koyambedu', 'CMBT Metro',
  'Arumbakkam', 'Vadapalani', 'Ashok Nagar', 'Ekkattuthangal',
  'Arignar Anna Alandur Metro', 'St. Thomas Mount Metro',
];

const List<String> interchangeStations = [
  'Chennai Central Metro',
  'Arignar Anna Alandur Metro',
];

const List<StationCoord> allStationCoords = [
  StationCoord(name: 'Wimco Nagar Depot Metro', lat: 13.1462, lng: 80.3012),
  StationCoord(name: 'Wimco Nagar Metro', lat: 13.1392, lng: 80.2977),
  StationCoord(name: 'Thiruvottriyur Metro', lat: 13.1311, lng: 80.2950),
  StationCoord(name: 'Thiruvottriyur Theradi Metro', lat: 13.1235, lng: 80.2907),
  StationCoord(name: 'Kaladipet Metro', lat: 13.1178, lng: 80.2876),
  StationCoord(name: 'Tollgate Metro', lat: 13.1089, lng: 80.2836),
  StationCoord(name: 'New Washermenpet Metro', lat: 13.1018, lng: 80.2801),
  StationCoord(name: 'Thondiarpet Metro', lat: 13.0952, lng: 80.2762),
  StationCoord(name: 'Sri Theagaraya College Metro', lat: 13.0889, lng: 80.2723),
  StationCoord(name: 'Washermenpet Metro', lat: 13.0831, lng: 80.2756),
  StationCoord(name: 'Mannadi', lat: 13.0762, lng: 80.2736),
  StationCoord(name: 'Highcourt', lat: 13.0721, lng: 80.2784),
  StationCoord(name: 'Chennai Central Metro', lat: 13.0827, lng: 80.2707),
  StationCoord(name: 'Government Estate', lat: 13.0672, lng: 80.2729),
  StationCoord(name: 'LIC', lat: 13.0634, lng: 80.2697),
  StationCoord(name: 'Thousand Lights', lat: 13.0589, lng: 80.2612),
  StationCoord(name: 'AG-DMS', lat: 13.0542, lng: 80.2578),
  StationCoord(name: 'Teynampet', lat: 13.0489, lng: 80.2534),
  StationCoord(name: 'Nandanam', lat: 13.0421, lng: 80.2498),
  StationCoord(name: 'Saidapet Metro', lat: 13.0348, lng: 80.2234),
  StationCoord(name: 'Little Mount', lat: 13.0271, lng: 80.2201),
  StationCoord(name: 'Guindy', lat: 13.0067, lng: 80.2206),
  StationCoord(name: 'Arignar Anna Alandur Metro', lat: 12.9987, lng: 80.2012),
  StationCoord(name: 'OTA-Nanganallur Road', lat: 12.9912, lng: 80.1934),
  StationCoord(name: 'Meenambakkam', lat: 12.9823, lng: 80.1689),
  StationCoord(name: 'Chennai International Airport', lat: 12.9941, lng: 80.1709),
  StationCoord(name: 'Egmore', lat: 13.0784, lng: 80.2612),
  StationCoord(name: 'Nehru Park', lat: 13.0756, lng: 80.2534),
  StationCoord(name: 'Kilpauk', lat: 13.0823, lng: 80.2423),
  StationCoord(name: 'Pachaiyappa\'s College', lat: 13.0889, lng: 80.2378),
  StationCoord(name: 'Shenoy Nagar', lat: 13.0934, lng: 80.2312),
  StationCoord(name: 'Anna Nagar East', lat: 13.0923, lng: 80.2198),
  StationCoord(name: 'Anna Nagar Tower', lat: 13.0889, lng: 80.2089),
  StationCoord(name: 'Thirumangalam', lat: 13.0856, lng: 80.1978),
  StationCoord(name: 'Koyambedu', lat: 13.0712, lng: 80.1934),
  StationCoord(name: 'CMBT Metro', lat: 13.0689, lng: 80.1867),
  StationCoord(name: 'Arumbakkam', lat: 13.0634, lng: 80.1823),
  StationCoord(name: 'Vadapalani', lat: 13.0523, lng: 80.1756),
  StationCoord(name: 'Ashok Nagar', lat: 13.0434, lng: 80.1712),
  StationCoord(name: 'Ekkattuthangal', lat: 13.0267, lng: 80.1923),
  StationCoord(name: 'St. Thomas Mount Metro', lat: 13.0012, lng: 80.1934),
];

StationCoord? getStationCoord(String name) {
  try {
    return allStationCoords.firstWhere((s) => s.name == name);
  } catch (_) {
    return null;
  }
}

double getAlertRadius(String stationName, String destStation, String? interchange) {
  if (stationName == destStation) return 600;
  if (stationName == interchange) return 400;
  return 300;
}