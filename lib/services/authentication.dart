import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

abstract class BaseAuth {
  Future<String?> signIn(String email, String password);

  Future<String?> signUp(String email, String password);

  Future<User?> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();

  Future<void> changeEmail(String email);

  Future<void> changePassword(String password);

  Future<void> deleteUser();

  Future<void> sendPasswordResetMail(String email);
}

class AuthService implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<String?> signIn(String email, String password) async {
    UserCredential userCredentail = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    return userCredentail.user?.uid;
  }

  @override
  Future<String?> signUp(String email, String password) async {
    UserCredential userCredentail = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return userCredentail.user?.uid;
  }

  @override
  Future<User?> getCurrentUser() async {
    User? user = _firebaseAuth.currentUser;
    return user;
  }

  @override
  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }

  @override
  Future<void> sendEmailVerification() async {
    User user = _firebaseAuth.currentUser!;
    user.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    User user = _firebaseAuth.currentUser!;
    return user.emailVerified;
  }

  @override
  Future<void> changeEmail(String email) async {
    User? user = _firebaseAuth.currentUser;
    user?.updateEmail(email).then((_) {
      print("Succesfull changed email");
    }).catchError((error) {
      print("email can't be changed" + error.toString());
    });
  }

  @override
  Future<void> changePassword(String password) async {
    User user = _firebaseAuth.currentUser!;
    user.updatePassword(password).then((_) {
      print("Succesfull changed password");
    }).catchError((error) {
      print("Password can't be changed" + error.toString());
    });
  }

  @override
  Future<void> deleteUser() async {
    User user = _firebaseAuth.currentUser!;
    user.delete().then((_) {
      print("Succesfull user deleted");
    }).catchError((error) {
      print("user can't be delete" + error.toString());
    });
  }

  @override
  Future<void> sendPasswordResetMail(String email) async{
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

}