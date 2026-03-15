import 'package:flutter/material.dart';
import 'app_strings.dart';

class AppCategories {
  static final List<String> categories = [
    AppStrings.catAll,
    AppStrings.catForts,
    AppStrings.catBeaches,
    AppStrings.catTemples,
    AppStrings.catHillStations,
    AppStrings.catCaves,
    AppStrings.catWaterfalls,
    AppStrings.catMuseums,
    AppStrings.catWildlife,
    AppStrings.catLakes,
    AppStrings.catTrekking,
    AppStrings.catUnesco,
    AppStrings.catSpiritual,
  ];

  static final Map<String, IconData> categoryIcons = {
    AppStrings.catAll: Icons.explore_rounded,
    AppStrings.catForts: Icons.fort_rounded,
    AppStrings.catBeaches: Icons.beach_access_rounded,
    AppStrings.catTemples: Icons.temple_hindu_rounded,
    AppStrings.catHillStations: Icons.landscape_rounded,
    AppStrings.catCaves: Icons.vignette_rounded,
    AppStrings.catWaterfalls: Icons.water_rounded,
    AppStrings.catMuseums: Icons.museum_rounded,
    AppStrings.catWildlife: Icons.pets_rounded,
    AppStrings.catLakes: Icons.water_drop_rounded,
    AppStrings.catTrekking: Icons.directions_walk_rounded,
    AppStrings.catUnesco: Icons.auto_awesome_rounded,
    AppStrings.catSpiritual: Icons.self_improvement_rounded,
  };

  static final Map<String, Color> categoryColors = {
    AppStrings.catAll: const Color(0xFF1E88E5),
    AppStrings.catForts: const Color(0xFF6C63FF),
    AppStrings.catBeaches: const Color(0xFF00B4D8),
    AppStrings.catTemples: const Color(0xFFE9A21B),
    AppStrings.catHillStations: const Color(0xFF2DC653),
    AppStrings.catCaves: const Color(0xFF8D6E63),
    AppStrings.catWaterfalls: const Color(0xFF448AFF),
    AppStrings.catMuseums: const Color(0xFF607D8B),
    AppStrings.catWildlife: const Color(0xFF388E3C),
    AppStrings.catLakes: const Color(0xFF0091EA),
    AppStrings.catTrekking: const Color(0xFFF4511E),
    AppStrings.catUnesco: const Color(0xFFD4AF37),
    AppStrings.catSpiritual: const Color(0xFF9C27B0),
  };
}
