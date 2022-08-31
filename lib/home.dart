import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 15,
  );

  // Maps
  final Set<Marker> _markers = HashSet<Marker>();
  final Set<Polygon> _polygons = HashSet<Polygon>();
  final Set<Circle> _circles = HashSet<Circle>();
  late GoogleMapController _googleMapController;
  late BitmapDescriptor _markerIcon;
  List<LatLng> polygonLatLngs = <LatLng>[];
  late double radius;

  //ids
  int _polygonIdCounter = 1;
  int _circleIdCounter = 1;
  int _markerIdCounter = 1;

  // Type controllers
  bool _isPolygon = true; //Default
  bool _isMarker = false;
  bool _isCircle = false;

  @override
  void initState() {
    super.initState();
    // If I want to change the marker icon:
    // _setMarkerIcon();
  }

  // This function is to change the marker icon
  void _setMarkerIcon() async {
    _markerIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/farm.png');
  }

  // Draw Polygon to the map
  void _setPolygon() {
    final String polygonIdVal = 'polygon_id_$_polygonIdCounter';
    _polygons.add(Polygon(
      polygonId: PolygonId(polygonIdVal),
      points: polygonLatLngs,
      strokeWidth: 2,
      strokeColor: Colors.yellow,
      fillColor: Colors.yellow.withOpacity(0.15),
    ));
  }

  // Set circles as points to the map
  void _setCircles(LatLng point) {
    final String circleIdVal = 'circle_id_$_circleIdCounter';
    _circleIdCounter++;
    print(
        'Circle | Latitude: ${point.latitude}  Longitude: ${point.longitude}  Radius: $radius');
    _circles.add(Circle(
        circleId: CircleId(circleIdVal),
        center: point,
        radius: radius,
        fillColor: Colors.redAccent.withOpacity(0.5),
        strokeWidth: 3,
        strokeColor: Colors.redAccent));
  }

  // Set Markers to the map
  void _setMarkers(LatLng point) {
    final String markerIdVal = 'marker_id_$_markerIdCounter';
    _markerIdCounter++;
    setState(() {
      print(
          'Marker | Latitude: ${point.latitude}  Longitude: ${point.longitude}');
      _markers.add(
        Marker(
          markerId: MarkerId(markerIdVal),
          position: point,
          infoWindow:
              const InfoWindow(title: 'Marker Title', snippet: 'Marker snippet'),
        ),
      );
    });
  }

  // Start the map with this marker setted up
  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('0'),
          position: LatLng(37.42796133580664, -122.085749655962),
          infoWindow:
              InfoWindow(title: 'Roça', snippet: 'Um bom lugar para estar'),
          //icon: _markerIcon,
        ),
      );
    });
  }

  Widget _fabPolygon() {
    return FloatingActionButton.extended(
      onPressed: () {
        //Remove the last point setted at the polygon
        setState(() {
          polygonLatLngs.removeLast();
        });
      },
      icon: Icon(Icons.undo),
      label: Text('Undo point'),
      backgroundColor: Colors.orange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Studying Maps - Zeh'),
          centerTitle: true,
          backgroundColor: Colors.grey[900],
        ),
        floatingActionButton:
            polygonLatLngs.length > 0 && _isPolygon ? _fabPolygon() : null,
        body: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              mapType: MapType.hybrid,
              markers: _markers,
              circles: _circles,
              polygons: _polygons,
              myLocationEnabled: true,
              onTap: (point) {
                if (_isPolygon) {
                  setState(() {
                    polygonLatLngs.add(point);
                    _setPolygon();
                  });
                } else if (_isMarker) {
                  setState(() {
                    _markers.clear();
                    _setMarkers(point);
                  });
                } else if (_isCircle) {
                  setState(() {
                    _circles.clear();
                    _setCircles(point);
                  });
                }
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: <Widget>[
                  RaisedButton(
                      color: Colors.black54,
                      onPressed: () {
                        _isPolygon = true;
                        _isMarker = false;
                        _isCircle = false;
                      },
                      child: Text(
                        'Polygon',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      )),
                  RaisedButton(
                      color: Colors.black54,
                      onPressed: () {
                        _isPolygon = false;
                        _isMarker = true;
                        _isCircle = false;
                      },
                      child: Text('Marker',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white))),
                  RaisedButton(
                      color: Colors.black54,
                      onPressed: () async {
                        _isPolygon = false;
                        _isMarker = false;
                        _isCircle = true;
                        radius = 50;
                        return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: Text(
                                    'Choose the radius (m)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  content: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Material(
                                        color: Colors.black,
                                        child: TextField(
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            icon: Icon(Icons.zoom_out_map),
                                            hintText: 'Ex: 100',
                                            suffixText: 'meters',
                                          ),
                                          keyboardType:
                                              TextInputType.numberWithOptions(),
                                          onChanged: (input) {
                                            setState(() {
                                              radius = double.parse(input);
                                            });
                                          },
                                        ),
                                      )),
                                  actions: <Widget>[
                                    FlatButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Ok',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                                  ],
                                ));
                      },
                      child: Text('Circle',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)))
                ],
              ),
            )
          ],
        ));
  }
}
