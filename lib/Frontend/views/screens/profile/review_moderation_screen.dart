import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';

class ReviewModerationScreen extends StatefulWidget {
  const ReviewModerationScreen({super.key});

  @override
  State<ReviewModerationScreen> createState() => _ReviewModerationScreenState();
}

class _ReviewModerationScreenState extends State<ReviewModerationScreen> {
  List<dynamic> _flatReviews = [];
  bool _isLoading = true;
  String? _error;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/places/popular'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> places = data['results'] ?? [];

        List<dynamic> allReviews = [];
        for (var place in places) {
          if (place['reviews'] != null && place['reviews'] is List) {
            for (var review in place['reviews']) {
              allReviews.add({
                ...review,
                'placeName': place['name'],
                'placeId': place['place_id'],
              });
            }
          }
        }

        setState(() {
          _flatReviews = allReviews;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load places for moderation');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        title: AppText.subHeading(
          'Review Moderation',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText.body('Error: $_error', color: errorColor),
            TextButton(onPressed: _fetchReviews, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_flatReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: appGreyLight),
            const SizedBox(height: 16),
            AppText.body('No reviews to moderate', color: appGrey),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: _flatReviews.length,
      itemBuilder: (context, index) {
        final review = _flatReviews[index];
        final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
        final author = review['author_name'] ?? 'Anonymous';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryBlue.withOpacity(0.1),
                    child: Text(
                      author[0].toUpperCase(),
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.body(author, fontWeight: FontWeight.bold),
                        AppText.caption('on ${review['placeName']}', size: 12),
                      ],
                    ),
                  ),
                  _buildRatingTag(rating),
                ],
              ),
              const SizedBox(height: 12),
              AppText.body(
                review['text'] ?? 'No comment provided',
                size: 14,
                color: appGreyDark,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _deleteReview(
                      review['placeId'],
                      review['author_name'],
                      review['time'],
                    ),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: errorColor,
                    ),
                    label: Text('Delete', style: TextStyle(color: errorColor)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review approved')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: travelSectionColor,
                      foregroundColor: appWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingTag(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: ratingColor, size: 14),
          const SizedBox(width: 4),
          AppText.small(
            rating.toString(),
            fontWeight: FontWeight.bold,
            color: ratingColor,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(
    String placeId,
    String authorName,
    dynamic time,
  ) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final encodedAuthor = Uri.encodeComponent(authorName);
      final response = await http.delete(
        Uri.parse(
          '${ApiConstants.baseUrl}/places/$placeId/reviews/$encodedAuthor/$time',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review deleted successfully')),
          );
        }
        _fetchReviews();
      } else {
        throw Exception('Failed to delete review');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: errorColor),
        );
      }
      setState(() => _isLoading = false);
    }
  }
}
