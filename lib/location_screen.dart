import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_map/flutter_map.dart';
import 'details_screen.dart';
import 'routes_screen.dart';

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String? _currentAddress;
  Position? _currentPosition;
  double _previousLatitude = 0.0;
  double _previousLongitude = 0.0;

  List<Map<String, dynamic>> items = []; //list of items

  // Fetch content from the json file
  Future<void> readJson() async {
    final String response = await rootBundle.loadString('assets/data1.json');
    final data = await json.decode(response);
    final List<dynamic> jsonData = data['items'];
    final List<Map<String, dynamic>> itemList = [];

    for (var item in jsonData) {
      final latitude = double.tryParse(item['latitude']);
      final longitude = double.tryParse(item['longitude']);

      if (latitude != null && longitude != null) {
        item['latitude'] = latitude;
        item['longitude'] = longitude;
        itemList.add(item);
      }
    }

    setState(() {
      items = itemList;
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    readJson();
  }

  Future<bool> _handleLocationPermission() async {
    //add to android/app/src/main/AndroidManifest.xml: '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>'
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        _getAddressFromLatLng(_currentPosition!);
        _previousLatitude = position.latitude;
        _previousLongitude = position.longitude;
      });
    }).catchError((e) {
      debugPrint(e.toString());
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e.toString());
    });
  }

  bool _hasPositionChanged(double latitude, double longitude) {
    final distance = Geolocator.distanceBetween(
      _previousLatitude,
      _previousLongitude,
      latitude,
      longitude,
    );

    return distance >=
        5; // Check if distance is greater than or equal to 5 meters
  }

  Future<void> _refreshLocation() async {
    await _getCurrentPosition();
  }

  Future<void> _showPinInfoDialog(int index) async {
    if (index == -1) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(title: Text("Your location"));
        },
      );
    } else {
      final item = items[index];
      final List<String> photos = await _fetchPhotos(item['id'].toString());
      //final List<dynamic> reviews = await _fetchReviews(item['id'].toString());

      item['photos'] = photos;
      //item['reviews'] = reviews;

      // ignore: use_build_context_synchronously
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(item['title']),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['address']),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(item: item),
                      ),
                    );
                  },
                  child: const Text('Show details'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<List<String>> _fetchPhotos(String itemId) async {
    final String response = await rootBundle.loadString('assets/photos.json');
    final data = await json.decode(response);
    final List<dynamic> jsonData = data['items'];

    final item = jsonData.firstWhere(
      (element) => element['id'] == itemId,
      orElse: () => null,
    );
    if (item != null) {
      return item['photos'].cast<String>();
    }
    return [];
  }

  Future<List<dynamic>> _fetchReviews(String itemId) async {
    final String response = await rootBundle.loadString('assets/reviews.json');
    final data = await json.decode(response);
    final List<dynamic> jsonData = data['items'];

    final item = jsonData.firstWhere(
      (element) => element['id'] == int.parse(itemId),
      orElse: () => null,
    );

    if (item != null) {
      return item['reviews'];
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Page"),
        actions: [
          IconButton(
            onPressed: _refreshLocation,
            icon: Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => RoutesScreen(),
                ),
              );
            },
            icon: Icon(Icons.route_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  center:
                      latlong2.LatLng(51.20970996273702, 17.380202823813097),
                  zoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
                  MarkerLayer(
                    markers: [
                      ...items.map((item) {
                        final latitude = item['latitude'];
                        final longitude = item['longitude'];

                        return Marker(
                          width: 40.0,
                          height: 40.0,
                          point: latlong2.LatLng(latitude, longitude),
                          builder: (ctx) => GestureDetector(
                            onTap: () =>
                                _showPinInfoDialog(items.indexOf(item)),
                            child: Container(
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.blue,
                                size: 35.0,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: latlong2.LatLng(
                            51.20970996273702, 17.380202823813097),
                        builder: (ctx) => GestureDetector(
                          onTap: () => _showPinInfoDialog(-1),
                          child: Container(
                            child: Icon(
                              Icons.location_pin,
                              color: Colors.deepPurple,
                              size: 50.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Address: ${_currentAddress ?? ""}'),
            ),
          ],
        ),
      ),
    );
  }
}
