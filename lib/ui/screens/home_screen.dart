import 'package:chatterly/theme/colors.dart';
import 'package:chatterly/theme/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../screens/image_gen_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late AnimationController _fabAnimationController;

  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  int _selectedBottomNavIndex = 0;
  bool _isHeaderExpanded = true;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create animations
    _headerSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerAnimationController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _cardsAnimationController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int index,
    Color? iconColor,
    List<Color>? gradientColors,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animationValue) * 50),
          child: Transform.scale(
            scale: 0.8 + (animationValue * 0.2),
            child: Opacity(
              opacity: animationValue,
              child: _buildFeatureCard(
                context,
                icon: icon,
                title: title,
                subtitle: subtitle,
                onTap: onTap,
                iconColor: iconColor,
                gradientColors: gradientColors,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    List<Color>? gradientColors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradientColors != null
                  ? LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: gradientColors == null ? Colors.white : null,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Animated icon container
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 0.1,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors != null
                                ? [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ]
                                : [
                                    (iconColor ?? AppColors.primary)
                                        .withOpacity(0.1),
                                    (iconColor ?? AppColors.primary)
                                        .withOpacity(0.05),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: gradientColors != null
                              ? Border.all(color: Colors.white.withOpacity(0.3))
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: gradientColors != null
                              ? Colors.white
                              : (iconColor ?? AppColors.primary),
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.heading.copyWith(
                          color: gradientColors != null ? Colors.white : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.subtitle.copyWith(
                          color: gradientColors != null
                              ? Colors.white.withOpacity(0.8)
                              : AppTextStyles.subtitle.color,
                        ),
                      ),
                    ],
                  ),
                ),

                // Animated arrow
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(value * 4, 0),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 20,
                        color: gradientColors != null
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isHeaderExpanded = !_isHeaderExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.all(_isHeaderExpanded ? 28 : 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Hello",
                                        style: AppTextStyles.heading.copyWith(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(seconds: 2),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Transform.rotate(
                                            angle: value * 0.5,
                                            child: const Text(
                                              "👋",
                                              style: TextStyle(fontSize: 24),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedCrossFade(
                                    duration: const Duration(milliseconds: 300),
                                    crossFadeState: _isHeaderExpanded
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    firstChild: Text(
                                      "Welcome to your AI-powered assistant app. Explore amazing features and unlock your creativity!",
                                      style: AppTextStyles.subtitle.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.4,
                                      ),
                                    ),
                                    secondChild: Text(
                                      "Your AI assistant is ready!",
                                      style: AppTextStyles.subtitle.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 300),
                              turns: _isHeaderExpanded ? 0 : 0.5,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white.withOpacity(0.8),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        if (_isHeaderExpanded) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Tip: Try asking me creative questions!",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                "Chatterly",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Welcome header
                _buildWelcomeHeader(),

                const SizedBox(height: 10),

                // Feature cards with staggered animation
                _buildAnimatedFeatureCard(
                  context,
                  icon: LucideIcons.messageSquare,
                  title: "AI Chat",
                  subtitle: "Start a conversation with your AI assistant",
                  onTap: () {
                    Navigator.pushNamed(context, '/chat');
                  },
                  index: 0,
                  iconColor: const Color(0xFF4285F4),
                ),

                _buildAnimatedFeatureCard(
                  context,
                  icon: LucideIcons.image,
                  title: "Image Generator",
                  subtitle: "Create stunning AI-generated artwork",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImageGenScreen(),
                      ),
                    );
                  },
                  index: 1,
                  gradientColors: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),

                _buildAnimatedFeatureCard(
                  context,
                  icon: LucideIcons.fileText,
                  title: "Content Generator",
                  subtitle: "Generate creative content and ideas",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Content Generator coming soon!"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  index: 2,
                  gradientColors: const [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),

                _buildAnimatedFeatureCard(
                  context,
                  icon: LucideIcons.languages,
                  title: "Language Translator",
                  subtitle: "Translate text between multiple languages",
                  onTap: () {
                    Navigator.pushNamed(context, '/translator');
                  },
                  index: 3,
                  gradientColors: const [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                ),

                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ],
      ),

      // Enhanced bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedBottomNavIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedBottomNavIndex = index;
            });

            switch (index) {
              case 0:
                // Already on home
                break;
              case 1:
                Navigator.pushNamed(context, '/chat');
                break;
              case 2:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Settings coming soon!"),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                break;
            }
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }
}
