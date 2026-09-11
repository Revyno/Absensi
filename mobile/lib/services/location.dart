import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  LocationService._();
  static final LocationService i = LocationService._();

  static const _kLat = 'office_lat';
  static const _kLng = 'office_lng';
  static const _kRadius = 'office_radius';

  static const defLat = -6.2088;
  static const defLng = 106.8228;
  static const defRadius = 150.0;

  double _lat = defLat, _lng = defLng, _radius = defRadius;

  double get radius => _radius;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _lat = p.getDouble(_kLat) ?? defLat;
    _lng = p.getDouble(_kLng) ?? defLng;
    _radius = p.getDouble(_kRadius) ?? defRadius;
  }

  Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Layanan lokasi mati. Nyalakan GPS.';
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak.';
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  double distanceTo(Position p) =>
      Geolocator.distanceBetween(_lat, _lng, p.latitude, p.longitude);

  bool inRadius(Position p) => distanceTo(p) <= _radius;

  Future<void> setOffice(double lat, double lng) async {
    _lat = lat;
    _lng = lng;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kLat, lat);
    await p.setDouble(_kLng, lng);
  }
}
