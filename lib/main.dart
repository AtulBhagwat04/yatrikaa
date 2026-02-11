import 'package:flutter/material.dart';

import 'Frontend/views/Routes/app_routes.dart';
import 'Frontend/views/Routes/route_names.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
