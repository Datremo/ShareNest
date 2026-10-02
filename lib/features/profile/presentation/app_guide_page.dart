import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/theme/app_colors.dart';

class AppGuidePage extends StatefulWidget {
  const AppGuidePage({super.key});

  @override
  State<AppGuidePage> createState() => _AppGuidePageState();
}

class _AppGuidePageState extends State<AppGuidePage> {
  int _expandedIndex = 0;

  final List<_ManualSection> _sections = [
    _ManualSection(
      title: 'Finding & Requesting Items',
      icon: Icons.search_rounded,
      color: const Color(0xFF0EA5E9),
      steps: [
        'Explore the Map: Browse nearby posts for LEND (borrow), GIVE (free), or EXCHANGE (trade).',
        'Send a Request: Found what you need? Tap it and request. For Lends, pick your dates. For Exchanges, pick one of your own items to offer in return.',
        'Coordinate: Once the owner approves your request, a private chat opens so you can agree on a time and place to meet.',
      ],
    ),
    _ManualSection(
      title: 'Sharing Your Items',
      icon: Icons.add_circle_outline,
      color: const Color(0xFF10B981),
      steps: [
        'Create a Post: Tap the + button to list an item.',
        'Choose a Mode: \n• LEND: Let neighbors borrow things (tools, ladders).\n• GIVE: Declutter by giving items away.\n• EXCHANGE: Trade your item for another.',
        'Approve Requests: When a neighbor requests your item, review it. If it looks good, tap Accept and chat to arrange the handoff.',
      ],
    ),
    _ManualSection(
      title: 'SOS! "Need it Now" Signals',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFEF4444),
      steps: [
        'Emergency Need: If you urgently need something (like jumper cables), tap the red "Need it Now" button to broadcast an SOS signal.',
        'Live Radar: Neighbors will see your SOS on their Live Radar map and can send you an Offer to lend or give you the item.',
        'Accepting Offers: Review offers from helpers. Once you Accept an offer, the SOS becomes a transaction and chat opens to coordinate.',
      ],
    ),
    _ManualSection(
      title: 'Handoffs & Returns',
      icon: Icons.handshake_rounded,
      color: const Color(0xFFF59E0B),
      steps: [
        'Meet in Person: All sharing happens in real life. Use the app chat to pick a safe, public spot or a neighbor\'s porch.',
        'Track the Status: As the Owner, tap "Mark as Handed Over" when you give the item. When the borrower returns it, tap "Mark as Returned".',
        'Accountability: Keeping track of the item status ensures everyone knows who has what, keeping the neighborhood safe.',
      ],
    ),
    _ManualSection(
      title: 'Building Your Trust Score',
      icon: Icons.verified_user_rounded,
      color: const Color(0xFF8B5CF6),
      steps: [
        'What is it? Your Trust Score shows neighbors how reliable you are.',
        'Earn Trust: You build your score by successfully completing shares, returning borrowed items on time, and helping with SOS requests.',
        'Reap Rewards: A high Trust Score makes neighbors much more likely to approve your requests and lend you valuable items!',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'How to Use ShareNest',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: AnimationLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 500),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                Text(
                  'The Official Manual 📖',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Everything you need to know about sharing, borrowing, and helping out in your neighborhood.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                ...List.generate(_sections.length, (index) {
                  return _buildManualCard(_sections[index], index);
                }),
                
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Ready to be a great neighbor?',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Let\'s Go!',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualCard(_ManualSection section, int index) {
    final isExpanded = _expandedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? -1 : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isExpanded ? section.color.withValues(alpha: 0.5) : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: isExpanded ? section.color.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: section.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(section.icon, color: section.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      section.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
            
            // Expanded Content
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(section.steps.length, (stepIndex) {
                    final stepText = section.steps[stepIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: section.color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${stepIndex + 1}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stepText,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF334155),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> steps;

  _ManualSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.steps,
  });
}
