import 'package:attendence_tracker/utils/routes/routes_name.dart';
import 'package:attendence_tracker/view/admin/admin_screen.dart';
import 'package:attendence_tracker/view/auth/google_signin_screen.dart';
import 'package:attendence_tracker/view/home/home_screen.dart';
import 'package:attendence_tracker/view/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.splash:
        return MaterialPageRoute(
            builder: (BuildContext context) => const SplashScreen());
      case RoutesName.home:
        return MaterialPageRoute(
            builder: (BuildContext context) => const HomeScreen());
      case RoutesName.admin:
        return MaterialPageRoute(
            builder: (BuildContext context) => const AdminScreen());
      case RoutesName.signIn:
        return MaterialPageRoute(
            builder: (BuildContext context) => const SignInScreen());
      default:
        return MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          );
        });
    }
  }
}
