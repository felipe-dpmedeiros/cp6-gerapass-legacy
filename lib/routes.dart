import 'package:flutter/material.dart';
import 'package:flutterfirebaseapp/core/auth_guard.dart';
import 'package:flutterfirebaseapp/screens/NewPasswordScreen.dart';
import 'package:flutterfirebaseapp/screens/home_screen.dart';
import 'package:flutterfirebaseapp/screens/intro/intro_screen.dart';
import 'package:flutterfirebaseapp/screens/splash/splash_screen.dart';



class Routes {
  static const String splash = '/';
  static const String intro = '/intro';
  static const String home = '/home';
  static const String password = '/password';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case intro:
        return MaterialPageRoute(builder: (_) => IntroScreen());
      case home:
        return MaterialPageRoute(builder: (_) => AuthGuard(child: HomeScreen()));
      case password:
        return MaterialPageRoute(builder: (_) => NewPasswordScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  Scaffold(body: Center(child: Text('Rota não encontrada!'))),
        );
    }
  }
}
