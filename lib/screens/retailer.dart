import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class RetailerDashboard extends StatefulWidget {
  const RetailerDashboard({super.key});

  @override
  State<RetailerDashboard> createState() => _RetailerDashboardState();
}

class _RetailerDashboardState extends State<RetailerDashboard> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  List<Map<String, dynamic>> produceList = [];
  List<Map<String, dynamic>> filteredProduce = [];
  String retailerName = '';
  bool loading = true;
  bool refreshing = false;
  Map<String, dynamic>? selectedProduce;
  String searchQuery = '';
  String sortOption = 'none';
  bool sortModalVisible = false;
  bool alertVisible = false;
  Map<String, dynamic> alertConfig = {};
  Timer? _debounce;
  
  // Notification-related variables
  int unreadNotificationsCount = 0;
  String? userId;
  String _currentLanguage = 'en'; // Default language

  // Translation map with multiple languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'welcome': 'Welcome',
      'retailer': 'Retailer',
      'error': 'Error',
      'failedToLoadProduce': 'Failed to load produce',
      'loadingProduce': 'Loading produce...',
      'noProduceAvailable': 'No produce available',
      'searchCrops': 'Search crops...',
      'none': 'None',
      'lowToHigh': 'Price: Low to High',
      'highToLow': 'Price: High to Low',
      'close': 'Close',
      'quantity': 'Quantity: {qty} kg',
      'price': 'Price: ₹{price}/kg',
      'farmer': 'Farmer: {name}',
      'addToCart': 'Add to Cart',
      'home': 'Home',
      'cart': 'Cart',
      'orders': 'Orders',
      'profile_retailer': 'Profile',
      'logout': 'Logout',
      'areYouSureLogout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'ok': 'OK',
      'success': 'Success',
      'itemAddedToCart': 'Item added to cart',
      'somethingWentWrong': 'Something went wrong',
      'pleaseLoginToAddToCart': 'Please login to add items to cart',
      'logoutFailed': 'Logout failed',
      'sortByPrice': 'Sort by Price',
      'unknown': 'Unknown',
      'retry': 'Retry',
      'refresh': 'Pull to refresh',
      'accessNotificationsError': 'Error accessing notifications',
    },
    'kn': {
      'welcome': 'ಸ್ವಾಗತ',
      'retailer': 'ಚಿಲ್ಲರೆ ವ್ಯಾಪಾರಿ',
      'error': 'ದೋಷ',
      'failedToLoadProduce': 'ಉತ್ಪನ್ನಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ',
      'loadingProduce': 'ಉತ್ಪನ್ನಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'noProduceAvailable': 'ಯಾವುದೇ ಉತ್ಪನ್ನಗಳು ಲಭ್ಯವಿಲ್ಲ',
      'searchCrops': 'ಬೆಳೆಗಳನ್ನು ಹುಡುಕಿ...',
      'none': 'ಯಾವುದೂ ಅಲ್ಲ',
      'lowToHigh': 'ಬೆಲೆ: ಕಡಿಮೆಯಿಂದ ಹೆಚ್ಚಿಗೆ',
      'highToLow': 'ಬೆಲೆ: ಹೆಚ್ಚಿನಿಂದ ಕಡಿಮೆಗೆ',
      'close': 'ಮುಚ್ಚಿ',
      'quantity': 'ಪ್ರಮಾಣ: {qty} ಕೆಜಿ',
      'price': 'ಬೆಲೆ: ₹{price}/ಕೆಜಿ',
      'farmer': 'ರೈತ: {name}',
      'addToCart': 'ಕಾರ್ಟ್‌ಗೆ ಸೇರಿಸಿ',
      'home': 'ಮುಖಪುಟ',
      'cart': 'ಕಾರ್ಟ್',
      'orders': 'ಆದೇಶಗಳು',
      'profile_retailer': 'ಪ್ರೊಫೈಲ್',
      'logout': 'ಲಾಗ್ ಔಟ್',
      'areYouSureLogout': 'ನೀವು ಖಂಡಿತವಾಗಿ ಲಾಗ್ ಔಟ್ ಮಾಡಲು ಬಯಸುವಿರಾ?',
      'cancel': 'ರದ್ದುಮಾಡಿ',
      'ok': 'ಸರಿ',
      'success': 'ಯಶಸ್ಸು',
      'itemAddedToCart': 'ಐಟಂ ಕಾರ್ಟ್‌ಗೆ ಸೇರಿಸಲಾಗಿದೆ',
      'somethingWentWrong': 'ಏನೋ ತಪ್ಪಾಗಿದೆ',
      'pleaseLoginToAddToCart': 'ಐಟಂಗಳನ್ನು ಕಾರ್ಟ್‌ಗೆ ಸೇರಿಸಲು ದಯವಿಟ್ಟು ಲಾಗಿನ್ ಆಗಿ',
      'logoutFailed': 'ಲಾಗ್ ಔಟ್ ವಿಫಲವಾಗಿದೆ',
      'sortByPrice': 'ಬೆಲೆಯ ಪ್ರಕಾರ ವಿಂಗಡಿಸಿ',
      'unknown': 'ತಿಳಿಯದ',
      'retry': 'ಮರುಪ್ರಯತ್ನಿಸಿ',
      'refresh': 'ರಿಫ್ರೆಶ್ ಮಾಡಲು ಎಳೆಯಿರಿ',
      'accessNotificationsError': 'ಅಧಿಸೂಚನೆಗಳನ್ನು ಪ್ರವೇಶಿಸುವಲ್ಲಿ ದೋಷ',
    },
    'hi': {
      'welcome': 'स्वागत है',
      'retailer': 'खुदरा विक्रेता',
      'error': 'त्रुटि',
      'failedToLoadProduce': 'उत्पाद लोड करने में विफल',
      'loadingProduce': 'उत्पाद लोड हो रहे हैं...',
      'noProduceAvailable': 'कोई उत्पाद उपलब्ध नहीं',
      'searchCrops': 'फसलें खोजें...',
      'none': 'कोई नहीं',
      'lowToHigh': 'कीमत: कम से ज्यादा',
      'highToLow': 'कीमत: ज्यादा से कम',
      'close': 'बंद करें',
      'quantity': 'मात्रा: {qty} किग्रा',
      'price': 'कीमत: ₹{price}/किग्रा',
      'farmer': 'किसान: {name}',
      'addToCart': 'कार्ट में जोड़ें',
      'home': 'होम',
      'cart': 'कार्ट',
      'orders': 'ऑर्डर',
      'profile_retailer': 'प्रोफाइल',
      'logout': 'लॉग आउट',
      'areYouSureLogout': 'क्या आप वाकई लॉग आउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
      'ok': 'ठीक है',
      'success': 'सफलता',
      'itemAddedToCart': 'आइटम कार्ट में जोड़ा गया',
      'somethingWentWrong': 'कुछ गलत हो गया',
      'pleaseLoginToAddToCart': 'कार्ट में आइटम जोड़ने के लिए कृपया लॉगिन करें',
      'logoutFailed': 'लॉग आउट विफल',
      'sortByPrice': 'कीमत के अनुसार क्रमबद्ध करें',
      'unknown': 'अज्ञात',
      'retry': 'पुन: प्रयास करें',
      'refresh': 'ताज़ा करने के लिए खींचें',
      'accessNotificationsError': 'सूचनाओं तक पहुंचने में त्रुटि',
    },
    'te': {
      'welcome': 'స్వాగతం',
      'retailer': 'చిల్లర వ్యాపారి',
      'error': 'లోపం',
      'failedToLoadProduce': 'ఉత్పత్తులను లోడ్ చేయడంలో విఫలమైంది',
      'loadingProduce': 'ఉత్పత్తులు లోడ్ అవుతున్నాయి...',
      'noProduceAvailable': 'ఏ ఉత్పత్తులు అందుబాటులో లేవు',
      'searchCrops': 'పంటలను శోధించండి...',
      'none': 'ఏమీ లేదు',
      'lowToHigh': 'ధర: తక్కువ నుండి ఎక్కువ',
      'highToLow': 'ధర: ఎక్కువ నుండి తక్కువ',
      'close': 'మూసివేయి',
      'quantity': 'పరిమాణం: {qty} కిలోలు',
      'price': 'ధర: ₹{price}/కిలో',
      'farmer': 'రైతు: {name}',
      'addToCart': 'కార్ట్‌కి జోడించండి',
      'home': 'హోమ్',
      'cart': 'కార్ట్',
      'orders': 'ఆర్డర్లు',
      'profile_retailer': 'ప్రొఫైల్',
      'logout': 'లాగ్ అవుట్',
      'areYouSureLogout': 'మీరు ఖచ్చితంగా లాగ్ అవుట్ చేయాలనుకుంటున్నారా?',
      'cancel': 'రద్దు చేయండి',
      'ok': 'సరే',
      'success': 'విజయం',
      'itemAddedToCart': 'అంశం కార్ట్‌కి జోడించబడింది',
      'somethingWentWrong': 'ఏదో తప్పు జరిగింది',
      'pleaseLoginToAddToCart': 'అంశాలను కార్ట్‌కి జోడించడానికి దయచేసి లాగిన్ అవ్వండి',
      'logoutFailed': 'లాగ్ అవుట్ విఫలమైంది',
      'sortByPrice': 'ధర ప్రకారం క్రమబద్ధీకరించండి',
      'unknown': 'తెలియదు',
      'retry': 'మళ్ళీ ప్రయత్నించండి',
      'refresh': 'రిఫ్రెష్ చేయడానికి లాగండి',
      'accessNotificationsError': 'నోటిఫికేషన్లను యాక్సెస్ చేయడంలో లోపం',
    },
    'ta': {
      'welcome': 'வரவேற்கிறோம்',
      'retailer': 'சில்லறை விற்பனையாளர்',
      'error': 'பிழை',
      'failedToLoadProduce': 'தயாரிப்புகளை ஏற்றுவதில் தோல்வி',
      'loadingProduce': 'தயாரிப்புகள் ஏற்றப்படுகின்றன...',
      'noProduceAvailable': 'எந்த தயாரிப்பும் கிடைக்கவில்லை',
      'searchCrops': 'பயிர்களைத் தேடுங்கள்...',
      'none': 'ஒன்றுமில்லை',
      'lowToHigh': 'விலை: குறைந்ததிலிருந்து அதிகம்',
      'highToLow': 'விலை: அதிகத்திலிருந்து குறைவு',
      'close': 'மூடு',
      'quantity': 'அளவு: {qty} கிலோ',
      'price': 'விலை: ₹{price}/கிலோ',
      'farmer': 'விவசாயி: {name}',
      'addToCart': 'கார்ட்டில் சேர்',
      'home': 'முகப்பு',
      'cart': 'கார்ட்',
      'orders': 'ஆர்டர்கள்',
      'profile_retailer': 'சுயவிவரம்',
      'logout': 'வெளியேறு',
      'areYouSureLogout': 'நீங்கள் நிச்சயமாக வெளியேற விரும்புகிறீர்களா?',
      'cancel': 'ரத்து செய்',
      'ok': 'சரி',
      'success': 'வெற்றி',
      'itemAddedToCart': 'பொருள் கார்ட்டில் சேர்க்கப்பட்டது',
      'somethingWentWrong': 'ஏதோ தவறு நடந்தது',
      'pleaseLoginToAddToCart': 'பொருட்களை கார்ட்டில் சேர்க்க தயவுசெய்து உள்நுழைக',
      'logoutFailed': 'வெளியேற்றம் தோல்வியடைந்தது',
      'sortByPrice': 'விலை அடிப்படையில் வரிசைப்படுத்து',
      'unknown': 'தெரியாத',
      'retry': 'மீண்டும் முயற்சி செய்',
      'refresh': 'புதுப்பிக்க இழுக்கவும்',
      'accessNotificationsError': 'அறிவிப்புகளை அணுகுவதில் பிழை',
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
    fetchRetailerInfo();
    fetchInStockProduce();
    fetchUnreadNotificationsCount();
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
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchRetailerInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await supabase
          .from('profiles')
          .select('name')
          .eq('id', userId!)
          .single();

      if (mounted) {
        setState(() {
          retailerName = response['name'] ?? t('retailer');
        });
      }
    } catch (err) {
      debugPrint('Error retrieving retailer info: $err');
    }
  }

  Future<void> fetchUnreadNotificationsCount() async {
    if (userId == null) return;

    try {
      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId!)
          .eq('read', false);

      if (mounted) {
        setState(() {
          unreadNotificationsCount = (response as List).length;
        });
      }
    } catch (err) {
      debugPrint('Error fetching unread notifications count: $err');
    }
  }

  void handleNotificationsPress() async {
    try {
      // Mark notifications as read when navigating to notifications page
      if (unreadNotificationsCount > 0) {
        await supabase
            .from('notifications')
            .update({'read': true})
            .eq('user_id', userId!)
            .eq('read', false);
        
        if (mounted) {
          setState(() {
            unreadNotificationsCount = 0;
          });
        }
      }
      
      Navigator.pushNamed(context, '/notifications').then((_) {
        fetchUnreadNotificationsCount();
      });
    } catch (err) {
      print('Error handling notifications: $err');
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(t('accessNotificationsError'))),
        );
      }
    }
  }

  Future<void> fetchInStockProduce() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final produceResponse = await supabase
          .from('produce')
          .select('id, crop_name, quantity, price_per_kg, status, image_url, farmer_id')
          .eq('status', 'in_stock');

      final farmerIds = produceResponse.map<String>((p) => p['farmer_id'].toString()).toSet().toList();
      final farmerResponse = await supabase
          .from('profiles')
          .select('id, name')
          .inFilter('id', farmerIds);

      final farmerDict = <String, String>{};
      for (final farmer in farmerResponse) {
        farmerDict[farmer['id']] = farmer['name'] ?? t('unknown');
      }
    
      final mergedList = produceResponse.map<Map<String, dynamic>>((produce) {
        return {
          ...produce,
          'farmer_name': farmerDict[produce['farmer_id']] ?? t('unknown'),
        };
      }).toList();

      setState(() {
        produceList = mergedList;
        applyFilters();
        loading = false;
        refreshing = false;
      });
    } catch (err) {
      debugPrint('Error fetching produce: $err');
      showCustomAlert(t('error'), t('failedToLoadProduce'));
      setState(() {
        loading = false;
        refreshing = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => refreshing = true);
    await fetchInStockProduce();
    await fetchUnreadNotificationsCount();
  }

  void applyFilters() {
    var updatedList = List<Map<String, dynamic>>.from(produceList);

    if (searchQuery.isNotEmpty) {
      updatedList = updatedList.where((item) =>
          item['crop_name'].toString().toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    if (sortOption == 'asc') {
      updatedList.sort((a, b) => (a['price_per_kg'] as num).compareTo(b['price_per_kg'] as num));
    } else if (sortOption == 'desc') {
      updatedList.sort((a, b) => (b['price_per_kg'] as num).compareTo(a['price_per_kg'] as num));
    }

    setState(() => filteredProduce = updatedList);
  }

  Future<void> addToCart(String cropId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        showCustomAlert(t('error'), t('pleaseLoginToAddToCart'));
        return;
      }

      final cropResponse = await supabase
          .from('produce')
          .select('price_per_kg')
          .eq('id', cropId)
          .single();

      await supabase.from('cart').insert([{
        'retailer_id': user.id,
        'crop_id': cropId,
        'quantity': 1,
        'price_per_kg': cropResponse['price_per_kg'],
      }]);

      showCustomAlert(t('success'), t('itemAddedToCart'));
    } catch (err) {
      debugPrint('Error adding to cart: $err');
      showCustomAlert(t('error'), t('somethingWentWrong'));
    }
  }

  void handleLogout() {
    showCustomAlert(
      t('logout'),
      t('areYouSureLogout'),
      [
        {'text': t('cancel'), 'onPress': () {}},
        {'text': t('logout'), 'style': 'destructive', 'onPress': _performLogout},
      ],
    );
  }

  Future<void> _performLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await supabase.auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (err) {
      debugPrint('Logout error: $err');
      showCustomAlert(t('error'), t('logoutFailed'));
    }
  }

  void openDetails(Map<String, dynamic> produce) => setState(() => selectedProduce = produce);
  void closeDetails() => setState(() => selectedProduce = null);

  void showCustomAlert(String title, String message, [List<Map<String, dynamic>>? buttons]) {
    setState(() {
      alertConfig = {
        'title': title,
        'message': message,
        'buttons': buttons ?? [{'text': t('ok'), 'onPress': () {}}],
      };
      alertVisible = true;
    });
  }

  void hideCustomAlert() => setState(() => alertVisible = false);

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => searchQuery = query);
      applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get system padding for navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 40.0; // Further reduced height of bottom navigation bar
    
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  _buildSearchAndFilter(),
                  // Adjust expanded area to account for bottom navigation
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: navBarHeight + bottomPadding),
                      child: _buildProduceList(),
                    ),
                  ),
                ],
              ),
              // Position bottom navigation with proper padding
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomPadding,
                child: _buildBottomNavigation(),
              ),
              if (sortModalVisible) _buildSortModal(),
              if (selectedProduce != null) _buildDetailsModal(),
              if (alertVisible) _buildCustomAlert(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A6FA5), Color(0xFF2C4C7C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    '🧑',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('welcome'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    retailerName.isNotEmpty ? retailerName : t('retailer'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Notification button with badge
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        FeatherIcons.bell,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: handleNotificationsPress,
                    ),
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadNotificationsCount > 9 ? '9+' : unreadNotificationsCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              // Logout button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    FeatherIcons.logOut,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: handleLogout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDE4ED)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      FeatherIcons.search,
                      color: Color(0xFF4A6FA5),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: t('searchCrops'),
                        hintStyle: const TextStyle(color: Color(0xFF757575)),
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filter button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFb0c4c7),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                FeatherIcons.filter,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  sortModalVisible = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProduceList() {
    // Determine if we're on web
    final isWeb = Theme.of(context).platform == TargetPlatform.windows || 
                 Theme.of(context).platform == TargetPlatform.linux || 
                 Theme.of(context).platform == TargetPlatform.macOS;
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF4A6FA5),
      child: loading
          ? _buildShimmerLoading(isWeb)
          : filteredProduce.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        FeatherIcons.inbox,
                        size: 40,
                        color: Color(0xFF4A6FA5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t('noProduceAvailable'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A6FA5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6FA5),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(t('retry')),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWeb ? 4 : 2, // More columns on web
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isWeb ? 0.65 : 0.75, // More compact on web
                  ),
                  itemCount: filteredProduce.length,
                  itemBuilder: (context, index) {
                    final item = filteredProduce[index];
                    return _buildProduceItem(item, isWeb);
                  },
                ),
    );
  }

  Widget _buildShimmerLoading(bool isWeb) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWeb ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWeb ? 0.65 : 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          height: isWeb ? 180.0 : 220.0, // Match card height
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProduceItem(Map<String, dynamic> item, [bool isWeb = false]) {
    // Adjust sizes based on platform
    final cardHeight = isWeb ? 180.0 : 220.0;
    final imageHeight = isWeb ? 100.0 : 140.0;
    final priceFontSize = isWeb ? 10.0 : 12.0;
    final cropFontSize = isWeb ? 12.0 : 14.0;
    final detailFontSize = isWeb ? 9.0 : 11.0;
    
    return GestureDetector(
      onTap: () => openDetails(item),
      child: Container(
        height: cardHeight, // Reduced height for web
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed size image container
            SizedBox(
              height: imageHeight, // Reduced height for web
              width: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      item['image_url'] ?? 'https://via.placeholder.com/150',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A6FA5).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₹${item['price_per_kg']}/kg',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: priceFontSize, // Reduced font size for web
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Fixed size product info area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['crop_name'] ?? '',
                      style: TextStyle(
                        fontSize: cropFontSize, // Reduced font size for web
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C4C7C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Row(
                      children: [
                        Icon(
                          FeatherIcons.package,
                          size: isWeb ? 10 : 12, // Reduced icon size for web
                          color: const Color(0xFF4A6FA5),
                        ),
                        const SizedBox(width: 2), // Reduced spacing
                        Expanded(
                          child: Text(
                            '${item['quantity']} kg',
                            style: TextStyle(
                              fontSize: detailFontSize, // Reduced font size for web
                              color: const Color(0xFF555555),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 40.0, // Further reduced from 50.0
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF5F7FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -3),
          ),
        ],
        border: Border(
          top: BorderSide(color: Color(0xFFDDE4ED)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4), // Further reduced padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(FeatherIcons.home, t('home')),
              _buildNavItem(FeatherIcons.shoppingCart, t('cart'), '/cart'),
              _buildNavItem(FeatherIcons.package, t('orders'), '/orders'),
              _buildNavItem(FeatherIcons.user, t('profile_retailer'), '/profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, [String? route]) {
    return GestureDetector(
      onTap: () {
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Container(
        padding: EdgeInsets.zero, // Removed all padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFF4A6FA5),
              size: 18, // Further reduced icon size
            ),
            const SizedBox(height: 1), // Minimal spacing
            FittedBox( // Added FittedBox to ensure text fits
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 8, // Further reduced text size
                  color: Color(0xFF4A6FA5),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sort Modal
  Widget _buildSortModal() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            sortModalVisible = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF5F7FA)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('sortByPrice'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C4C7C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDE4ED)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSortOption(t('none'), 'none'),
                          const Divider(height: 1),
                          _buildSortOption(t('lowToHigh'), 'asc'),
                          const Divider(height: 1),
                          _buildSortOption(t('highToLow'), 'desc'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              sortModalVisible = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                            child: Text(
                              t('close'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          sortOption = value;
          sortModalVisible = false;
        });
        applyFilters();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: sortOption == value ? const Color(0xFF4A6FA5) : Colors.black54,
                ),
              ),
            ),
            if (sortOption == value)
              const Icon(
                Icons.check,
                color: Color(0xFF4A6FA5),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // Details Modal
  Widget _buildDetailsModal() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: closeDetails,
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 600),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF5F7FA)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fixed size image container
                    SizedBox(
                      height: 220, // Fixed height for image
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Image.network(
                          selectedProduce?['image_url'] ?? 'https://via.placeholder.com/300',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedProduce?['crop_name'] ?? '',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C4C7C),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            _buildDetailRow(
                              FeatherIcons.package,
                              t('quantity').replaceAll('{qty}', selectedProduce?['quantity']?.toString() ?? ''),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              FeatherIcons.dollarSign,
                              t('price').replaceAll('{price}', selectedProduce?['price_per_kg']?.toString() ?? ''),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              FeatherIcons.user,
                              t('farmer').replaceAll('{name}', selectedProduce?['farmer_name'] ?? ''),
                            ),
                            const SizedBox(height: 24),
                            // Add to Cart Button
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A6FA5),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    addToCart(selectedProduce!['id']);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          FeatherIcons.shoppingCart,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          t('addToCart'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Close Button
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: closeDetails,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                                    alignment: Alignment.center,
                                    child: Text(
                                      t('close'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4A6FA5),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF444444),
            ),
          ),
        ),
      ],
    );
  }

  // Custom Alert
  Widget _buildCustomAlert() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: hideCustomAlert,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      alertConfig['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      alertConfig['message'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: (alertConfig['buttons'] as List).map((button) {
                        final isDestructive = button['style'] == 'destructive';
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: isDestructive ? const Color(0xFFE53935) : const Color(0xFF4A6FA5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  button['onPress']();
                                  hideCustomAlert();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                  child: Text(
                                    button['text'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}