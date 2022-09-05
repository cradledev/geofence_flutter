import 'package:flutter/material.dart';
import './login_signup_page.dart';
import '../services/authentication.dart';
import './home.dart';

import '../services/firestoreService.dart';

// import '../services/notificationService.dart';

class RootPage extends StatefulWidget {
  const RootPage({required this.auth});

  final AuthService auth;
  @override
  State<StatefulWidget> createState() => _RootPageState();
}

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class _RootPageState extends State<RootPage> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  String? _userId = "";

  late List<Map<String, dynamic>> geofencesData;
  late bool _isDoneLoadingData = false;
  @override
  void initState() {
    super.initState();
    geofencesData = <Map<String, dynamic>>[];
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) {
          _userId = user.uid;
        }
        authStatus =
            user?.uid == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
      });
    });
    setState(() {
      _isDoneLoadingData = false;
    });
  }

  void _onLoggedIn() {
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        _userId = user?.uid.toString();
      });
    });
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  void _onSignedOut() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      _userId = "";
    });
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }

  void getGeoFenceData() async{
    // FireStoreService.readItemsByFuture().then((querySnapshot) {
    //   print("Geo Fence Data is here =========================================");
    //   geofencesData =  querySnapshot.docs.map((value) => {'id' : value.id, 'data' : value.data()}).toList();
    // });
    var _tmp = await FireStoreService.readItemsByFuture();
    // setState(() {
    //   geofencesData =  _tmp.docs.map((value) => {'id' : value.id, 'data' : value.data()}).toList();
    // });
    setState(() {
      _isDoneLoadingData = true;
      geofencesData =  _tmp.docs.map((value) => {'id' : value.id, 'data' : value.data()}).toList();
    });
  }
  @override
  Widget build(BuildContext context) {

    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return _buildWaitingScreen();
      case AuthStatus.NOT_LOGGED_IN:
        return LoginSignUpPage(
          auth: widget.auth,
          onSignedIn: _onLoggedIn,
        );
      case AuthStatus.LOGGED_IN:
        if (_userId!.isNotEmpty) {
          FireStoreService.userUid = _userId;
          getGeoFenceData();
          return _isDoneLoadingData? HomePage(geoFenceData: geofencesData, userId: _userId!) : _buildWaitingScreen();
        } else {
          return _buildWaitingScreen();
        }
      default:
        return _buildWaitingScreen();
    }
  }
}
