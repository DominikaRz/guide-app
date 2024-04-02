import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'route_screen.dart';

class RoutesScreen extends StatefulWidget {
  @override
  _RoutesScreenState createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    String jsonData = await rootBundle.loadString('assets/routes.json');
    setState(() {
      items = json.decode(jsonData)['items'];
    });
  }

  void navigateToDetailsScreen(int index) {
    List<LatLng> coordinates = [];

    var n = items[index]["coordinates"].length;
    for (int i = 0; i < n; i++)
      coordinates.add(LatLng(items[index]["coordinates"][i]["latitude"],
          items[index]["coordinates"][i]["longitude"]));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          item: items[index],
          coordinates: coordinates,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Routes'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(items[index]['title']),
            subtitle: Text(
                'Time: ${items[index]['time']} - Distance: ${items[index]['distance']}'),
            onTap: () => navigateToDetailsScreen(index),
          );
        },
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final dynamic item;
  final List<LatLng> coordinates;

  const DetailsScreen({required this.item, required this.coordinates});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item['title']),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${item['time']}'),
            Text('Distance: ${item['distance']}'),
            SizedBox(height: 16.0),
            Text(item['description']),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Handle button click
              },
              child: Text('Send Data'),
            ),
          ],
        ),
      ),
    );
  }
}
