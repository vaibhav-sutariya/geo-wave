import 'package:geolocator/geolocator.dart';

Future<Position> getUserCurrentLocation() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    await Geolocator.requestPermission();
  }

  return await Geolocator.getCurrentPosition();
}
