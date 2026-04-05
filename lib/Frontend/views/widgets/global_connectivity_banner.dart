import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yatrikaa/Frontend/core/bloc/connectivity/connectivity_bloc.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';

class GlobalConnectivityBanner extends StatefulWidget {
  const GlobalConnectivityBanner({super.key});

  @override
  State<GlobalConnectivityBanner> createState() =>
      _GlobalConnectivityBannerState();
}

class _GlobalConnectivityBannerState extends State<GlobalConnectivityBanner> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        // Exclude screens as requested: splash, onboarding, login, signup
        final hiddenRoutes = [
          RouteNames.splash,
          RouteNames.onboarding,
          RouteNames.auth,
          RouteNames.login,
          RouteNames.signup,
        ];

        if (state.currentRoute != null &&
            hiddenRoutes.contains(state.currentRoute)) {
          return const SizedBox.shrink();
        }

        if (state.isOffline) {
          return _buildBanner(
            color: const Color(0xFF212121),
            text: "No connection",
            icon: Icons.wifi_off_rounded,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBanner({
    required Color color,
    required String text,
    required IconData icon,
  }) {
    return Material(
      color: color,
      child: Container(
        width: double.infinity,
        // Extremely slim YouTube style
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
