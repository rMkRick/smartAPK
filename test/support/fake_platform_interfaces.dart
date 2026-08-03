// Fakes reutilizables de las platform interfaces de geolocator e
// image_picker: al extender la clase abstracta (no "implements"), el
// constructor base ya registra el token de verificación de
// PlatformInterface, así que basta con sobreescribir los métodos que
// nuestros Controllers realmente usan para poder correr sus tests sin un
// dispositivo/emulador real.
import 'dart:async';

import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Position? currentPosition = Position(
    latitude: -13.5319,
    longitude: -71.9675,
    timestamp: DateTime(2026, 1, 1),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  final StreamController<Position> _positionController = StreamController<Position>.broadcast();

  void emitPosition(Position position) => _positionController.add(position);

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    return currentPosition!;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return _positionController.stream;
  }
}

class FakeImagePickerPlatform extends ImagePickerPlatform {
  /// Ruta que "elige" el usuario; null simula que canceló la selección.
  String? nextImagePath;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return nextImagePath == null ? null : XFile(nextImagePath!);
  }
}
