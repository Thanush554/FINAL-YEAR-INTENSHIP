import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===============================
/// Animated Order Progress Bar (with Flutter Icons)
/// ===============================
class OrderProgressBar extends StatefulWidget {
  final String initialStatus;
  final String orderId;
  final String language;

  const OrderProgressBar({
    super.key,
    required this.initialStatus,
    required this.orderId,
    required this.language,
  });

  @override
  State<OrderProgressBar> createState() => _OrderProgressBarState();
}

class _OrderProgressBarState extends State<OrderProgressBar>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  final List<String> stages = ["ordered", "packed", "shipped", "delivered"];
  late AnimationController _controller;
  late Animation<double> _animation;
  late int currentStageIndex;
  Timer? _autoUpdateTimer;

  // Translation map with 5 languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'orders.ordered': 'Ordered',
      'orders.packed': 'Packed',
      'orders.shipped': 'Shipped',
      'orders.delivered': 'Delivered',
    },
    'kn': {
      'orders.ordered': 'ಆರ್ಡರ್',
      'orders.packed': 'ಪ್ಯಾಕ್',
      'orders.shipped': 'ರವಾನೆ',
      'orders.delivered': 'ವಿತರಿಸಲಾಗಿದೆ',
    },
    'hi': {
      'orders.ordered': 'ऑर्डर',
      'orders.packed': 'पैक',
      'orders.shipped': 'शिप',
      'orders.delivered': 'डिलीवर',
    },
    'te': {
      'orders.ordered': 'ఆర్డర్',
      'orders.packed': 'ప్యాక్',
      'orders.shipped': 'షిప్',
      'orders.delivered': 'డెలివర్',
    },
    'ta': {
      'orders.ordered': 'ஆர்டர்',
      'orders.packed': 'பேக்',
      'orders.shipped': 'ஷிப்',
      'orders.delivered': 'டெலிவரி',
    },
  };

  // Function to get translation based on current language
  String t(String key) {
    return translations[widget.language]?[key] ?? translations['en']?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    currentStageIndex = stages.indexOf(widget.initialStatus);
    if (currentStageIndex < 0) currentStageIndex = 0;
    _initAnimation();
    _startAutoProgression();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = Tween<double>(
      begin: 0,
      end: currentStageIndex / (stages.length - 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  void _startAutoProgression() {
    if (currentStageIndex >= stages.length - 1) return;

    _autoUpdateTimer =
        Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (currentStageIndex < stages.length - 1) {
        currentStageIndex++;
        await _updateStatusInDatabase(stages[currentStageIndex]);
        setState(() {
          _animation = Tween<double>(
            begin: _animation.value,
            end: currentStageIndex / (stages.length - 1),
          ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
          _controller.forward(from: 0);
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _updateStatusInDatabase(String newStatus) async {
    try {
      await supabase.from('orders').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.orderId);
      print("✅ Order ${widget.orderId} updated to $newStatus");
    } catch (e) {
      print("❌ Error updating order status: $e");
    }
  }

  Color getStageColor(String stage) {
    switch (stage) {
      case "ordered":
        return Colors.blue.shade700;
      case "packed":
        return Colors.indigo.shade700;
      case "shipped":
        return Colors.cyan.shade700;
      case "delivered":
        return Colors.green.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  /// Flutter icons for each stage
  IconData getStageIcon(String stage) {
    switch (stage) {
      case "ordered":
        return Icons.shopping_cart;
      case "packed":
        return Icons.inventory_2;
      case "shipped":
        return Icons.local_shipping;
      case "delivered":
        return Icons.verified;
      default:
        return Icons.circle;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// Grey background line
          Positioned(
            top: 40,
            left: 30,
            right: 30,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          /// Animated progress line
          Positioned(
            top: 40,
            left: 30,
            right: 30,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (_, __) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _animation.value,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          getStageColor(stages[currentStageIndex]),
                          getStageColor(stages.last).withOpacity(0.6)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),

          /// Stage Icons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stages.map((stage) {
              final index = stages.indexOf(stage);
              final isActive = index <= currentStageIndex;
              final isCurrent = index == currentStageIndex;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? getStageColor(stage) : Colors.white,
                      border: Border.all(
                        color: getStageColor(stage),
                        width: 2,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: getStageColor(stage).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        getStageIcon(stage),
                        color: isActive
                            ? Colors.white
                            : getStageColor(stage).withOpacity(0.7),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('orders.$stage'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent
                          ? getStageColor(stage)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// Orders Page with Crop Images
/// ===============================
class AmazonStyleOrderPage extends StatefulWidget {
  const AmazonStyleOrderPage({super.key});

  @override
  State<AmazonStyleOrderPage> createState() => _AmazonStyleOrderPageState();
}

class _AmazonStyleOrderPageState extends State<AmazonStyleOrderPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool loading = true;
  List<dynamic> orders = [];
  String retailerName = "";
  String _currentLanguage = 'en'; // Default language
  String? _expandedOrderId; // Track which order is expanded

  // Translation map with 5 languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'orders.title': "Your Orders",
      'orders.retailerOrders': "{name}'s Orders",
      'orders.orderId': "Order #",
      'orders.noImage': "No Image",
      'orders.unknownCrop': "Unknown Crop",
      'orders.ordered': "ORDERED",
      'orders.packed': "PACKED",
      'orders.shipped': "SHIPPED",
      'orders.delivered': "DELIVERED",
      'orders.productDetails': "Product Details",
      'orders.description': "Description",
      'orders.pricePerKg': "Price per kg",
      'orders.quantity': "Quantity",
      'orders.total': "Total",
      'orders.noDescriptionAvailable': "No description available",
    },
    'kn': {
      'orders.title': "ನಿಮ್ಮ ಆದೇಶಗಳು",
      'orders.retailerOrders': "{name} ಅವರ ಆದೇಶಗಳು",
      'orders.orderId': "ಆದೇಶ #",
      'orders.noImage': "ಚಿತ್ರ ಇಲ್ಲ",
      'orders.unknownCrop': "ತಿಳಿಯದ ಬೆಳೆ",
      'orders.ordered': "ಆರ್ಡರ್ ಮಾಡಲಾಗಿದೆ",
      'orders.packed': "ಪ್ಯಾಕ್ ಮಾಡಲಾಗಿದೆ",
      'orders.shipped': "ರವಾನೆ ಮಾಡಲಾಗಿದೆ",
      'orders.delivered': "ವಿತರಿಸಲಾಗಿದೆ",
      'orders.productDetails': "ಉತ್ಪನ್ನ ವಿವರಗಳು",
      'orders.description': "ವಿವರಣೆ",
      'orders.pricePerKg': "ಪ್ರತಿ ಕೆಜಿ ಬೆಲೆ",
      'orders.quantity': "ಪ್ರಮಾಣ",
      'orders.total': "ಒಟ್ಟು",
      'orders.noDescriptionAvailable': "ಯಾವುದೇ ವಿವರಣೆ ಲಭ್ಯವಿಲ್ಲ",
    },
    'hi': {
      'orders.title': "आपके ऑर्डर",
      'orders.retailerOrders': "{name} के ऑर्डर",
      'orders.orderId': "ऑर्डर #",
      'orders.noImage': "कोई इमेज नहीं",
      'orders.unknownCrop': "अज्ञात फसल",
      'orders.ordered': "ऑर्डर किया गया",
      'orders.packed': "पैक किया गया",
      'orders.shipped': "शिप किया गया",
      'orders.delivered': "डिलीवर किया गया",
      'orders.productDetails': "उत्पाद विवरण",
      'orders.description': "विवरण",
      'orders.pricePerKg': "प्रति किलो कीमत",
      'orders.quantity': "मात्रा",
      'orders.total': "कुल",
      'orders.noDescriptionAvailable': "कोई विवरण उपलब्ध नहीं",
    },
    'te': {
      'orders.title': "మీ ఆర్డర్లు",
      'orders.retailerOrders': "{name} ఆర్డర్లు",
      'orders.orderId': "ఆర్డర్ #",
      'orders.noImage': "చిత్ర లేదు",
      'orders.unknownCrop': "తెలియని పంట",
      'orders.ordered': "ఆర్డర్ చేయబడింది",
      'orders.packed': "ప్యాక్ చేయబడింది",
      'orders.shipped': "షిప్ చేయబడింది",
      'orders.delivered': "డెలివర్ చేయబడింది",
      'orders.productDetails': "ఉత్పత్తి వివరాలు",
      'orders.description': "వివరణ",
      'orders.pricePerKg': "కిలోకు ధర",
      'orders.quantity': "పరిమాణం",
      'orders.total': "మొత్తం",
      'orders.noDescriptionAvailable': "వివరణ అందుబాటులో లేదు",
    },
    'ta': {
      'orders.title': "உங்கள் ஆர்டர்கள்",
      'orders.retailerOrders': "{name} ஆர்டர்கள்",
      'orders.orderId': "ஆர்டர் #",
      'orders.noImage': "படம் இல்லை",
      'orders.unknownCrop': "தெரியாத பயிர்",
      'orders.ordered': "ஆர்டர் செய்யப்பட்டது",
      'orders.packed': "பேக் செய்யப்பட்டது",
      'orders.shipped': "ஷிப் செய்யப்பட்டது",
      'orders.delivered': "டெலிவரி செய்யப்பட்டது",
      'orders.productDetails': "தயாரிப்பு விவரங்கள்",
      'orders.description': "விளக்கம்",
      'orders.pricePerKg': "கிலோவுக்கு விலை",
      'orders.quantity': "அளவு",
      'orders.total': "மொத்தம்",
      'orders.noDescriptionAvailable': "விளக்கம் இல்லை",
    },
  };

  // Function to get translation based on current language
  String t(String key, {Map<String, dynamic>? params}) {
    String text = translations[_currentLanguage]?[key] ?? translations['en']?[key] ?? key;
    
    // Replace parameters if provided
    if (params != null) {
      params.forEach((key, value) {
        text = text.replaceAll('{$key}', value.toString());
      });
    }
    
    return text;
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _fetchOrdersWithImages();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('selectedLanguage') ?? 'en';
      setState(() {
        _currentLanguage = language;
      });
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<String?> _getRetailerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  /// Fetch all orders + crop images using JOIN
  Future<void> _fetchOrdersWithImages() async {
    try {
      setState(() => loading = true);
      final retailerId = await _getRetailerId();
      if (retailerId == null) return;

      final profileResponse = await supabase
          .from('profiles')
          .select('name')
          .eq('id', retailerId)
          .maybeSingle();
      retailerName = profileResponse?['name'] ?? "Retailer";

      final response = await supabase
          .from('orders')
          .select(
              'id, status, created_at, order_items(quantity, price_per_kg, total_price, produce(crop_name, image_url, description))')
          .eq('retailer_id', retailerId)
          .order('created_at', ascending: false);

      setState(() {
        orders = response as List<dynamic>;
        loading = false;
      });
    } catch (e) {
      print("❌ Error fetching orders with images: $e");
      setState(() => loading = false);
    }
  }

  Color getCardColor(String status) {
    switch (status) {
      case "ordered":
        return Colors.blue.shade50;
      case "packed":
        return Colors.indigo.shade50;
      case "shipped":
        return Colors.cyan.shade50;
      case "delivered":
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  String formatDate(String dateStr) {
    final dt = DateTime.parse(dateStr);
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  void _toggleOrderDetails(String orderId) {
    setState(() {
      if (_expandedOrderId == orderId) {
        _expandedOrderId = null;
      } else {
        _expandedOrderId = orderId;
      }
    });
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final orderItems = order['order_items'] as List<dynamic>;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('orders.productDetails'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              IconButton(
                onPressed: () => _toggleOrderDetails(order['id'].toString()),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Show all order items
          Column(
            children: orderItems.map((item) {
              final produce = item['produce'] as Map<String, dynamic>;
              final cropName = produce['crop_name'] ?? t('orders.unknownCrop');
              final imageUrl = produce['image_url'] ?? "";
              final description = produce['description'] ?? "";
              final quantity = item['quantity'] ?? 0;
              final pricePerKg = item['price_per_kg'] ?? 0.0;
              final totalPrice = item['total_price'] ?? 0.0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Crop image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: Text(t('orders.noImage')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Crop name
                    Text(
                      cropName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        t('orders.description'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Price and quantity info
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            t('orders.pricePerKg'),
                            '₹${pricePerKg.toStringAsFixed(2)}',
                            Icons.money,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            t('orders.quantity'),
                            '$quantity kg',
                            Icons.inventory_2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Total price
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('orders.total'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            retailerName.isNotEmpty 
                ? t('orders.retailerOrders', params: {'name': retailerName})
                : t('orders.title')),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final orderIdStr = order['id'].toString();
                final displayId = orderIdStr.length >= 6
                    ? orderIdStr.substring(0, 6)
                    : orderIdStr;
                final isExpanded = _expandedOrderId == orderIdStr;

                String imageUrl = "";
                String cropName = t('orders.unknownCrop');
                if (order['order_items'] != null &&
                    (order['order_items'] as List).isNotEmpty) {
                  final firstItem = order['order_items'][0];
                  cropName = firstItem['produce']?['crop_name'] ?? t('orders.unknownCrop');
                  imageUrl = firstItem['produce']?['image_url'] ?? "";
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: getCardColor(order['status']),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('orders.orderId') + displayId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            t('orders.${order['status']}'),
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(" ${formatDate(order['created_at'])}",
                          style: const TextStyle(color: Colors.black54)),
                      const Divider(height: 25, thickness: 0.8),

                      /// Crop Image and Name
                      GestureDetector(
                        onTap: () => _toggleOrderDetails(orderIdStr),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 80,
                                  width: 80,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: Text(t('orders.noImage')),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cropName,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        isExpanded 
                                            ? Icons.keyboard_arrow_up 
                                            : Icons.keyboard_arrow_down,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isExpanded 
                                            ? t('orders.productDetails') 
                                            : "View details",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Animated Progress Bar
                      OrderProgressBar(
                        initialStatus: order['status'],
                        orderId: order['id'].toString(),
                        language: _currentLanguage,
                      ),
                      
                      // Detailed view when expanded
                      if (isExpanded) _buildOrderDetails(order),
                    ],
                  ),
                );
              },
            ),
    );
  }
}