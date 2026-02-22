import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_event.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/app_routes.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // AuthBloc is created INSIDE MaterialApp's builder so all routes
      // can access it through the normal widget-tree context.
      create: (context) => AuthBloc()..add(AppStarted()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: RouteNames.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
