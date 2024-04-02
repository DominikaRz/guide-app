import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'routeAPI.dart';
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final dynamic item;
  final List<LatLng> coordinates;
  //final List<dynamic> coordinates;

  const MapScreen({Key? key, required this.item, required this.coordinates})
      : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Raw coordinates got from  OpenRouteService
  List listOfPoints = [];

  // Conversion of listOfPoints into LatLng(Latitude, Longitude) list of points
  List<LatLng> points = [];

// if a normal query is to be resolved use the second function
  void launchMap() async {
    String googleUrl = widget.item["url"];
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  // Method to consume the OpenRouteService API
  //(allows only to view start and end, so there is a loop for showing all of the route)
  getCoordinates() async {
    int n = widget.coordinates.length - 1;
    for (int i = 0; i < n; i++) {
      var response = await http.get(getRouteUrl(
          '${widget.coordinates[i].longitude.toString()}, ${widget.coordinates[i].latitude.toString()}',
          '${widget.coordinates[i + 1].longitude.toString()}, ${widget.coordinates[i + 1].latitude.toString()}'));
      setState(() {
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          listOfPoints = data['features'][0]['geometry']['coordinates'];
          points += listOfPoints
              .map((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
              .toList();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getCoordinates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
            zoom: 15, center: LatLng(51.20924427622925, 17.376565400909037)),
        children: [
          // Layer that adds the map
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          // Layer that adds points the map
          /*
          MarkerLayer(
            markers: [
              // First Marker
              Marker(
                point: LatLng(51.20924427622925, 17.376565400909037),
                width: 80,
                height: 80,
                builder: (context) => IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.location_on),
                  color: Colors.green,
                  iconSize: 45,
                ),
              ),
              // Second Marker
              Marker(
                point: LatLng(51.20742995343211, 17.37187404420478),
                width: 80,
                height: 80,
                builder: (context) => IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.location_on),
                  color: Colors.red,
                  iconSize: 45,
                ),
              ),
            ],
          ),*/
          // Polylines layer
          PolylineLayer(
            polylineCulling: false,
            polylines: [
              Polyline(points: points, color: Colors.blue, strokeWidth: 5),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return Container(
                height: 400,
                color: Colors.white,
                child: Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  widget.item["title"],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17),
                                ),
                              ),
                              SizedBox(width: 10),
                              IconButton(
                                alignment: Alignment.topRight,
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close),
                              ),
                            ],
                          ),
                          SizedBox(height: 3),
                          Text(
                              "Time: ${widget.item["time"]} - Distance: ${widget.item["distance"]} "),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => launchMap(),
                            child: Text("Navigate in Google maps"),
                          ),
                          SizedBox(height: 15),
                          Text(widget.item["description"]),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(
          Icons.info_outline,
          color: Colors.white,
        ),
      ),
      /*
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => getCoordinates(),
        child: const Icon(
          Icons.route,
          color: Colors.white,
        ),
      ),*/
      /*
      Center(
      child: ElevatedButton(
        child: const Text('showModalBottomSheet'),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return Container(
                height: 200,
                color: Colors.amber,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Modal BottomSheet'),
                      ElevatedButton(
                        child: const Text('Close BottomSheet'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );*/
    );
  }
}
