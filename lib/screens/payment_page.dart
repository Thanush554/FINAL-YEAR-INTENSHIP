import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const PaymentPage({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  bool isProcessing = false;
  bool paymentSuccess = false;
  String paymentMethod = "Card";
  late AnimationController _controller;
  String _currentLanguage = 'en';

  // 🌍 Multilingual translations
  final Map<String, Map<String, String>> translations = {
    'en': {
      'payment.title': 'Complete Payment',
      'payment.total': 'Total: ₹{amount}',
      'payment.method': 'Payment Method',
      'payment.card': 'Credit / Debit Card',
      'payment.upi': 'UPI Payment',
      'payment.cod': 'Cash on Delivery',
      'payment.payNow': 'Pay Now',
      'payment.success': 'Payment Successful!',
      'payment.orderPlaced': 'Your order has been placed successfully.',
      'payment.goToHome': 'Go to Home',
      'payment.cartEmpty': 'Cart is Empty',
      'payment.cartEmptyMessage': 'Please add items before proceeding.',
      'payment.failed': 'Payment Failed',
      'payment.ok': 'OK',
    },
    'kn': {
      'payment.title': 'ಪಾವತಿಯನ್ನು ಪೂರ್ಣಗೊಳಿಸಿ',
      'payment.total': 'ಒಟ್ಟು: ₹{amount}',
      'payment.method': 'ಪಾವತಿ ವಿಧಾನ',
      'payment.card': 'ಕ್ರೆಡಿಟ್ / ಡೆಬಿಟ್ ಕಾರ್ಡ್',
      'payment.upi': 'UPI ಪಾವತಿ',
      'payment.cod': 'ಡೆಲಿವರಿ ಮೇಲೆ ನಗದು',
      'payment.payNow': 'ಈಗ ಪಾವತಿಸಿ',
      'payment.success': 'ಪಾವತಿ ಯಶಸ್ವಿಯಾಗಿದೆ!',
      'payment.orderPlaced': 'ನಿಮ್ಮ ಆರ್ಡರ್ ಯಶಸ್ವಿಯಾಗಿ ಇರಿಸಲಾಗಿದೆ.',
      'payment.goToHome': 'ಮುಖಪುಟಕ್ಕೆ ಹೋಗಿ',
      'payment.cartEmpty': 'ಕಾರ್ಟ್ ಖಾಲಿಯಾಗಿದೆ',
      'payment.cartEmptyMessage': 'ಮುಂದುವರಿಯುವ ಮೊದಲು ಐಟಂಗಳನ್ನು ಸೇರಿಸಿ.',
      'payment.failed': 'ಪಾವತಿ ವಿಫಲವಾಗಿದೆ',
      'payment.ok': 'ಸರಿ',
    },
  };

  String t(String key) =>
      translations[_currentLanguage]?[key] ?? translations['en']?[key] ?? key;

  String generateTransactionId() {
    final random = Random();
    return "TXN${random.nextInt(999999999).toString().padLeft(9, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentLanguage = prefs.getString('selectedLanguage') ?? 'en';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> handlePayment() async {
    if (widget.cartItems.isEmpty) {
      _showDialog(t('payment.cartEmpty'), t('payment.cartEmptyMessage'));
      return;
    }

    setState(() => isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final retailerId = prefs.getString("userId");

      if (retailerId == null) {
        throw Exception("User not logged in.");
      }

      // ✅ Create order entry
      final orderResponse = await supabase
          .from("orders")
          .insert({
            "retailer_id": retailerId,
            "total_amount": widget.totalAmount,
            "status": "ordered",
            "created_at": DateTime.now().toUtc().toIso8601String(),
          })
          .select();

      if (orderResponse.isEmpty) throw Exception("Failed to create order.");

      final orderId = orderResponse.first["id"];

      // ✅ Prepare order items safely
      final orderItems = widget.cartItems.map((item) {
        // Parse quantity as double first, then convert to int if needed
        final quantityDouble =
            double.tryParse(item["quantity"].toString()) ?? 0.0;
        final quantity = quantityDouble.toInt(); // Convert to integer
        
        final price =
            double.tryParse(item["price_per_kg"].toString()) ?? 0.0;
        return {
          "order_id": orderId,
          "crop_id": item["crop_id"],
          "quantity": quantity, // Now using integer
          "price_per_kg": price,
          "total_price": quantity * price,
        };
      }).toList();

      // ✅ Insert order items
      await supabase.from("order_items").insert(orderItems);

      // ✅ Insert payment
      final transactionId = generateTransactionId();
      final paymentStatus = paymentMethod == "COD" ? "pending" : "success";

      await supabase.from("payments").insert({
        "order_id": orderId,
        "retailer_id": retailerId,
        "amount": widget.totalAmount,
        "payment_method": paymentMethod,
        "status": paymentStatus,
        "transaction_id": transactionId,
        "created_at": DateTime.now().toUtc().toIso8601String(),
      });

      // ✅ Clear cart (no crash if table missing)
      await supabase.from("cart").delete().eq("retailer_id", retailerId);

      setState(() {
        paymentSuccess = true;
      });
      _controller.forward();
    } catch (e) {
      _showDialog(t('payment.failed'), e.toString());
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('payment.ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get system padding for navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA5D6A7), Color(0xFF81C784), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: paymentSuccess ? _buildSuccessView() : _buildPaymentForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      key: const ValueKey("form"),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payment, size: 60, color: Color(0xFF2E7D32)),
          const SizedBox(height: 15),
          Text(t('payment.title'),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
          const SizedBox(height: 20),
          Text(
            t('payment.total').replaceAll('{amount}', widget.totalAmount.toStringAsFixed(2)),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF33691E)),
          ),
          const SizedBox(height: 30),
          DropdownButtonFormField<String>(
            initialValue: paymentMethod,
            items: [
              DropdownMenuItem(value: "Card", child: Text(t('payment.card'))),
              DropdownMenuItem(value: "UPI", child: Text(t('payment.upi'))),
              DropdownMenuItem(value: "COD", child: Text(t('payment.cod'))),
            ],
            onChanged: (val) => setState(() => paymentMethod = val!),
            decoration: InputDecoration(
              labelText: t('payment.method'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: isProcessing ? null : handlePayment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(t('payment.payNow'),
                    style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: Container(
        key: const ValueKey("success"),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            Text(t('payment.success'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const SizedBox(height: 10),
            Text(t('payment.orderPlaced'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(t('payment.goToHome'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}