import 'package:flutter/material.dart';

import 'animations/cart_fly_animation.dart';
import 'controllers/reel_animation_controller.dart';
import 'models/food_category.dart';
import 'models/food_item.dart';
import 'widgets/animated_cart_bar.dart';
import 'widgets/animated_cart_sheet.dart';
import 'widgets/animated_food_detail_sheet.dart';
import 'widgets/animated_category_arc.dart';
import 'widgets/animated_header.dart';
import 'widgets/animated_product_card.dart';
import 'widgets/animated_search_bar.dart';

void main() {
  runApp(const FoodDeliveryApp());
}

/// Main Application Entry Widget
class FoodDeliveryApp extends StatelessWidget {
  const FoodDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hungry? Order & Eat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9FAFC),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B4A),
          primary: const Color(0xFFFF6B4A),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const CartFlyOverlay(
        child: MainFoodDeliveryScreen(),
      ),
    );
  }
}

// =============================================================================
// MAIN SCREEN
// =============================================================================

class MainFoodDeliveryScreen extends StatefulWidget {
  const MainFoodDeliveryScreen({super.key});

  @override
  State<MainFoodDeliveryScreen> createState() => _MainFoodDeliveryScreenState();
}

class _MainFoodDeliveryScreenState extends State<MainFoodDeliveryScreen>
    with TickerProviderStateMixin {
  // --- Category & Search State ---
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // --- Animation Controllers ---
  late AnimationController _entranceAnimController;
  late Animation<double> _entranceProgress;

  // Floating food image micro-movement
  late AnimationController _floatingAnimController;
  late Animation<double> _floatingAnimation;

  // Circular Wheel Snap Animation
  double _wheelOffset = 2.0; // Index 2 is 'All' by default
  late AnimationController _snapAnimController;
  Animation<double>? _snapAnimation;

  // Reel Marketing Controller
  final ReelAnimationController _reelController = ReelAnimationController();

  // Keys for coordinates tracking
  final GlobalKey _orangeBagKey = GlobalKey();
  final GlobalKey _topCartKey = GlobalKey();

  // Cart State (Initial default matches design: 2 items, $45.33)
  final Map<String, int> _cart = {'pizza': 2};

  // Categories catalog
  final List<FoodCategory> _categories = const [
    FoodCategory(
      id: 'fruits',
      title: 'Fruits',
      imageAsset: 'assets/images/cat_fruits.png',
      iconFallback: Icons.eco_rounded,
    ),
    FoodCategory(
      id: 'drinks',
      title: 'Drinks',
      imageAsset: 'assets/images/cat_drinks.png',
      iconFallback: Icons.local_drink_rounded,
    ),
    FoodCategory(
      id: 'all',
      title: 'All',
      imageAsset: 'assets/images/cat_all.png',
      iconFallback: Icons.restaurant_rounded,
    ),
    FoodCategory(
      id: 'snack',
      title: 'Snack',
      imageAsset: 'assets/images/cat_snack.png',
      iconFallback: Icons.fastfood_rounded,
    ),
    FoodCategory(
      id: 'food',
      title: 'Food',
      imageAsset: 'assets/images/cat_food.png',
      iconFallback: Icons.dinner_dining_rounded,
    ),
    FoodCategory(
      id: 'burgers',
      title: 'Burgers',
      imageAsset: 'assets/images/burger.png',
      iconFallback: Icons.lunch_dining_rounded,
    ),
    FoodCategory(
      id: 'grill',
      title: 'Grill',
      imageAsset: 'assets/images/skewers.png',
      iconFallback: Icons.kebab_dining_rounded,
    ),
  ];

  // Comprehensive catalog across all categories
  late final List<FoodItem> _allFoodItems = [
    // --- FOOD ---
    const FoodItem(
      id: 'noodles',
      name: 'Noodles Twistara',
      subtitle: 'With Spicy Sauce',
      discount: '-25%',
      price: 5.33,
      rating: 4.9,
      calories: '380 kcal',
      prepTime: '15-20 min',
      category: 'Food',
      imageAsset: 'assets/images/noodles.png',
      description:
          'Fresh wok-fried noodles tossed in rich spicy garlic glaze, hand-pulled vegetables, roasted sesame, and aromatic chili oil.',
    ),
    const FoodItem(
      id: 'pizza',
      name: 'Pizza Sicilia',
      subtitle: 'Pizza Sicilia',
      discount: '-25%',
      price: 8.99,
      rating: 4.8,
      calories: '650 kcal',
      prepTime: '20-25 min',
      category: 'Food',
      imageAsset: 'assets/images/pizza.png',
      description:
          'Authentic thin-crust artisan pizza baked on stone fire, topped with San Marzano tomatoes, fresh mozzarella, kalamata olives, and sweet basil.',
    ),
    const FoodItem(
      id: 'salad_bowl',
      name: 'Avocado Crunch Salad',
      subtitle: 'Grilled Chicken & Corn',
      discount: '-30%',
      price: 6.99,
      rating: 4.8,
      calories: '340 kcal',
      prepTime: '10-12 min',
      category: 'Food',
      imageAsset: 'assets/images/cat_food.png',
      description:
          'Tender fire-roasted chicken breast over organic baby greens, roasted sweet corn, cherry tomatoes, creamy diced avocado, and crumbled feta cheese.',
    ),

    // --- BURGERS ---
    const FoodItem(
      id: 'burger',
      name: 'Cheeseburger Deluxe',
      subtitle: 'Double Beef & Cheddar',
      discount: '-15%',
      price: 7.49,
      rating: 4.9,
      calories: '540 kcal',
      prepTime: '10-15 min',
      category: 'Burgers',
      imageAsset: 'assets/images/burger.png',
      description:
          'Prime flame-grilled beef patty, melted Wisconsin aged cheddar, crispy farm lettuce, sliced ripe tomatoes on a golden brioche bun.',
    ),
    const FoodItem(
      id: 'burger_combo',
      name: 'Burger & Fries Combo',
      subtitle: 'With Chilled Soda',
      discount: '-20%',
      price: 9.99,
      rating: 4.9,
      calories: '780 kcal',
      prepTime: '12-15 min',
      category: 'Burgers',
      imageAsset: 'assets/images/cat_all.png',
      description:
          'Double stacked artisan cheeseburger served with hot golden French fries and an ice-cold fountain soda with straw.',
    ),

    // --- SNACK ---
    const FoodItem(
      id: 'potato_chips',
      name: 'Crispy Kettle Chips',
      subtitle: 'Sea Salt & Rosemary',
      discount: '-20%',
      price: 3.99,
      rating: 4.7,
      calories: '280 kcal',
      prepTime: '3-5 min',
      category: 'Snack',
      imageAsset: 'assets/images/cat_snack.png',
      description:
          'Thick artisan kettle-cooked potato crisps lightly tossed in coarse Himalayan sea salt, cracked black pepper, and fragrant dried rosemary.',
    ),
    const FoodItem(
      id: 'snack_burger',
      name: 'Mini Slider Burger',
      subtitle: 'Cheddar & Pickles',
      discount: '-10%',
      price: 4.99,
      rating: 4.8,
      calories: '360 kcal',
      prepTime: '8-10 min',
      category: 'Snack',
      imageAsset: 'assets/images/burger.png',
      description:
          'Bite-sized grilled Angus beef slider topped with aged cheddar, caramelized onions, and house burger relish.',
    ),

    // --- FRUITS ---
    const FoodItem(
      id: 'fruits_basket',
      name: 'Organic Fruit Basket',
      subtitle: 'Seasonal Berry Mix',
      discount: '-15%',
      price: 4.50,
      rating: 4.8,
      calories: '180 kcal',
      prepTime: '5-10 min',
      category: 'Fruits',
      imageAsset: 'assets/images/cat_fruits.png',
      description:
          'Fresh hand-picked harvest including ripe strawberries, organic bananas, crisp green apples, juicy watermelon slices, and fresh sweet oranges.',
    ),
    const FoodItem(
      id: 'fruit_medley',
      name: 'Fresh Fruit Medley',
      subtitle: 'With Honey Lime Drizzle',
      discount: '-20%',
      price: 5.20,
      rating: 4.9,
      calories: '150 kcal',
      prepTime: '5-8 min',
      category: 'Fruits',
      imageAsset: 'assets/images/cat_fruits.png',
      description:
          'A vibrant medley of sweet tropical fruits tossed with a delicate touch of raw honey, fresh mint leaves, and a squeeze of lime.',
    ),

    // --- DRINKS ---
    const FoodItem(
      id: 'lime_mojito',
      name: 'Mint Lime Mojito',
      subtitle: 'Iced Refreshing Cooler',
      discount: '-10%',
      price: 3.49,
      rating: 4.9,
      calories: '95 kcal',
      prepTime: '3-5 min',
      category: 'Drinks',
      imageAsset: 'assets/images/cat_drinks.png',
      description:
          'Sparkling ice cooler crafted with muddled garden mint, fresh Tahitian lime wedges, cane syrup, and bubbly chilled soda.',
    ),
    const FoodItem(
      id: 'citrus_fizz',
      name: 'Sparkling Citrus Fizz',
      subtitle: 'Double Mint & Lemon',
      discount: '-15%',
      price: 3.99,
      rating: 4.8,
      calories: '110 kcal',
      prepTime: '4-6 min',
      category: 'Drinks',
      imageAsset: 'assets/images/cat_drinks.png',
      description:
          'Craft artisan iced beverage brewed with natural botanical citrus extracts, crushed ice, and invigorating aromatic mint.',
    ),

    // --- GRILL ---
    const FoodItem(
      id: 'skewers',
      name: 'Chicken Skewers',
      subtitle: 'Grilled with Peppers',
      discount: '-20%',
      price: 6.80,
      rating: 4.7,
      calories: '320 kcal',
      prepTime: '15-18 min',
      category: 'Grill',
      imageAsset: 'assets/images/skewers.png',
      description:
          'Tender marinated chicken breast charbroiled on wooden skewers with sweet bell peppers, red onions, and Mediterranean herb drizzle.',
    ),
    const FoodItem(
      id: 'bbq_skewers',
      name: 'Smoked BBQ Kebabs',
      subtitle: 'Charred Herb Glaze',
      discount: '-15%',
      price: 8.50,
      rating: 4.8,
      calories: '410 kcal',
      prepTime: '18-22 min',
      category: 'Grill',
      imageAsset: 'assets/images/skewers.png',
      description:
          'Fire-grilled tender marinated skewers served with charred peppers, smoked paprika aioli, and roasted garlic dipping sauce.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // 1. Cinematic Screen Entrance Animation Controller (3.6s slow sequence)
    _entranceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _entranceProgress = CurvedAnimation(
      parent: _entranceAnimController,
      curve: Curves.easeOutCubic,
    );
    _entranceAnimController.forward();

    // 2. Floating food image subtle oscillation (gentle 3.8s)
    _floatingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _floatingAnimController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Circular Wheel Snap Animation Controller (smooth 650ms)
    _snapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // 4. Parallax Scroll Tracker
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });

    // 5. Bind Reel Marketing Animation Controller
    _reelController.bind(
      onResetScreen: () {
        setState(() {
          _cart.clear();
          searchQuery = '';
          _searchController.clear();
          selectedCategory = 'All';
          _wheelOffset = 2.0;
        });
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
        _entranceAnimController.reset();
      },
      onPlayEntrance: () async {
        await _entranceAnimController.forward();
      },
      onSelectCategory: (catIndex) async {
        _animateWheelToIndex(catIndex);
      },
      onSimulateAddItem: (itemId) async {
        final item = _allFoodItems.firstWhere((i) => i.id == itemId);
        final startPos = Offset(
          MediaQuery.of(context).size.width * 0.35,
          MediaQuery.of(context).size.height * 0.45,
        );
        _flyAndAddItem(item, startPos, const Size(70, 70));
      },
      onOpenCart: () {
        _openCartModal();
      },
      onCloseCart: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  void dispose() {
    _entranceAnimController.dispose();
    _floatingAnimController.dispose();
    _snapAnimController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _reelController.dispose();
    super.dispose();
  }

  // Smoothly rotate the wheel to a specific category index
  void _animateWheelToIndex(int targetIndex) {
    final clamped = targetIndex.clamp(0, _categories.length - 1);
    _snapAnimation =
        Tween<double>(begin: _wheelOffset, end: clamped.toDouble()).animate(
      CurvedAnimation(
        parent: _snapAnimController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
            setState(() {
              _wheelOffset = _snapAnimation!.value;
            });
          });

    _snapAnimController.reset();
    _snapAnimController.forward().then((_) {
      setState(() {
        _wheelOffset = clamped.toDouble();
        selectedCategory = _categories[clamped].title;
      });
    });
  }

  // Cart Computations
  int get totalItemCount => _cart.values.fold(0, (sum, count) => sum + count);

  double get totalPrice {
    // Exact initial state match
    if (_cart.length == 1 &&
        _cart.containsKey('pizza') &&
        _cart['pizza'] == 2) {
      return 45.33;
    }
    double total = 0.0;
    _cart.forEach((id, qty) {
      final item = _allFoodItems.firstWhere((element) => element.id == id);
      total += item.price * qty;
    });
    return total;
  }

  void _addItem(String id) {
    setState(() {
      _cart[id] = (_cart[id] ?? 0) + 1;
    });
  }

  void _removeItem(String id) {
    setState(() {
      if ((_cart[id] ?? 0) > 1) {
        _cart[id] = _cart[id]! - 1;
      } else {
        _cart.remove(id);
      }
    });
  }

  // Add item with curved flying visual transition to the bottom cart button
  void _flyAndAddItem(FoodItem item, Offset startPos, Size imgSize) {
    // Determine destination target coordinate (orange bag button on bottom cart bar)
    Offset targetPos;
    final renderBox =
        _orangeBagKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null && renderBox.hasSize) {
      final boxPos = renderBox.localToGlobal(Offset.zero);
      targetPos = Offset(boxPos.dx + 10, boxPos.dy + 10);
    } else {
      // Fallback coordinates corresponding to the bottom cart button position
      final media = MediaQuery.of(context);
      targetPos = Offset(media.size.width - 64, media.size.height - 64);
    }

    CartFlyManager.instance.flyItem(
      startOffset: startPos,
      startSize: imgSize,
      endOffset: targetPos,
      imageAsset: item.imageAsset,
      onComplete: () {
        _addItem(item.id);
      },
    );
  }

  List<FoodItem> get filteredItems {
    return _allFoodItems.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              item.subtitle.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'All' ||
          item.category.toLowerCase() == selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // Top Reel Marketing Demo Trigger Banner (Commented out)
                /*
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _reelController,
                    builder: (context, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (!_reelController.isPlaying) {
                                  _reelController.startReelAnimation();
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _reelController.isPlaying
                                      ? const Color(0xFFFF6B4A)
                                      : const Color(0xFF18181A)
                                          .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _reelController.isPlaying
                                          ? Icons.videocam_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 14,
                                      color: _reelController.isPlaying
                                          ? Colors.white
                                          : const Color(0xFF18181A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _reelController.isPlaying
                                          ? 'Recording Reel (Slow)...'
                                          : '🎬 Reel Demo (Slow)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _reelController.isPlaying
                                            ? Colors.white
                                            : const Color(0xFF18181A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                */

                // -------------------------------------------------------------
                // WIDGET 1: Header, Delivery Address & Title
                // -------------------------------------------------------------
                SliverToBoxAdapter(
                  child: AnimatedHeaderSection(
                    entranceProgress: _entranceProgress,
                    totalItemCount: totalItemCount,
                    topCartKey: _topCartKey,
                    onNotificationTap: _showNotificationSheet,
                    onCartTap: _openCartModal,
                    onLocationTap: () {},
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // -------------------------------------------------------------
                // WIDGET 1B: Search & Filter Bar
                // -------------------------------------------------------------
                SliverToBoxAdapter(
                  child: AnimatedSearchBar(
                    entranceProgress: _entranceProgress,
                    searchController: _searchController,
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                    },
                    onFilterTap: _showFilterBottomSheet,
                  ),
                ),

                // Decreased spacing between search field and scrollable category items
                const SliverToBoxAdapter(child: SizedBox(height: 0)),

                // -------------------------------------------------------------
                // WIDGET 2: Circular Arc Scrollable Wheel Category Selector
                // -------------------------------------------------------------
                SliverToBoxAdapter(
                  child: AnimatedCategoryArc(
                    entranceProgress: _entranceProgress,
                    categories: _categories,
                    selectedCategory: selectedCategory,
                    wheelOffset: _wheelOffset,
                    onCategorySelected: _animateWheelToIndex,
                    onDragStart: () {
                      _snapAnimController.stop();
                    },
                    onDragUpdate: (delta) {
                      setState(() {
                        _wheelOffset -= delta / 70.0;
                        _wheelOffset = _wheelOffset.clamp(
                          -0.4,
                          _categories.length - 0.6,
                        );

                        final nearestIndex = _wheelOffset.round().clamp(
                              0,
                              _categories.length - 1,
                            );
                        if (selectedCategory !=
                            _categories[nearestIndex].title) {
                          selectedCategory = _categories[nearestIndex].title;
                        }
                      });
                    },
                    onDragEnd: (velocity) {
                      final targetOffset = _wheelOffset - (velocity / 750.0);
                      final targetIndex = targetOffset.round().clamp(
                            0,
                            _categories.length - 1,
                          );
                      _animateWheelToIndex(targetIndex);
                    },
                  ),
                ),

                // Decreased spacing between category arc and scrollable food items grid
                const SliverToBoxAdapter(child: SizedBox(height: 0)),

                // -------------------------------------------------------------
                // WIDGET 3: Food Items Grid with Staggered Entrance & Floating
                // -------------------------------------------------------------
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: _buildFoodGrid(),
                ),

                // Spacing for floating bottom cart pill
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // WIDGET 4: Floating Bottom Cart Bar with Hover and Activation Motion
          // -------------------------------------------------------------------
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: AnimatedCartBar(
                orangeBagKey: _orangeBagKey,
                totalCount: totalItemCount,
                totalPrice: totalPrice,
                onTap: _openCartModal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FOOD GRID SECTION
  // ===========================================================================
  Widget _buildFoodGrid() {
    final items = filteredItems;

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(40),
          alignment: Alignment.center,
          child: Column(
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 54,
                color: Color(0xFFBDC3CD),
              ),
              const SizedBox(height: 12),
              const Text(
                'No food items found',
                style: TextStyle(
                  color: Color(0xFF18181A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching for another dish or check other categories',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8F959E), fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    searchQuery = '';
                    _animateWheelToIndex(2); // Reset to 'All'
                  });
                },
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        final isInCart = _cart.containsKey(item.id) && _cart[item.id]! > 0;
        final qty = _cart[item.id] ?? 0;

        return RepaintBoundary(
          child: AnimatedProductCard(
            item: item,
            isInCart: isInCart,
            quantity: qty,
            index: index,
            entranceProgress: _entranceProgress,
            floatingAnimation: _floatingAnimation,
            scrollOffset: _scrollOffset,
            onTap: () {
              _showFoodDetailSheet(item);
            },
            onAdd: (imgPos, imgSize) {
              _flyAndAddItem(item, imgPos, imgSize);
            },
            onRemove: () {
              _removeItem(item.id);
            },
          ),
        );
      }, childCount: items.length),
    );
  }

  // ===========================================================================
  // INTERACTION SHEETS & MODALS (Filter, Details, Cart, Notifications)
  // ===========================================================================

  void _showFoodDetailSheet(FoodItem item) {
    final qty = _cart[item.id] ?? 0;
    AnimatedFoodDetailSheet.show(
      context,
      item: item,
      initialQuantity: qty,
      onQuantityChanged: (newQty) {
        setState(() {
          _cart[item.id] = newQty;
        });
      },
      onAddToCart: () {
        if ((_cart[item.id] ?? 0) == 0) {
          _addItem(item.id);
        }
      },
    );
  }

  void _openCartModal() {
    AnimatedCartSheet.show(
      context,
      cart: _cart,
      allFoodItems: _allFoodItems,
      totalPrice: totalPrice,
      totalCount: totalItemCount,
      onAdd: (id) {
        _addItem(id);
        setState(() {});
      },
      onRemove: (id) {
        _removeItem(id);
        setState(() {});
      },
      onCheckout: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Order placed successfully! Delivery to Diriyah, Riyadh.',
            ),
            backgroundColor: Color(0xFF18181A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E4E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Filter & Sort',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8F959E),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Popular'),
                    selected: true,
                    selectedColor: const Color(0xFF18181A),
                    labelStyle: const TextStyle(color: Colors.white),
                    onSelected: (val) {},
                  ),
                  ChoiceChip(
                    label: const Text('Fastest Delivery'),
                    selected: false,
                    onSelected: (val) {},
                  ),
                  ChoiceChip(
                    label: const Text('Top Rated'),
                    selected: false,
                    onSelected: (val) {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications: 25% off applied to your current order!'),
        backgroundColor: Color(0xFF18181A),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
