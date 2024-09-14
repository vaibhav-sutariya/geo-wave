import 'dart:developer';

import 'package:attendence_tracker/utils/flushbar_helper.dart';
import 'package:attendence_tracker/utils/routes/routes_name.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Failed to sign in with Google.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    FlushBarHelper.flushbarSuccessMessage('Login Successfull!', context);

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    log('User: ${userCredential.user}');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    if (prefs.getBool('isLoggedIn') == true) {
      Navigator.pushReplacementNamed(context, RoutesName.home);
    }
    // Successfully signed in
    // You can now use `userCredential` for further processing or navigation
  } catch (e) {
    // Handle error, e.g., show a snackbar with the error message
    print('Exception during Google sign in: $e');
    FlushBarHelper.flushbarErrorMessage('Login Failed $e', context);
  } finally {}
}
