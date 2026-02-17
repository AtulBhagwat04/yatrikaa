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
}
