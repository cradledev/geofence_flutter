import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:location/location.dart' as loc;

import '../services/firestoreService.dart';
import '../services/notificationService.dart';

import 'package:pointer_interceptor/pointer_interceptor.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.geoFenceData, required this.userId});

  final List<Map<String, dynamic>> geoFenceData;
  final String userId;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 15,
  );

  loc.Location location = loc.Location();
  late loc.LocationData currentLocation;
  late bool _serviceEnabled;
  late loc.PermissionStatus _permissionGranted;
  // Maps
  late Set<Marker> _markers = HashSet<Marker>();
  late Set<Polygon> _polygons = HashSet<Polygon>();
  late Set<Circle> _circles = HashSet<Circle>();
  late Set<Polyline> _polyLines = HashSet<Polyline>();

  late List<Map<String, dynamic>> markerMapData = <Map<String, dynamic>>[];
  late List<Map<String, dynamic>> polygonMapData = <Map<String, dynamic>>[];
  late List<Map<String, dynamic>> circleMapData = <Map<String, dynamic>>[];

  late GoogleMapController _googleMapController;
  late BitmapDescriptor _markerIcon;
  List<LatLng> polygonLatLngs = <LatLng>[];
  // List<LatLng> polyLineLatLngs = <LatLng>[];
  late double radius;

  late Marker? selectedMarker;
  late Polygon? selectedPolygon;
  late Circle? selectedCircle;

  late Marker? activeMarker = null;
  late Polygon? activePolygon = null;
  late Circle? activeCircle = null;
  //ids
  // int _polygonIdCounter = 1;
  // int _circleIdCounter = 1;
  // int _markerIdCounter = 1;
  // int _polyLineIdCounter = 1;

  // Type controllers
  bool _isPolygon = true; //Default
  bool _isMarker = false;
  bool _isCircle = false;

  bool _isStartingDrawing = false;
  // bool _isStartingDeleting = false;

  String? tag = "";

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    location.onLocationChanged.listen((loc.LocationData latestLocation) {
      currentLocation = latestLocation;
      print("current location:" + latestLocation.toString());
      onTrackingPositionOnCustomMap(
          mt.LatLng(latestLocation.latitude!, latestLocation.longitude!));
    });
    // If I want to change the marker icon:
    // _setMarkerIcon();
    onInit();
    onMakingInitMapData();
    setInitialLocation();
    // Future.delayed(const Duration(seconds: 4), () {
    //   onTrackingPositionOnCustomMap(
    //       mt.LatLng(37.40025807866793, -122.08673335611822));
    // });
  }

  // custom init function
  void onInit() {
    FireStoreService.userUid = widget.userId;
    selectedMarker = null;
    selectedPolygon = null;
    selectedCircle = null;
  }

  void _checkLocationPermission() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }
  }

  void setInitialLocation() async {
    currentLocation = await location.getLocation();
  }

  void onMakingInitMapData() {
    setState(() {
      tag = "";
    });

    if (widget.geoFenceData.isNotEmpty) {
      _polygons.clear();
      _circles.clear();
      _markers.clear();

      markerMapData = widget.geoFenceData
          .where((e) => e['data']['type'] == "Marker")
          .toList();
      circleMapData = widget.geoFenceData
          .where((e) => e['data']['type'] == "Circle")
          .toList();
      polygonMapData = widget.geoFenceData
          .where((e) => e['data']['type'] == "Polygon")
          .toList();

      for (var i = 0; i < markerMapData.length; i++) {
        var _data = jsonDecode(markerMapData[i]['data']['data']);
        Marker _tmp = Marker(
            markerId: MarkerId(_data['markerId']),
            position: LatLng(_data['position'][0], _data['position'][1]),
            consumeTapEvents: true,
            onTap: () {
              if (_isMarker && !_isStartingDrawing) {
                onInit();
                selectedMarker = _markers.firstWhereOrNull(
                    (element) => element.markerId.value == _data['markerId']);
                // getSelectedMarker(
                //     mt.LatLng(_data['position'][0], _data['position'][1]));
                print(
                    'selected marker is here ${selectedMarker?.markerId.value}');
              }
            });
        setState(() {
          _markers.add(_tmp);
        });
      }
      for (var i = 0; i < circleMapData.length; i++) {
        var _data = jsonDecode(circleMapData[i]['data']['data']);
        Circle _tmp = Circle(
            circleId: CircleId(_data['circleId']),
            center: LatLng(_data['center'][0], _data['center'][1]),
            radius: _data['radius'],
            fillColor: Colors.redAccent.withOpacity(0.5),
            strokeWidth: 3,
            strokeColor: Colors.redAccent,
            onTap: () {
              if (_isCircle && !_isStartingDrawing) {
                onInit();
                selectedCircle = _circles.firstWhereOrNull(
                    (element) => element.circleId.value == _data['circleId']);
              }
            });
        setState(() {
          _circles.add(_tmp);
        });
      }
      for (var i = 0; i < polygonMapData.length; i++) {
        var _data = jsonDecode(polygonMapData[i]['data']['data']);
        List<LatLng> _tmppolygonPoints = <LatLng>[];
        for (var j = 0; j < _data['points'].length; j++) {
          _tmppolygonPoints
              .add(LatLng(_data['points'][j][0], _data['points'][j][1]));
        }
        Polygon _tmp = Polygon(
            polygonId: PolygonId(_data['polygonId']),
            points: _tmppolygonPoints,
            strokeWidth: 2,
            strokeColor: Colors.yellow,
            fillColor: Colors.yellow.withOpacity(0.15),
            onTap: () {
              if (_isPolygon && !_isStartingDrawing) {
                onInit();
                selectedPolygon = _polygons.firstWhereOrNull(
                    (element) => element.polygonId.value == _data['polygonId']);
              }
            });
        setState(() {
          _polygons.add(_tmp);
        });
      }
    }
  }

  // This function is to change the marker icon
  void _setMarkerIcon() async {
    _markerIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/farm.png');
  }

  // Draw Polygon to the map
  void _setPolygon() async {
    // if (tag!.isNotEmpty && _isNextProcessingSaveMapData) {
    print("=====================6788788================");
    final String polygonIdVal =
        'polygon_id_${DateTime.now().millisecondsSinceEpoch}';
    // _polygonIdCounter++;
    // _polyLineIdCounter++;
    Polygon _tmp = Polygon(
        polygonId: PolygonId(polygonIdVal),
        points: polygonLatLngs,
        strokeWidth: 2,
        strokeColor: Colors.yellow,
        fillColor: Colors.yellow.withOpacity(0.15),
        onTap: () {
          if (_isPolygon && !_isStartingDrawing) {
            onInit();
            List<Polygon> _tmp = _polygons.map((e) => e).toList();
            selectedPolygon = _tmp.firstWhereOrNull(
                (element) => element.polygonId.value == polygonIdVal);
          }
        });
    _polygons.add(_tmp);
    await FireStoreService.addItem(
        title: tag!,
        description: "Polygon is here",
        type: "Polygon",
        mapData: jsonEncode(_tmp));

    polygonLatLngs = <LatLng>[];
    _polyLines.clear();
    onMakingInitMapData();
    // } else {
    //   polygonLatLngs = <LatLng>[];
    //   _polyLines.clear();
    // }
  }

  // Draw PolyLines to the map
  void _setPolyLines() {
    String polyLineIdVal = 'polyLine_id';
    _polyLines.add(
      Polyline(
          polylineId: PolylineId(polyLineIdVal),
          points: polygonLatLngs,
          width: 2,
          color: Colors.blue),
    );
  }

  // Set circles as points to the map
  void _setCircles(LatLng point) async {
    final String circleIdVal =
        'circle_id_${DateTime.now().millisecondsSinceEpoch}';
    // _circleIdCounter++;
    print(
        'Circle | Latitude: ${point.latitude}  Longitude: ${point.longitude}  Radius: $radius');
    Circle _tmp = Circle(
        circleId: CircleId(circleIdVal),
        center: point,
        radius: radius,
        fillColor: Colors.redAccent.withOpacity(0.5),
        strokeWidth: 3,
        strokeColor: Colors.redAccent,
        onTap: () {
          if (_isCircle && !_isStartingDrawing) {
            onInit();
            selectedCircle = _circles.firstWhereOrNull(
                (element) => element.circleId.value == circleIdVal);
          }
        });
    _circles.add(_tmp);
    await FireStoreService.addItem(
        title: tag!,
        description: "Circle is here",
        type: "Circle",
        mapData: jsonEncode(_tmp));
    onMakingInitMapData();
  }

  // Set Markers to the map
  void _setMarkers(LatLng point) async {
    final String markerIdVal =
        'marker_id_${DateTime.now().millisecondsSinceEpoch}';
    // _markerIdCounter++;
    print(
        'Marker | Latitude: ${point.latitude}  Longitude: ${point.longitude}');
    Marker _tmp = Marker(
        markerId: MarkerId(markerIdVal),
        position: point,
        // infoWindow:
        //     const InfoWindow(title: 'Marker Title', snippet: 'Marker snippet'),
        consumeTapEvents: true,
        onTap: () {
          if (_isMarker && !_isStartingDrawing) {
            onInit();
            // getSelectedMarker(mt.LatLng(point.latitude, point.longitude));
            selectedMarker = _markers.firstWhereOrNull(
                (element) => element.markerId.value == markerIdVal);
            print('selected marker is here ${selectedMarker?.markerId.value}');
          }
        });
    _markers.add(_tmp);
    await FireStoreService.addItem(
        title: tag!,
        description: "Marker is here",
        type: "Marker",
        mapData: jsonEncode(_tmp));
    onMakingInitMapData();
  }

  // Start the map with this marker setted up
  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;

    setState(() {
      _markers.add(
        const Marker(
          markerId: MarkerId('0'),
          position: LatLng(37.42796133580664, -122.085749655962),
          infoWindow: InfoWindow(
              title: 'Init Position', snippet: 'This is the init position.'),
          //icon: _markerIcon,
        ),
      );
    });
  }

  void onTrackingPositionOnCustomMap(mt.LatLng _point) {
    if (_polygons.isNotEmpty) {
      Polygon? tmpactivePolygon = _polygons.firstWhereOrNull((element) =>
          _isCheckingIfPointInsidePolygon(_point, element) == true);

      if (activePolygon != null) {
        print("=====================2");
        if (tmpactivePolygon != null) {
          if (tmpactivePolygon.polygonId.value !=
              activePolygon?.polygonId.value) {
            print("=====================3");
            var _tmpPolygonData = polygonMapData.firstWhere((element) {
              var _data = jsonDecode(element['data']['data']);
              return _data['polygonId'] == tmpactivePolygon.polygonId.value;
            });
            activePolygon = tmpactivePolygon;
            print(
                '_activationPolygon is here==========${_tmpPolygonData["id"]}, ${_tmpPolygonData["data"]['type']}');
            NotificationService.showNotification(
                _tmpPolygonData["data"]['title'],
                'Entered ${_tmpPolygonData["data"]['title']} Area in type of ${_tmpPolygonData["data"]['type']}');
          }
        } else {
          print("=====================4");
          var _tmpPolygonData = polygonMapData.firstWhere((element) {
            var _data = jsonDecode(element['data']['data']);
            return _data['polygonId'] == activePolygon?.polygonId.value;
          });
          activePolygon = tmpactivePolygon;

          NotificationService.showNotification(_tmpPolygonData["data"]['title'],
              'Exit ${_tmpPolygonData["data"]['title']} Area in type of ${_tmpPolygonData["data"]['type']}');
        }
      } else {
        if (tmpactivePolygon != null) {
          print("=====================1");
          var _tmpPolygonData = polygonMapData.firstWhere((element) {
            var _data = jsonDecode(element['data']['data']);
            return _data['polygonId'] == tmpactivePolygon.polygonId.value;
          });
          activePolygon = tmpactivePolygon;

          NotificationService.showNotification(_tmpPolygonData["data"]['title'],
              'Entered ${_tmpPolygonData["data"]['title']} Area in type of ${_tmpPolygonData["data"]['type']}');
        }
      }
    }
    if (_circles.isNotEmpty) {
      Circle? tmpactiveCircle = _circles.firstWhereOrNull(
          (element) => _isCheckingIfPointInsideCircle(_point, element) == true);
      if (activeCircle != null) {
        if (tmpactiveCircle != null) {
          if (tmpactiveCircle.circleId.value != activeCircle?.circleId.value) {
            var _tmpCircleData = circleMapData.firstWhere((element) {
              var _data = jsonDecode(element['data']['data']);
              return _data['circleId'] == tmpactiveCircle.circleId.value;
            });
            activeCircle = tmpactiveCircle;
            NotificationService.showNotification(
                _tmpCircleData["data"]['title'],
                'Entered ${_tmpCircleData["data"]['title']} Area in type of ${_tmpCircleData["data"]['type']}');
          }
        } else {
          var _tmpCircleData = circleMapData.firstWhere((element) {
            var _data = jsonDecode(element['data']['data']);
            return _data['circleId'] == activeCircle!.circleId.value;
          });

          activeCircle = tmpactiveCircle;
          NotificationService.showNotification(_tmpCircleData["data"]['title'],
              'Exit ${_tmpCircleData["data"]['title']} Area in type of ${_tmpCircleData["data"]['type']}');
        }
      } else {
        if (tmpactiveCircle != null) {
          var _tmpCircleData = circleMapData.firstWhere((element) {
            var _data = jsonDecode(element['data']['data']);
            return _data['circleId'] == tmpactiveCircle.circleId.value;
          });

          activeCircle = tmpactiveCircle;
          NotificationService.showNotification(_tmpCircleData["data"]['title'],
              'Entered ${_tmpCircleData["data"]['title']} Area in type of ${_tmpCircleData["data"]['type']}');
        }
      }
    }
    if (_markers.isNotEmpty) {
      Marker? tmpactiveMarker = _markers.firstWhereOrNull(
          (element) => _isCheckingIfPointIsMarker(_point, element) == true);
      if (activeMarker != null) {
        if (tmpactiveMarker != null) {
          if (tmpactiveMarker.markerId.value != activeMarker?.markerId.value) {
            var _tmpMarkerData = markerMapData.firstWhere((element) {
              var _data = jsonDecode(element['data']['data']);
              return _data['markerId'] == tmpactiveMarker.markerId.value;
            });
            activeMarker = tmpactiveMarker;
            NotificationService.showNotification(
                _tmpMarkerData["data"]['title'],
                'Entered ${_tmpMarkerData["data"]['title']} Area in type of ${_tmpMarkerData["data"]['type']}');
          }
        } else {
          var _tmpMarkerData = markerMapData.firstWhere((element) {
            var _data = jsonDecode(element['data']['data']);
            return _data['markerId'] == activeMarker!.markerId.value;
          });

          activeMarker = tmpactiveMarker;
          NotificationService.showNotification(_tmpMarkerData["data"]['title'],
              'Exit ${_tmpMarkerData["data"]['title']} Area in type of ${_tmpMarkerData["data"]['type']}');
        }
      } else {
        if (tmpactiveMarker != null) {
          var _tmpMarkerData = markerMapData.firstWhere((element) {
            var _data = jsonDecode(element['data']['data']);
            return _data['markerId'] == tmpactiveMarker.markerId.value;
          });

          activeMarker = tmpactiveMarker;
          NotificationService.showNotification(_tmpMarkerData["data"]['title'],
              'Entered ${_tmpMarkerData["data"]['title']} Area in type of ${_tmpMarkerData["data"]['type']}');
        }
      }
    }
  }

  // void getSelectedPolygon(mt.LatLng _point) {
  //   if (_polygons.isEmpty) {
  //     setState(() {
  //       selectedPolygon = null;
  //     });
  //   } else {
  //     List<Polygon> _tmpPolygonList = _polygons.map((e) => e).toList();
  //     for (var i = 0; i < _tmpPolygonList.length; i++) {
  //       Polygon _tmpPolygon = _tmpPolygonList[i];
  //       if (_isCheckingIfPointInsidePolygon(_point, _tmpPolygon)) {
  //         setState(() {
  //           selectedPolygon = _tmpPolygon;
  //         });
  //         break;
  //       }
  //     }
  //   }
  // }

  // void getSelectedCircle(mt.LatLng _point) {
  //   if (_circles.isEmpty) {
  //     setState(() {
  //       selectedCircle = null;
  //     });
  //   } else {
  //     List<Circle> _tmpCircleList = _circles.map((e) => e).toList();
  //     for (var i = 0; i < _tmpCircleList.length; i++) {
  //       Circle _tmpCircle = _tmpCircleList[i];
  //       if (_isCheckingIfPointInsideCircle(_point, _tmpCircle)) {
  //         setState(() {
  //           selectedCircle = _tmpCircle;
  //         });
  //         break;
  //       }
  //     }
  //   }
  // }

  // void getSelectedMarker(mt.LatLng _point) {
  //   if (_markers.isEmpty) {
  //     setState(() {
  //       selectedMarker = null;
  //     });
  //   } else {
  //     List<Marker> _tmpMarkerList = _markers.map((e) => e).toList();
  //     for (var i = 0; i < _tmpMarkerList.length; i++) {
  //       Marker _tmpMarker = _tmpMarkerList[i];
  //       if (_isCheckingIfPointIsMarker(_point, _tmpMarker)) {
  //         setState(() {
  //           selectedMarker = _tmpMarker;
  //         });
  //         break;
  //       }
  //     }
  //   }
  // }

  bool _isCheckingIfPointInsidePolygon(mt.LatLng _point, Polygon _polygon) {
    List<mt.LatLng> _polygonPoints = _polygon.points
        .map((e) => mt.LatLng.fromMap(
            {'latitude': e.latitude, 'longitude': e.longitude}))
        .toList();
    bool _isInside =
        mt.PolygonUtil.containsLocation(_point, _polygonPoints, true);
    return _isInside;
  }

  bool _isCheckingIfPointInsideCircle(mt.LatLng _point, Circle _circle) {
    // List<mt.LatLng> _polygonPoints = _polygon.points.map((e) => mt.LatLng.fromMap({'latitude' : e.latitude, 'longitude' : e.longitude})).toList();
    mt.LatLng _circleCenter =
        mt.LatLng(_circle.center.latitude, _circle.center.longitude);
    final _distance =
        mt.SphericalUtil.computeDistanceBetween(_point, _circleCenter);
    bool _isInside = false;
    if (_distance <= _circle.radius) {
      _isInside = true;
    } else {
      _isInside = false;
    }
    return _isInside;
  }

  bool _isCheckingIfPointIsMarker(mt.LatLng _point, Marker _pMarker) {
    // List<mt.LatLng> _polygonPoints = _polygon.points.map((e) => mt.LatLng.fromMap({'latitude' : e.latitude, 'longitude' : e.longitude})).toList();
    mt.LatLng _markerPosition =
        mt.LatLng(_pMarker.position.latitude, _pMarker.position.longitude);
    bool _isInside = false;
    if (_markerPosition == _point) {
      _isInside = true;
    } else {
      _isInside = false;
    }
    return _isInside;
  }

  Future<void> onDeletSelectedShape() async {
    if (_isPolygon && _polygons.isNotEmpty && selectedPolygon != null) {
      // Polygon _tempPolygon = _polygons.firstWhere(
      //     (pPolygon) => pPolygon.polygonId.value == selectedPolygon?.polygonId.value,
      //     orElse: () => null);
      setState(() {
        _polygons.removeWhere((element) =>
            element.polygonId.value == selectedPolygon?.polygonId.value);
      });
      var _tmp = polygonMapData.firstWhere((element) =>
          jsonDecode(element['data']['data'])['polygonId'] ==
          selectedPolygon?.polygonId.value);

      String _selectPolygonMapDataId = _tmp['id'];
      await FireStoreService.deleteItem(docId: _selectPolygonMapDataId);
    }
    if (_isCircle && _circles.isNotEmpty && selectedCircle != null) {
      // Circle _tempCircle = _circles.firstWhere(
      //     (pCircle) => pCircle.circleId.value == selectedCircle?.circleId.value,
      //     orElse: () => );
      setState(() {
        _circles.removeWhere((element) =>
            element.circleId.value == selectedCircle?.circleId.value);
      });
      var _tmp = circleMapData.firstWhere((element) =>
          jsonDecode(element['data']['data'])['circleId'] ==
          selectedCircle?.circleId.value);
      String _selectCircleMapDataId = _tmp['id'];
      await FireStoreService.deleteItem(docId: _selectCircleMapDataId);
    }
    if (_isMarker && _markers.length > 1 && selectedMarker != null) {
      // Marker marker = _markers.firstWhere(
      //     (marker) => marker.markerId.value == "myId",
      //     orElse: () => null);
      setState(() {
        _markers.removeWhere(
            (item) => item.markerId.value == selectedMarker?.markerId.value);
      });
      var _tmp = markerMapData.firstWhere((element) =>
          jsonDecode(element['data']['data'])['markerId'] ==
          selectedMarker?.markerId.value);
      String _selectMarkerMapDataId = _tmp['id'];
      await FireStoreService.deleteItem(docId: _selectMarkerMapDataId);
    }
  }

  Widget _fabPolygon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        polygonLatLngs.isNotEmpty
            ? PointerInterceptor(
                child: FloatingActionButton(
                  child: const Icon(Icons.undo),
                  onPressed: () {
                    setState(() {
                      polygonLatLngs.removeLast();
                    });
                  },
                  backgroundColor: Colors.orange,
                  heroTag: null,
                ),
              )
            : const SizedBox(
                width: 0,
              ),
        const SizedBox(
          height: 10,
        ),
        PointerInterceptor(
          child: FloatingActionButton(
            child: Icon(
                !_isStartingDrawing ? Icons.draw_outlined : Icons.exit_to_app),
            onPressed: () {
              setState(() {
                _isStartingDrawing = !_isStartingDrawing;
                // _isStartingDeleting = false;
              });
            },
            backgroundColor: Colors.purple,
            heroTag: null,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        _isStartingDrawing
            ? const SizedBox(
                width: 0,
                height: 0,
              )
            : PointerInterceptor(
                child: FloatingActionButton(
                  child: const Icon(Icons.delete),
                  onPressed: () async {
                    await onDeletSelectedShape();
                  },
                  backgroundColor: Colors.red,
                  heroTag: null,
                ),
              ),
        const SizedBox(
          height: 10,
        ),
        _isStartingDrawing && _isPolygon
            ? PointerInterceptor(
                child: FloatingActionButton(
                  child: const Icon(Icons.save),
                  onPressed: () async {
                    if (_isPolygon && _polyLines.isNotEmpty) {
                      showAlertDialog(context, null);
                    }
                  },
                  heroTag: null,
                  backgroundColor: Colors.green,
                ),
              )
            : const SizedBox(
                width: 0,
                height: 0,
              )
      ],
    );
  }

  showAlertDialog(BuildContext context, LatLng? point) {
    // set up the buttons
    Widget cancelButton = PointerInterceptor(
        child: TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ));
    ;
    Widget continueButton = PointerInterceptor(
        child: TextButton(
      child: const Text("Confirm"),
      onPressed: () {
        if (tag!.isNotEmpty) {
          if (_isPolygon) {
            setState(() {
              _setPolygon();
              polygonLatLngs = <LatLng>[];
              _polyLines.clear();
            });
          }
          if (_isCircle) {
            setState(() {
              _setCircles(point!);
            });
          }
          if (_isMarker) {
            setState(() {
              _setMarkers(point!);
            });
          }
        }
        Navigator.of(context).pop();
      },
    ));
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Tag Input"),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextFormField(
          maxLines: 1,
          keyboardType: TextInputType.text,
          autofocus: false,
          onChanged: (value) {
            setState(() {
              tag = value;
            });
          },
          decoration: const InputDecoration(
              hintText: 'Tag Input',
              icon: Icon(
                Icons.tag_outlined,
                color: Colors.grey,
              )),
          validator: (value) => value!.isEmpty ? 'Tag can\'t be empty' : null,
        ),
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Geo-Fence with Custom Marker'),
          centerTitle: true,
          backgroundColor: Colors.grey[900],
        ),
        floatingActionButton: _fabPolygon(),
        body: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              onMapCreated: _onMapCreated,
              mapType: MapType.hybrid,
              markers: _markers,
              circles: _circles,
              polygons: _polygons,
              polylines: _polyLines,
              myLocationEnabled: true,
              onTap: (point) {
                print("point is here =================$point");
                onInit();
                if (_isPolygon) {
                  if (_isStartingDrawing) {
                    setState(() {
                      // polygonLatLngs.add(point);
                      // _setPolygon();
                      polygonLatLngs.add(point);
                      _setPolyLines();
                    });
                  }
                  // else {
                  //   getSelectedPolygon(
                  //       mt.LatLng(point.latitude, point.longitude));
                  // }
                } else if (_isMarker) {
                  if (_isStartingDrawing) {
                    // setState(() {
                    //   // _markers.clear();
                    //   _setMarkers(point);
                    // });
                    showAlertDialog(context, point);
                  }
                  // else {
                  //   getSelectedMarker(
                  //       mt.LatLng(point.latitude, point.longitude));
                  // }
                } else if (_isCircle) {
                  if (_isStartingDrawing) {
                    // setState(() {
                    //   // _circles.clear();
                    //   _setCircles(point);
                    // });
                    showAlertDialog(context, point);
                  }
                  // else {
                  //   getSelectedCircle(
                  //       mt.LatLng(point.latitude, point.longitude));
                  // }
                }
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  PointerInterceptor(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isPolygon = true;
                          _isMarker = false;
                          _isCircle = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          primary: _isPolygon ? Colors.amber : Colors.blue),
                      child: const Text(
                        'Polygon',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  PointerInterceptor(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          polygonLatLngs = <LatLng>[];
                          _polyLines.clear();
                          _isPolygon = false;
                          _isMarker = true;
                          _isCircle = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          primary: _isMarker ? Colors.amber : Colors.blue),
                      child: const Text(
                        'Marker',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  PointerInterceptor(
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          polygonLatLngs = <LatLng>[];
                          _polyLines.clear();
                          _isPolygon = false;
                          _isMarker = false;
                          _isCircle = true;
                          radius = 50;
                        });
                  
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text(
                              'Choose the radius (m)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            content: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Material(
                                  color: Colors.black,
                                  child: TextField(
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.white),
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.zoom_out_map),
                                      hintText: 'Ex: 100',
                                      suffixText: 'meters',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(),
                                    onChanged: (input) {
                                      setState(() {
                                        radius = double.parse(input);
                                      });
                                    },
                                  ),
                                )),
                            actions: <Widget>[
                              PointerInterceptor(
                                child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Ok',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          primary: _isCircle ? Colors.amber : Colors.blue),
                      child: const Text(
                        'Circle',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
