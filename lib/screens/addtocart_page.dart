import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// --------------------
/// MODEL CLASSES
/// --------------------
class CartItem {
  final String id;
  final String cropId;
  final int quantity;
  final double pricePerKg;
  final double totalPrice;
  final Produce? produce;

  CartItem({
    required this.id,
    required this.cropId,
    required this.quantity,
    required this.pricePerKg,
    required this.totalPrice,
    this.produce,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'].toString(),
      cropId: json['crop_id'].toString(),
      quantity: json['quantity'] ?? 0,
      pricePerKg: (json['price_per_kg'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      produce: json['produce'] != null
          ? Produce.fromJson(json['produce'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_id': cropId,
        'quantity': quantity,
        'price_per_kg': pricePerKg,
        'total_price': totalPrice,
        'produce': produce?.toJson(),
      };
}

class Produce {
  final String id;
  final String cropName;
  final String? imageUrl;
  final String farmerId;
  final int quantity;
  final String? description; // Added description field

  Produce({
    required this.id,
    required this.cropName,
    this.imageUrl,
    required this.farmerId,
    required this.quantity,
    this.description, // Added description field
  });

  factory Produce.fromJson(Map<String, dynamic> json) {
    return Produce(
      id: json['id'].toString(),
      cropName: json['crop_name'] ?? '',
      imageUrl: json['image_url'],
      farmerId: json['farmer_id'].toString(),
      quantity: json['quantity'] ?? 0,
      description: json['description'], // Added description field
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_name': cropName,
        'image_url': imageUrl,
        'farmer_id': farmerId,
        'quantity': quantity,
        'description': description, // Added description field
      };
}

/// --------------------
/// TRANSLATION CLASS
/// --------------------
class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'cart.title': 'Your Cart 🛒',
      'cart.empty': 'Your cart is empty 🛒',
      'cart.total': 'Total:',
      'cart.proceedToPayment': 'Proceed to Payment',
      'cart.item.unknownCrop': 'Unknown Crop',
      'cart.item.pricePerKg': '/ kg',
      'cart.item.stockAvailable': 'Stock Available:',
      'cart.item.itemTotal': 'Item Total:',
      'cart.item.negotiate': 'Negotiate',
      'cart.item.productDetails': 'Product Details',
      'cart.item.description': 'Description',
      'cart.item.pricePerKgLabel': 'Price per kg',
      'cart.item.availableStock': 'Available Stock',
      'cart.item.quantityInCart': 'Quantity in Cart:',
      'cart.item.totalPrice': 'Total Price:',
      'cart.item.negotiatePrice': 'Negotiate Price',
      'cart.item.removeItem': 'Remove Item',
      'cart.error.stockLimit': 'Only {stock} kg available in stock',
      'cart.error.updateQuantity': 'Failed to update quantity: {error}',
      'cart.error.removeItem': 'Failed to remove item: {error}',
      'cart.error.emptyCart': 'Your cart is empty',
      'cart.error.negotiation': 'Failed to open negotiation: {error}',
    },
    'kn': {
      'cart.title': 'ನಿಮ್ಮ ಕಾರ್ಟ್ 🛒',
      'cart.empty': 'ನಿಮ್ಮ ಕಾರ್ಟ್ ಖಾಲಿ ಇದೆ 🛒',
      'cart.total': 'ಒಟ್ಟು:',
      'cart.proceedToPayment': 'ಪಾವತಿಗೆ ಮುಂದುವರಿಸಿ',
      'cart.item.unknownCrop': 'ತಿಳಿಯದ ಬೆಳೆ',
      'cart.item.pricePerKg': '/ ಕೆಜಿ',
      'cart.item.stockAvailable': 'ಲಭ್ಯ ಸ್ಟಾಕ್:',
      'cart.item.itemTotal': 'ಐಟಂ ಒಟ್ಟು:',
      'cart.item.negotiate': 'ಸಂಧಾನ ಮಾಡಿ',
      'cart.item.productDetails': 'ಉತ್ಪನ್ನ ವಿವರಗಳು',
      'cart.item.description': 'ವಿವರಣೆ',
      'cart.item.pricePerKgLabel': 'ಪ್ರತಿ ಕೆಜಿ ಬೆಲೆ',
      'cart.item.availableStock': 'ಲಭ್ಯ ಸ್ಟಾಕ್',
      'cart.item.quantityInCart': 'ಕಾರ್ಟ್‌ನಲ್ಲಿನ ಪ್ರಮಾಣ:',
      'cart.item.totalPrice': 'ಒಟ್ಟು ಬೆಲೆ:',
      'cart.item.negotiatePrice': 'ಬೆಲೆ ಸಂಧಾನ ಮಾಡಿ',
      'cart.item.removeItem': 'ಐಟಂ ತೆಗೆದುಹಾಕಿ',
      'cart.error.stockLimit': 'ಕೇವಲ {stock} ಕೆಜಿ ಮಾತ್ರ ಲಭ್ಯವಿದೆ',
      'cart.error.updateQuantity': 'ಪ್ರಮಾಣವನ್ನು ನವೀಕರಿಸಲು ವಿಫಲವಾಗಿದೆ: {error}',
      'cart.error.removeItem': 'ಐಟಂ ತೆಗೆದುಹಾಕಲು ವಿಫಲವಾಗಿದೆ: {error}',
      'cart.error.emptyCart': 'ನಿಮ್ಮ ಕಾರ್ಟ್ ಖಾಲಿ ಇದೆ',
      'cart.error.negotiation': 'ಸಂಧಾನವನ್ನು ತೆರೆಯಲು ವಿಫಲವಾಗಿದೆ: {error}',
    },
    'hi': {
      'cart.title': 'आपकी कार्ट 🛒',
      'cart.empty': 'आपकी कार्ट खाली है 🛒',
      'cart.total': 'कुल:',
      'cart.proceedToPayment': 'भुगतान के लिए आगे बढ़ें',
      'cart.item.unknownCrop': 'अज्ञात फसल',
      'cart.item.pricePerKg': '/ किलो',
      'cart.item.stockAvailable': 'उपलब्ध स्टॉक:',
      'cart.item.itemTotal': 'आइटम कुल:',
      'cart.item.negotiate': 'बातचीत करें',
      'cart.item.productDetails': 'उत्पाद विवरण',
      'cart.item.description': 'विवरण',
      'cart.item.pricePerKgLabel': 'प्रति किलो कीमत',
      'cart.item.availableStock': 'उपलब्ध स्टॉक',
      'cart.item.quantityInCart': 'कार्ट में मात्रा:',
      'cart.item.totalPrice': 'कुल कीमत:',
      'cart.item.negotiatePrice': 'कीमत पर बातचीत करें',
      'cart.item.removeItem': 'आइटम हटाएं',
      'cart.error.stockLimit': 'केवल {stock} किलो उपलब्ध है',
      'cart.error.updateQuantity': 'मात्रा अपडेट करने में विफल: {error}',
      'cart.error.removeItem': 'आइटम हटाने में विफल: {error}',
      'cart.error.emptyCart': 'आपकी कार्ट खाली है',
      'cart.error.negotiation': 'बातचीत खोलने में विफल: {error}',
    },
    'te': {
      'cart.title': 'మీ కార్ట్ 🛒',
      'cart.empty': 'మీ కార్ట్ ఖాళీగా ఉంది 🛒',
      'cart.total': 'మొత్తం:',
      'cart.proceedToPayment': 'చెల్లింపుకు వెళ్ళండి',
      'cart.item.unknownCrop': 'తెలియని పంట',
      'cart.item.pricePerKg': '/ కిలో',
      'cart.item.stockAvailable': 'అందుబాటులో ఉన్న స్టాక్:',
      'cart.item.itemTotal': 'అంశం మొత్తం:',
      'cart.item.negotiate': 'చర్చ చేయండి',
      'cart.item.productDetails': 'ఉత్పత్తి వివరాలు',
      'cart.item.description': 'వివరణ',
      'cart.item.pricePerKgLabel': 'కిలోకు ధర',
      'cart.item.availableStock': 'అందుబాటులో ఉన్న స్టాక్',
      'cart.item.quantityInCart': 'కార్ట్‌లో పరిమాణం:',
      'cart.item.totalPrice': 'మొత్తం ధర:',
      'cart.item.negotiatePrice': 'ధరపై చర్చ చేయండి',
      'cart.item.removeItem': 'అంశాన్ని తీసివేయండి',
      'cart.error.stockLimit': 'కేవలం {stock} కిలోలు మాత్రమే అందుబాటులో ఉన్నాయి',
      'cart.error.updateQuantity': 'పరిమాణాన్ని నవీకరించడంలో విఫలమైంది: {error}',
      'cart.error.removeItem': 'అంశాన్ని తీసివేయడంలో విఫలమైంది: {error}',
      'cart.error.emptyCart': 'మీ కార్ట్ ఖాళీగా ఉంది',
      'cart.error.negotiation': 'చర్చను తెరవడంలో విఫలమైంది: {error}',
    },
    'ta': {
      'cart.title': 'உங்கள் கார்ட் 🛒',
      'cart.empty': 'உங்கள் கார்ட் காலியாக உள்ளது 🛒',
      'cart.total': 'மொத்தம்:',
      'cart.proceedToPayment': 'கட்டணத்திற்கு செல்லுங்கள்',
      'cart.item.unknownCrop': 'தெரியாத பயிர்',
      'cart.item.pricePerKg': '/ கிலோ',
      'cart.item.stockAvailable': 'கிடைக்கும் பங்கு:',
      'cart.item.itemTotal': 'பொருள் மொத்தம்:',
      'cart.item.negotiate': 'பேச்சுவார்த்தை நடத்துங்கள்',
      'cart.item.productDetails': 'தயாரிப்பு விவரங்கள்',
      'cart.item.description': 'விளக்கம்',
      'cart.item.pricePerKgLabel': 'கிலோவுக்கு விலை',
      'cart.item.availableStock': 'கிடைக்கும் பங்கு',
      'cart.item.quantityInCart': 'கார்ட்டில் உள்ள அளவு:',
      'cart.item.totalPrice': 'மொத்த விலை:',
      'cart.item.negotiatePrice': 'விலையில் பேச்சுவார்த்தை நடத்துங்கள்',
      'cart.item.removeItem': 'பொருளை அகற்றுங்கள்',
      'cart.error.stockLimit': 'வெறும் {stock} கிலோ மட்டுமே கிடைக்கும்',
      'cart.error.updateQuantity': 'அளவை புதுப்பிப்பதில் தோல்வி: {error}',
      'cart.error.removeItem': 'பொருளை அகற்றுவதில் தோல்வி: {error}',
      'cart.error.emptyCart': 'உங்கள் கார்ட் காலியாக உள்ளது',
      'cart.error.negotiation': 'பேச்சுவார்த்தைத் திறப்பதில் தோல்வி: {error}',
    },
  };

  static String getTranslation(String key, String language) {
    return translations[language]?[key] ?? translations['en']?[key] ?? key;
  }
}

/// --------------------
/// CART ITEM WIDGET
/// --------------------
class CartItemWidget extends StatefulWidget {
  final CartItem item;
  final Function(String, String, double, int, int, int) updateQuantity;
  final Function(String, String, int) removeItem;
  final Function(String, String, String) navigateToNegotiation;
  final String language;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.updateQuantity,
    required this.removeItem,
    required this.navigateToNegotiation,
    required this.language,
  });

  @override
  _CartItemWidgetState createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late TextEditingController _quantityController;
  bool _showDetails = false;

  String t(String key) {
    return AppTranslations.getTranslation(key, widget.language);
  }

  @override
  void initState() {
    super.initState();
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _handleBlur() {
    final newQty = int.tryParse(_quantityController.text) ?? 0;
    if (newQty != widget.item.quantity) {
      widget.updateQuantity(
        widget.item.id,
        widget.item.cropId,
        widget.item.pricePerKg,
        widget.item.quantity,
        newQty,
        widget.item.produce?.quantity ?? 0,
      );
    }
  }

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleDetails,
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14)),
                      child: Image.network(
                        widget.item.produce?.imageUrl ??
                            "https://via.placeholder.com/150",
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.produce?.cropName ?? t('cart.item.unknownCrop'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${widget.item.pricePerKg.toStringAsFixed(2)}${t('cart.item.pricePerKg')}',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _qtyButton(Icons.remove, () {
                                  final newQty = widget.item.quantity - 1;
                                  _quantityController.text = newQty.toString();
                                  widget.updateQuantity(
                                    widget.item.id,
                                    widget.item.cropId,
                                    widget.item.pricePerKg,
                                    widget.item.quantity,
                                    newQty,
                                    widget.item.produce?.quantity ?? 0,
                                  );
                                }),
                                Expanded(
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    height: 34,
                                    child: TextField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                        filled: true,
                                        fillColor: const Color(0xFFF3F4F6),
                                      ),
                                      onEditingComplete: _handleBlur,
                                    ),
                                  ),
                                ),
                                _qtyButton(Icons.add, () {
                                  final newQty = widget.item.quantity + 1;
                                  _quantityController.text = newQty.toString();
                                  widget.updateQuantity(
                                    widget.item.id,
                                    widget.item.cropId,
                                    widget.item.pricePerKg,
                                    widget.item.quantity,
                                    newQty,
                                    widget.item.produce?.quantity ?? 0,
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${t('cart.item.stockAvailable')} ${widget.item.produce?.quantity ?? 0}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.redAccent),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${t('cart.item.itemTotal')} ₹${widget.item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                widget.navigateToNegotiation(
                                  widget.item.cropId,
                                  widget.item.produce?.farmerId ?? '',
                                  widget.item.produce?.cropName ?? '',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: Text(t('cart.item.negotiate')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () => widget.removeItem(
                    widget.item.id,
                    widget.item.cropId,
                    widget.item.quantity,
                  ),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Detailed view section
        if (_showDetails) _buildDetailedView(),
      ],
    );
  }

  Widget _buildDetailedView() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 8,
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
                t('cart.item.productDetails'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              IconButton(
                onPressed: _toggleDetails,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bigger image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.item.produce?.imageUrl ?? "https://via.placeholder.com/300",
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Product name
          Text(
            widget.item.produce?.cropName ?? t('cart.item.unknownCrop'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Description
          if (widget.item.produce?.description != null && 
              widget.item.produce!.description!.isNotEmpty) ...[
            Text(
              t('cart.item.description'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.produce!.description!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Price and stock info
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  t('cart.item.pricePerKgLabel'),
                  '₹${widget.item.pricePerKg.toStringAsFixed(2)}',
                  Icons.money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  t('cart.item.availableStock'),
                  '${widget.item.produce?.quantity ?? 0} kg',
                  Icons.inventory_2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quantity controls
          Row(
            children: [
              Text(
                t('cart.item.quantityInCart'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              _qtyButton(Icons.remove, () {
                final newQty = widget.item.quantity - 1;
                _quantityController.text = newQty.toString();
                widget.updateQuantity(
                  widget.item.id,
                  widget.item.cropId,
                  widget.item.pricePerKg,
                  widget.item.quantity,
                  newQty,
                  widget.item.produce?.quantity ?? 0,
                );
              }),
              Container(
                width: 60,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                  ),
                  onEditingComplete: _handleBlur,
                ),
              ),
              _qtyButton(Icons.add, () {
                final newQty = widget.item.quantity + 1;
                _quantityController.text = newQty.toString();
                widget.updateQuantity(
                  widget.item.id,
                  widget.item.cropId,
                  widget.item.pricePerKg,
                  widget.item.quantity,
                  newQty,
                  widget.item.produce?.quantity ?? 0,
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
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
                  t('cart.item.totalPrice'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${widget.item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.navigateToNegotiation(
                      widget.item.cropId,
                      widget.item.produce?.farmerId ?? '',
                      widget.item.produce?.cropName ?? '',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(t('cart.item.negotiatePrice')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.removeItem(
                    widget.item.id,
                    widget.item.cropId,
                    widget.item.quantity,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(t('cart.item.removeItem')),
                ),
              ),
            ],
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

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.lightBlue[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue[900]),
      ),
    );
  }
}

/// --------------------
/// ADD TO CART SCREEN
/// --------------------
class AddToCartScreen extends StatefulWidget {
  const AddToCartScreen({super.key});

  @override
  _AddToCartScreenState createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<CartItem> _cartItems = [];
  double _totalPrice = 0.0;
  bool _loading = true;
  RealtimeChannel? _subscription;
  String _currentLanguage = 'en'; // Default language

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _fetchCartItems();
    _setupRealtimeSubscription();
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

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _subscription = supabase
        .channel('cart_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'cart',
          callback: (_) => _fetchCartItems(),
        )
        .subscribe();
  }

  String t(String key) {
    return AppTranslations.getTranslation(key, _currentLanguage);
  }

  Future<void> _fetchCartItems() async {
    try {
      setState(() => _loading = true);
      final prefs = await SharedPreferences.getInstance();
      final retailerId = prefs.getString("userId");
      if (retailerId == null) {
        _resetCart();
        return;
      }

      final data = await supabase
          .from('cart')
          .select('''
            id, crop_id, quantity, price_per_kg, total_price,
            produce:crop_id (id, crop_name, image_url, farmer_id, quantity, description)
          ''')
          .eq('retailer_id', retailerId);

      final items = (data as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _cartItems = items;
        _totalPrice =
            _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
        _loading = false;
      });
    } catch (err) {
      print('❌ Fetch cart error: $err');
      _resetCart();
    }
  }

  void _resetCart() {
    setState(() {
      _cartItems = [];
      _totalPrice = 0.0;
      _loading = false;
    });
  }

  Future<void> _updateQuantity(String cartId, String cropId, double pricePerKg,
      int oldQty, int newQty, int stockQty) async {
    try {
      if (newQty < 1) return _removeItem(cartId, cropId, oldQty);
      if (newQty > stockQty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t('cart.error.stockLimit').replaceAll('{stock}', stockQty.toString())),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      await supabase.rpc('update_cart_quantity', params: {
        'p_cart_id': cartId,
        'p_crop_id': cropId,
        'p_price_per_kg': pricePerKg,
        'p_old_qty': oldQty,
        'p_new_qty': newQty,
      });

      _fetchCartItems();
    } catch (err) {
      print('❌ Update qty error: $err');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('cart.error.updateQuantity').replaceAll('{error}', err.toString())),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _removeItem(String cartId, String cropId, int qty) async {
    try {
      final produce = await supabase
          .from('produce')
          .select('quantity')
          .eq('id', cropId)
          .single();
      final updatedQty = (produce['quantity'] as int) + qty;

      await Future.wait([
        supabase.from('produce').update({'quantity': updatedQty}).eq('id', cropId),
        supabase.from('cart').delete().eq('id', cartId),
      ]);

      _fetchCartItems();
    } catch (err) {
      print('❌ Remove error: $err');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('cart.error.removeItem').replaceAll('{error}', err.toString())),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _proceedToPayment() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('cart.error.emptyCart')),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'cartItems': _cartItems.map((e) => e.toJson()).toList(),
        'totalAmount': _totalPrice,
      },
    );
  }

  void _navigateToNegotiation(
      String cropId, String farmerId, String cropName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final retailerId = prefs.getString("userId") ?? '';
      final retailerName = prefs.getString("userName") ?? '';

      // Fetch farmer name
      String farmerName = '';
      try {
        final farmerData = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', farmerId)
            .single();
        farmerName = farmerData['full_name'] ?? '';
      } catch (e) {
        print('Error fetching farmer name: $e');
      }

      Navigator.pushNamed(
        context,
        '/negotiateR',
        arguments: {
          'cropId': cropId,
          'farmerId': farmerId,
          'retailerId': retailerId,
          'currentUserId': retailerId,
          'cropName': cropName,
          'farmerName': farmerName,
          'retailerName': retailerName,
        },
      );
    } catch (e) {
      print('Error navigating to negotiation: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('cart.error.negotiation').replaceAll('{error}', e.toString())),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🚫 No back button
        title: Text(
          t('cart.title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _cartItems.isEmpty
                    ? Center(child: Text(t('cart.empty')))
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: _cartItems.length,
                              itemBuilder: (context, index) => CartItemWidget(
                                item: _cartItems[index],
                                updateQuantity: _updateQuantity,
                                removeItem: _removeItem,
                                navigateToNegotiation: _navigateToNegotiation,
                                language: _currentLanguage,
                              ),
                            ),
                          ),
                          _buildTotalSection(),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('cart.total'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                t('cart.proceedToPayment'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}