/*
    1. The app should be able to use GPS or similar techniligies to pinpoint 
       the user's current location and provide relevant information accordingly
    2. App should include restaurants, parks, museums, theaters, landmarks, 
       shopping centers, hospitals, police stations, etc. (min 10 places of 
       all listed (NOT one to each))
    3. Each location should have additional information like opening hours, 
       contact info, user ratings, and reviews.
    4. Based on places create some city tour proposal for 4h, one day, two days of visit.
    5. App should provide interactive map which shows all mentioned places
 */

/*
    First screen of app shows the map of the city with 13 places in it (can be added in JSON files).
      When tap on the pin the dialog will be shown with the name, 
        address of the place and button for details. 
      When button is clicked the user is redirect to next screeen with three tabs. 
        First tab shows photos (when tap it shows the whole image), address, 
          phone(if exist you can call(redirect to contacts)), 
          small description (you can listen with the early AI voice). 
        Next tab is history of the place. Last one provides reviews of the places.
    You can go back to the main map. There you will see the two buttons in navbar. 
      First refresh the location (this is in real time, but to provide better experiance 
        for the presentation of the app for this lab the location is stuck in one place, 
        but the address is changing. The whole functionality is in the project,)
      Second leads to the routes screen. It is the list of possible routes. 
        When tap show the screen with route drawing in screen and information button that will show 
        the bottom sheet with informations and Google Maps rediresction
      There are only three small routes, but the city is also small and walk from end to end takes something about 40 min.
*/

import 'package:flutter/material.dart';
import 'location_screen.dart';

import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

void main() {
  RenderErrorBox.backgroundColor = Colors.transparent;
  RenderErrorBox.textStyle = ui.TextStyle(color: Colors.transparent);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guide App Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      debugShowCheckedModeBanner: false,
      home: LocationPage(),
    );
  }
}
