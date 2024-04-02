import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  DetailScreen({required this.item});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final PageController _pageController = PageController();
  double _currentPage = 0;
  bool _hasCallSupport = false;
  Future<void>? _launched;
  FlutterTts flutterTts = FlutterTts();
  List<Map<String, dynamic>> reviews = []; // List to store fetched reviews

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
    canLaunchUrl(Uri(scheme: 'tel', path: '123456789')).then((bool result) {
      setState(() {
        _hasCallSupport = result;
      });
    });
    //_fetchReviews(widget.item['id'].toString()); // Fetch reviews data
    _fetchReviews(); // Fetch reviews for the given ID
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _viewImageFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(imageUrl: imageUrl),
      ),
    );
  }

// Fetch reviews for the given ID
  void _fetchReviews() async {
    final String response = await rootBundle.loadString('assets/reviews.json');
    final data = await json.decode(response);
    final List<dynamic> jsonData = data['items'];

    final item = jsonData.firstWhere(
      (element) => element['id'] == widget.item['id'],
      orElse: () => null,
    );
    if (item != null) {
      setState(() {
        reviews = item['reviews'].cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _speakDescription() async {
    await flutterTts.speak(widget.item['description']);
  }

  Future<void> _stopDescription() async {
    await flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return DefaultTabController(
      initialIndex: 0, //optional, starts from 0, select the tab by default
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.item['title']),
          backgroundColor: Colors.deepPurple,
          bottom: const TabBar(
            tabs: [
              Tab(text: "About"),
              Tab(text: "History"),
              Tab(text: "Reviews")
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              //for first tab
              child: _buildHome(),
            ),
            Container(
              //for second tab
              child: _buildHistory(),
            ),
            Container(
              //for third tab
              child: _buildReviews(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviews() {
    if (reviews.isEmpty) {
      return const Center(
        child: Text(
          "No reviews available",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      title: Text(review['nick']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (int i = 0; i < review['stars']; i++)
                                const Icon(Icons.star, color: Colors.yellow),
                              SizedBox(width: 4.0),
                              Text('stars'),
                            ],
                          ),
                          Text(review['content']),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final List<String> photos = widget.item['photos'].cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _viewImageFullScreen(photos[index]),
                child: Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: DotsIndicator(
            dotsCount: photos.length,
            position: _currentPage,
            decorator: DotsDecorator(
              color: Color.fromRGBO(196, 196, 196, 1),
              activeColor: Colors.deepPurple,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.item['title']}',
                    style: TextStyle(
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          widget.item['address'],
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            widget.item['phone'],
                            style: TextStyle(fontSize: 16),
                          ),
                          if (widget.item['phone'] != "")
                            IconButton(
                              onPressed: _hasCallSupport
                                  ? () => setState(() {
                                        _launched = _makePhoneCall(
                                            widget.item['phone']);
                                      })
                                  : null,
                              icon: Icon(Icons.call),
                            )
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    widget.item['description'],
                  ),
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _speakDescription,
                    child: Text('Read Description'),
                  ),
                  ElevatedButton(
                    onPressed: _stopDescription,
                    child: Text('Stop Description'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    if (widget.item["history"] == null) {
      return const Center(
        child: Text(
          "No history available",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item["history"],
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  FullScreenImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(0, 0, 0, 0),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
