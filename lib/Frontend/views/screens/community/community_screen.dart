import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Artistic Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.ms,
                  AppSpacing.m,
                  AppSpacing.ms,
                  AppSpacing.m,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.heading(
                          'Journeys',
                          fontWeight: FontWeight.w900,
                          size: 30,
                          letterSpacing: -1,
                        ),
                        AppText.caption(
                          'Community stories & tips',
                          color: primaryBlue,
                        ),
                      ],
                    ),
                    _HeaderAction(
                      icon: Icons.add_rounded,
                      onTap: () {},
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ),

            // The Feed
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = _dummyPosts[index % _dummyPosts.length];
                  return _TravelJournalCard(post: post);
                }, childCount: _dummyPosts.length),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPrimary ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? primaryBlue : Colors.black).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : primaryBlue,
          size: 24,
        ),
      ),
    );
  }
}

class _TravelJournalCard extends StatefulWidget {
  final _PostData post;
  const _TravelJournalCard({required this.post});

  @override
  State<_TravelJournalCard> createState() => _TravelJournalCardState();
}

class _TravelJournalCardState extends State<_TravelJournalCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: p.imageUrl,
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheHeight: 600, // Reduced slightly for safety
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[100], height: 260),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      height: 260,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // Location Tag
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Region
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: primaryBlue.withOpacity(0.1),
                      child: Text(
                        p.author[0],
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppText.body(
                      p.author,
                      fontWeight: FontWeight.w700,
                      size: 13,
                    ),
                    const Spacer(),
                    AppText.caption(p.time, size: 10),
                  ],
                ),
                const SizedBox(height: 12),
                AppText.body(
                  p.caption,
                  size: 13,
                  color: Colors.grey.shade800,
                  height: 1.5,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Optimized Action Area
                Row(
                  children: [
                    _PillButton(
                      icon: _liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '${p.likes + (_liked ? 1 : 0)}',
                      active: _liked,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _liked = !_liked);
                      },
                    ),
                    const SizedBox(width: 12),
                    _PillButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${p.comments}',
                      onTap: () {},
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'View Trip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.redAccent : Colors.grey.shade600;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? Colors.redAccent.withOpacity(0.05)
              : Colors.transparent,
          border: Border.all(color: color.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data Objects ────────────────────────────────────────────────────────────

class _PostData {
  final String author, location, time, imageUrl, caption;
  final int likes, comments;
  const _PostData({
    required this.author,
    required this.location,
    required this.time,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
  });
}

final _dummyPosts = [
  const _PostData(
    author: 'Aarav Mehta',
    location: 'Mahabaleshwar Peaks',
    time: '2 hours ago',
    imageUrl:
        'https://images.unsplash.com/photo-1590050752117-234cc43a290d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
    caption:
        'The mist rolling over the lake at Venna was surreal. If you are planning to visit, try the early morning boat ride for the best views!',
    likes: 245,
    comments: 18,
  ),
  const _PostData(
    author: 'Isha Deshmukh',
    location: 'Gateway of India',
    time: '5 hours ago',
    imageUrl:
        'https://images.unsplash.com/photo-1548013146-72479768bbaa?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
    caption:
        'Mumbai in the evening is always a vibe. The architecture here tells so many stories. Caught the ferry to Elephanta today!',
    likes: 128,
    comments: 24,
  ),
  const _PostData(
    author: 'Karan Singh',
    location: 'Raigad Fort',
    time: 'Yesterday',
    imageUrl:
        'https://images.unsplash.com/photo-1563234582-74cc2989ccf8?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
    caption:
        'Feeling like royalty at Chhatrapati Shivaji Maharaj\'s capital. The ropeway makes it so easy to access this mountain fortress.',
    likes: 562,
    comments: 42,
  ),
];
