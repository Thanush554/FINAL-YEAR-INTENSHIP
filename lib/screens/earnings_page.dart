import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  List<Map<String, dynamic>> earnings = [];
  bool loading = true;
  bool hasError = false;
  String _currentLanguage = 'en'; // Default language

  // Translation map with multiple languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'loadingEarnings': 'Loading earnings...',
      'earnings': 'Earnings',
      'earningsSummary': 'Earnings Summary',
      'totalOrders': 'Total Orders',
      'totalEarnings': 'Total Earnings',
      'noEarningsFound': 'No earnings found',
      'noEarningsSubtitle': 'You haven\'t made any sales yet',
      'orderId': 'Order ID: {id}',
      'unknownCrop': 'Unknown Crop',
      'quantity': 'Quantity: {quantity} kg',
      'pricePerKg': 'Price: ₹{price}/kg',
      'total': 'Total: ₹{total}',
      'status': 'Status: {status}',
      'lastUpdated': 'Last Updated: {date}',
      'unknownDate': 'Unknown Date',
      'errorLoading': 'Error loading earnings',
      'retry': 'Retry',
    },
    'kn': {
      'loadingEarnings': 'ಗಳಿಕೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'earnings': 'ಗಳಿಕೆಗಳು',
      'earningsSummary': 'ಗಳಿಕೆಗಳ ಸಾರಾಂಶ',
      'totalOrders': 'ಒಟ್ಟು ಆದೇಶಗಳು',
      'totalEarnings': 'ಒಟ್ಟು ಗಳಿಕೆಗಳು',
      'noEarningsFound': 'ಯಾವುದೇ ಗಳಿಕೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ',
      'noEarningsSubtitle': 'ನೀವು ಇನ್ನೂ ಯಾವುದೇ ಮಾರಾಟಗಳನ್ನು ಮಾಡಿಲ್ಲ',
      'orderId': 'ಆದೇಶ ID: {id}',
      'unknownCrop': 'ತಿಳಿಯದ ಬೆಳೆ',
      'quantity': 'ಪ್ರಮಾಣ: {quantity} ಕೆಜಿ',
      'pricePerKg': 'ಬೆಲೆ: ₹{price}/ಕೆಜಿ',
      'total': 'ಒಟ್ಟು: ₹{total}',
      'status': 'ಸ್ಥಿತಿ: {status}',
      'lastUpdated': 'ಕೊನೆಯ ಬಾರಿಗೆ ನವೀಕರಿಸಿದ: {date}',
      'unknownDate': 'ತಿಳಿಯದ ದಿನಾಂಕ',
      'errorLoading': 'ಗಳಿಕೆಗಳನ್ನು ಲೋಡ್ ಮಾಡುವಲ್ಲಿ ದೋಷ',
      'retry': 'ಮರುಪ್ರಯತ್ನಿಸಿ',
    },
    'hi': {
      'loadingEarnings': 'आय लोड हो रही है...',
      'earnings': 'आय',
      'earningsSummary': 'आय सारांश',
      'totalOrders': 'कुल ऑर्डर',
      'totalEarnings': 'कुल आय',
      'noEarningsFound': 'कोई आय नहीं मिली',
      'noEarningsSubtitle': 'आपने अभी तक कोई बिक्री नहीं की है',
      'orderId': 'ऑर्डर ID: {id}',
      'unknownCrop': 'अज्ञात फसल',
      'quantity': 'मात्रा: {quantity} किग्रा',
      'pricePerKg': 'कीमत: ₹{price}/किग्रा',
      'total': 'कुल: ₹{total}',
      'status': 'स्थिति: {status}',
      'lastUpdated': 'अंतिम अपडेट: {date}',
      'unknownDate': 'अज्ञात तिथि',
      'errorLoading': 'आय लोड करने में त्रुटि',
      'retry': 'पुन: प्रयास करें',
    },
    'te': {
      'loadingEarnings': 'ఆదాయాలు లోడ్ అవుతున్నాయి...',
      'earnings': 'ఆదాయాలు',
      'earningsSummary': 'ఆదాయాల సారాంశం',
      'totalOrders': 'మొత్తం ఆర్డర్లు',
      'totalEarnings': 'మొత్తం ఆదాయాలు',
      'noEarningsFound': 'ఏ ఆదాయాలు కనుగొనబడలేదు',
      'noEarningsSubtitle': 'మీరు ఇంకా ఎలాంటి అమ్మకాలు చేయలేదు',
      'orderId': 'ఆర్డర్ ID: {id}',
      'unknownCrop': 'తెలియని పంట',
      'quantity': 'పరిమాణం: {quantity} కిలోలు',
      'pricePerKg': 'ధర: ₹{price}/కిలో',
      'total': 'మొత్తం: ₹{total}',
      'status': 'స్థితి: {status}',
      'lastUpdated': 'చివరిగా నవీకరించబడినది: {date}',
      'unknownDate': 'తెలియని తేదీ',
      'errorLoading': 'ఆదాయాలను లోడ్ చేయడంలో లోపం',
      'retry': 'మళ్ళీ ప్రయత్నించండి',
    },
    'ta': {
      'loadingEarnings': 'வருமானம் ஏற்றப்படுகிறது...',
      'earnings': 'வருமானம்',
      'earningsSummary': 'வருமான சுருக்கம்',
      'totalOrders': 'மொத்த ஆர்டர்கள்',
      'totalEarnings': 'மொத்த வருமானம்',
      'noEarningsFound': 'வருமானம் எதுவும் கிடைக்கவில்லை',
      'noEarningsSubtitle': 'நீங்கள் இதுவரை எந்த விற்பனையும் செய்யவில்லை',
      'orderId': 'ஆர்டர் ID: {id}',
      'unknownCrop': 'தெரியாத பயிர்',
      'quantity': 'அளவு: {quantity} கிலோ',
      'pricePerKg': 'விலை: ₹{price}/கிலோ',
      'total': 'மொத்தம்: ₹{total}',
      'status': 'நிலை: {status}',
      'lastUpdated': 'கடைசியாக புதுப்பிக்கப்பட்டது: {date}',
      'unknownDate': 'தெரியாத தேதி',
      'errorLoading': 'வருமானத்தை ஏற்றுவதில் பிழை',
      'retry': 'மீண்டும் முயற்சி செய்',
    },
  };

  // Function to get translation based on current language
  String t(String key) {
    return translations[_currentLanguage]?[key] ?? translations['en']![key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    fetchEarnings();
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

  Future<void> fetchEarnings() async {
    try {
      setState(() {
        loading = true;
        hasError = false;
      });

      final prefs = await SharedPreferences.getInstance();
      final farmerId = prefs.getString('userId');
      
      if (farmerId == null) {
        setState(() {
          loading = false;
          hasError = true;
        });
        return;
      }

      // Fixed: Use a different approach to order by orders.created_at
      final response = await Supabase.instance.client
          .from('order_items')
          .select('''
            *,
            orders!inner(*),
            produce!inner(*)
          ''')
          .eq('produce.farmer_id', farmerId)
          .order('id', ascending: false); // Using id column from order_items instead

      setState(() {
        earnings = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
        } catch (err) {
      print('Error fetching earnings: $err');
      setState(() {
        loading = false;
        hasError = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('errorLoading')}: ${err.toString()}')),
        );
      }
    }
  }

  Map<String, dynamic> calculateSummary() {
    if (earnings.isEmpty) {
      return {'totalOrders': 0, 'totalEarnings': 0.0};
    }
    
    final uniqueOrderIds = <String>{};
    double totalEarnings = 0.0;
    
    for (final item in earnings) {
      final orderId = item['order_id']?.toString();
      if (orderId != null) uniqueOrderIds.add(orderId);
      
      final totalPrice = item['total_price']?.toString() ?? '0';
      totalEarnings += double.tryParse(totalPrice) ?? 0.0;
    }
    
    return {
      'totalOrders': uniqueOrderIds.length,
      'totalEarnings': totalEarnings,
    };
  }

  @override
  Widget build(BuildContext context) {
    final summary = calculateSummary();

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1),
      appBar: AppBar(
        title: Text(
          t('earnings'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2D6A4F),
        elevation: 0,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00AAFF)),
                  ),
                  const SizedBox(height: 10),
                  Text(t('loadingEarnings')),
                ],
              ),
            )
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('errorLoading'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: fetchEarnings,
                        child: Text(t('retry')),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      _buildSummaryCard(summary),
                      const SizedBox(height: 20),
                      earnings.isEmpty
                          ? _buildEmptyState()
                          : _buildEarningsList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF40916C), Color(0xFF95D5B2)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            t('earningsSummary'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Total Orders
              Expanded(
                child: Column(
                  children: [
                    Text(
                      summary['totalOrders'].toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t('totalOrders'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE0F2E9),
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              // Total Earnings
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '₹${summary['totalEarnings'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t('totalEarnings'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE0F2E9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Color(0xFFB0BEC5),
          ),
          const SizedBox(height: 16),
          Text(
            t('noEarningsFound'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('noEarningsSubtitle'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsList() {
    return Column(
      children: earnings.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFE6F0EF)],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID
                    Text(
                      t('orderId').replaceAll('{id}', item['order_id']?.toString() ?? ''),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 5),
                    
                    // Crop Name
                    Text(
                      item['produce']?['crop_name'] ?? t('unknownCrop'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Quantity
                    Text(
                      t('quantity').replaceAll('{quantity}', item['quantity']?.toString() ?? '0'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Price per kg
                    Text(
                      t('pricePerKg').replaceAll('{price}', item['price_per_kg']?.toString() ?? '0'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Total
                    Text(
                      t('total').replaceAll('{total}', item['total_price']?.toString() ?? '0'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Status
                    Text(
                      t('status').replaceAll('{status}', item['orders']?['status'] ?? 'unknown'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: (item['orders']?['status'] == 'delivered' || 
                                item['orders']?['status'] == 'completed')
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF6B6B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Last Updated
                    Text(
                      t('lastUpdated').replaceAll(
                        '{date}',
                        item['orders']?['updated_at'] != null
                            ? _formatDateTime(item['orders']['updated_at'])
                            : t('unknownDate'),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Crop Image
              if (item['produce']?['image_url'] != null)
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['produce']['image_url'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return t('unknownDate');
    }
  }
}