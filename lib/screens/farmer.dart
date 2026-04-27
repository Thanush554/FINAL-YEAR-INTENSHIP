import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' as location_lib;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  // Translation map for multiple languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'dashboard.welcomeBack': 'Welcome back',
      'dashboard.farmer': 'Farmer',
      'dashboard.notifications': 'Notifications',
      'dashboard.logout': 'Logout',
      'dashboard.logoutConfirmation': 'Are you sure you want to logout?',
      'dashboard.logoutButton': 'Logout',
      'dashboard.logoutError': 'Error during logout',
      'dashboard.searchCrops': 'Search crops...',
      'dashboard.inStock': 'In Stock',
      'dashboard.outOfStock': 'Out of Stock',
      'dashboard.all': 'All',
      'dashboard.stock': 'Stock',
      'dashboard.sort': 'Sort',
      'dashboard.newest': 'Newest',
      'dashboard.priceAsc': 'Price: Low to High',
      'dashboard.priceDesc': 'Price: High to Low',
      'dashboard.quantityDesc': 'Quantity: High to Low',
      'dashboard.noCropsListed': 'No crops listed yet',
      'dashboard.addFirstCrop': 'Add your first crop',
      'dashboard.home': 'Home',
      'dashboard.add': 'Add',
      'dashboard.suggestions': 'Suggestions',
      'dashboard.disease': 'Disease',
      'dashboard.chat': 'Chat',
      'dashboard.profile': 'Profile',
      'dashboard.editCrop': 'Edit Crop',
      'dashboard.cropName': 'Crop Name',
      'dashboard.cropNamePlaceholder': 'Enter crop name',
      'dashboard.price': 'Price per kg',
      'dashboard.pricePlaceholder': 'Enter price per kg',
      'dashboard.quantity': 'Quantity (kg)',
      'dashboard.quantityPlaceholder': 'Enter quantity',
      'dashboard.description': 'Description',
      'dashboard.descriptionPlaceholder': 'Enter crop description (minimum 10 words)',
      'dashboard.descriptionMinWords': 'Description must have at least 10 words',
      'dashboard.statusAutoSetNote': 'Status will be automatically set based on quantity',
      'common.cancel': 'Cancel',
      'common.save': 'Save',
      'common.ok': 'OK',
      'common.error': 'Error',
      'common.success': 'Success',
      'common.retry': 'Retry',
      'common.delete': 'Delete',
      'common.invalid': 'Invalid',
      'common.edit': 'Edit',
      'dashboard.deleteCrop': 'Delete Crop',
      'dashboard.deleteCropConfirmation': 'Are you sure you want to delete this crop?',
      'dashboard.cropRemovedSuccess': 'Crop removed successfully',
      'dashboard.cropDeleteError': 'Error deleting crop',
      'dashboard.quantityPositiveError': 'Quantity must be a positive number',
      'dashboard.pricePositiveError': 'Price must be a positive number',
      'dashboard.cropUpdateSuccess': 'Crop updated successfully',
      'dashboard.saveUpdateError': 'Error saving update',
      'dashboard.permissionDenied': 'Permission Denied',
      'dashboard.imageAccessPermission': 'Please grant permission to access images',
      'dashboard.imagePickError': 'Error picking image',
      'dashboard.imageUploadFailed': 'Image upload failed, but crop was added',
      'dashboard.cropNameRequired': 'Crop name is required',
      'dashboard.produceAddedSuccess': 'Produce added successfully',
      'dashboard.addProduceError': 'Error adding produce',
      'dashboard.navigationError': 'Navigation Error',
      'dashboard.pageUnavailable': 'Page unavailable: {page}',
      'dashboard.messages': 'Messages',
      'dashboard.noNewMessages': 'No new messages',
      'dashboard.fetchMessagesError': 'Error fetching messages',
      'dashboard.accessNotificationsError': 'Error accessing notifications',
      'dashboard.weatherUnavailable': 'Weather data unavailable',
      'dashboard.locationPermissionDenied': 'Location permission denied',
      'dashboard.weatherLoadError': 'Error loading weather data',
      'dashboard.loadDataError': 'Error loading data',
      'dashboard.errorLoadUserData': 'Error loading user data',
      'dashboard.apiKeyMissing': 'Weather service unavailable: API key not configured',
      'dashboard.location': 'Location',
      'dashboard.locationPlaceholder': 'Fetching location...',
      'dashboard.locationError': 'Could not get location',
      'dashboard.enableLocation': 'Please enable location services',
      'dashboard.enableLocationButton': 'Enable Location',
      'dashboard.day': 'Day',
      'dashboard.night': 'Night',
    },
    'kn': {
      'dashboard.welcomeBack': 'ಮತ್ತೆ ಸ್ವಾಗತ',
      'dashboard.farmer': 'ರೈತ',
      'dashboard.notifications': 'ಸೂಚನೆಗಳು',
      'dashboard.logout': 'ಲಾಗ್ ಔಟ್',
      'dashboard.logoutConfirmation': 'ನೀವು ಖಂಡಿತವಾಗಿಯೂ ಲಾಗ್ ಔಟ್ ಮಾಡಲು ಬಯಸುವಿರಾ?',
      'dashboard.logoutButton': 'ಲಾಗ್ ಔಟ್',
      'dashboard.logoutError': 'ಲಾಗ್ ಔಟ್ ಸಮಯದಲ್ಲಿ ದೋಷ',
      'dashboard.searchCrops': 'ಬೆಳೆಗಳನ್ನು ಹುಡುಕಿ...',
      'dashboard.inStock': 'ಸ್ಟಾಕ್‌ನಲ್ಲಿ',
      'dashboard.outOfStock': 'ಸ್ಟಾಕ್ ಕೊನೆಯಾಗಿದೆ',
      'dashboard.all': 'ಎಲ್ಲಾ',
      'dashboard.stock': 'ಸ್ಟಾಕ್',
      'dashboard.sort': 'ವಿಂಗಡಿಸಿ',
      'dashboard.newest': 'ಹೊಸದು',
      'dashboard.priceAsc': 'ಬೆಲೆ: ಕಡಿಮೆ ಇಂದ ಹೆಚ್ಚು',
      'dashboard.priceDesc': 'ಬೆಲೆ: ಹೆಚ್ಚು ಇಂದ ಕಡಿಮೆ',
      'dashboard.quantityDesc': 'ಪ್ರಮಾಣ: ಹೆಚ್ಚು ಇಂದ ಕಡಿಮೆ',
      'dashboard.noCropsListed': 'ಇನ್ನೂ ಯಾವುದೇ ಬೆಳೆಗಳನ್ನು ಪಟ್ಟಿ ಮಾಡಿಲ್ಲ',
      'dashboard.addFirstCrop': 'ನಿಮ್ಮ ಮೊದಲ ಬೆಳೆಯನ್ನು ಸೇರಿಸಿ',
      'dashboard.home': 'ಮುಖಪುಟ',
      'dashboard.add': 'ಸೇರಿಸಿ',
      'dashboard.suggestions': 'ಸಲಹೆಗಳು',
      'dashboard.disease': 'ರೋಗ',
      'dashboard.chat': 'ಚಾಟ್',
      'dashboard.profile': 'ಪ್ರೊಫೈಲ್',
      'dashboard.editCrop': 'ಬೆಳೆಯನ್ನು ಸಂಪಾದಿಸಿ',
      'dashboard.cropName': 'ಬೆಳೆಯ ಹೆಸರು',
      'dashboard.cropNamePlaceholder': 'ಬೆಳೆಯ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
      'dashboard.price': 'ಪ್ರತಿ ಕೆಜಿ ಬೆಲೆ',
      'dashboard.pricePlaceholder': 'ಪ್ರತಿ ಕೆಜಿ ಬೆಲೆಯನ್ನು ನಮೂದಿಸಿ',
      'dashboard.quantity': 'ಪ್ರಮಾಣ (ಕೆಜಿ)',
      'dashboard.quantityPlaceholder': 'ಪ್ರಮಾಣವನ್ನು ನಮೂದಿಸಿ',
      'dashboard.description': 'ವಿವರಣೆ',
      'dashboard.descriptionPlaceholder': 'ಬೆಳೆಯ ವಿವರಣೆಯನ್ನು ನಮೂದಿಸಿ (ಕನಿಷ್ಠ 10 ಪದಗಳು)',
      'dashboard.descriptionMinWords': 'ವಿವರಣೆಯಲ್ಲಿ ಕನಿಷ್ಠ 10 ಪದಗಳಿರಬೇಕು',
      'dashboard.statusAutoSetNote': 'ಪ್ರಮಾಣದ ಆಧಾರದ ಮೇಲೆ ಸ್ಥಿತಿಯನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಹೊಂದಿಸಲಾಗುತ್ತದೆ',
      'common.cancel': 'ರದ್ದುಮಾಡಿ',
      'common.save': 'ಉಳಿಸಿ',
      'common.ok': 'ಸರಿ',
      'common.error': 'ದೋಷ',
      'common.success': 'ಯಶಸ್ವಿ',
      'common.retry': 'ಮರುಪ್ರಯತ್ನಿಸಿ',
      'common.delete': 'ಅಳಿಸಿ',
      'common.invalid': 'ಅಮಾನ್ಯ',
      'common.edit': 'ಸಂಪಾದಿಸಿ',
      'dashboard.deleteCrop': 'ಬೆಳೆಯನ್ನು ಅಳಿಸಿ',
      'dashboard.deleteCropConfirmation': 'ನೀವು ಈ ಬೆಳೆಯನ್ನು ಖಂಡಿತವಾಗಿಯೂ ಅಳಿಸಲು ಬಯಸುವಿರಾ?',
      'dashboard.cropRemovedSuccess': 'ಬೆಳೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
      'dashboard.cropDeleteError': 'ಬೆಳೆಯನ್ನು ಅಳಿಸುವಲ್ಲಿ ದೋಷ',
      'dashboard.quantityPositiveError': 'ಪ್ರಮಾಣವು ಧನಾತ್ಮಕ ಸಂಖ್ಯೆಯಾಗಿರಬೇಕು',
      'dashboard.pricePositiveError': 'ಬೆಲೆಯು ಧನಾತ್ಮಕ ಸಂಖ್ಯೆಯಾಗಿರಬೇಕು',
      'dashboard.cropUpdateSuccess': 'ಬೆಳೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ',
      'dashboard.saveUpdateError': 'ನವೀಕರಣವನ್ನು ಉಳಿಸುವಲ್ಲಿ ದೋಷ',
      'dashboard.permissionDenied': 'ಅನುಮತಿ ನಿರಾಕರಿಸಲಾಗಿದೆ',
      'dashboard.imageAccessPermission': 'ಚಿತ್ರಗಳನ್ನು ಪ್ರವೇಶಿಸಲು ದಯವಿಟ್ಟು ಅನುಮತಿ ನೀಡಿ',
      'dashboard.imagePickError': 'ಚಿತ್ರವನ್ನು ಆಯ್ಕೆ ಮಾಡುವಲ್ಲಿ ದೋಷ',
      'dashboard.imageUploadFailed': 'ಚಿತ್ರ ಅಪ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ, ಆದರೆ ಬೆಳೆಯನ್ನು ಸೇರಿಸಲಾಗಿದೆ',
      'dashboard.cropNameRequired': 'ಬೆಳೆಯ ಹೆಸರು ಅಗತ್ಯವಿದೆ',
      'dashboard.produceAddedSuccess': 'ಉತ್ಪನ್ನವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಸೇರಿಸಲಾಗಿದೆ',
      'dashboard.addProduceError': 'ಉತ್ಪನ್ನವನ್ನು ಸೇರಿಸುವಲ್ಲಿ ದೋಷ',
      'dashboard.navigationError': 'ನ್ಯಾವಿಗೇಶನ್ ದೋಷ',
      'dashboard.pageUnavailable': 'ಪುಟ ಲಭ್ಯವಿಲ್ಲ: {page}',
      'dashboard.messages': 'ಸಂದೇಶಗಳು',
      'dashboard.noNewMessages': 'ಹೊಸ ಸಂದೇಶಗಳಿಲ್ಲ',
      'dashboard.fetchMessagesError': 'ಸಂದೇಶಗಳನ್ನು ಪಡೆಯುವಲ್ಲಿ ದೋಷ',
      'dashboard.accessNotificationsError': 'ಸೂಚನೆಗಳನ್ನು ಪ್ರವೇಶಿಸುವಲ್ಲಿ ದೋಷ',
      'dashboard.weatherUnavailable': 'ಹವಾಮಾನ ಡೇಟಾ ಲಭ್ಯವಿಲ್ಲ',
      'dashboard.locationPermissionDenied': 'ಸ್ಥಳ ಅನುಮತಿ ನಿರಾಕರಿಸಲಾಗಿದೆ',
      'dashboard.weatherLoadError': 'ಹವಾಮಾನ ಡೇಟಾವನ್ನು ಲೋಡ್ ಮಾಡುವಲ್ಲಿ ದೋಷ',
      'dashboard.loadDataError': 'ಡೇಟಾವನ್ನು ಲೋಡ್ ಮಾಡುವಲ್ಲಿ ದೋಷ',
      'dashboard.errorLoadUserData': 'ಬಳಕೆದಾರ ಡೇಟಾವನ್ನು ಲೋಡ್ ಮಾಡುವಲ್ಲಿ ದೋಷ',
      'dashboard.apiKeyMissing': 'ಹವಾಮಾನ ಸೇವೆ ಲಭ್ಯವಿಲ್ಲ: API ಕೀ ಕಾನ್ಫಿಗರ್ ಮಾಡಿಲ್ಲ',
      'dashboard.location': 'ಸ್ಥಳ',
      'dashboard.locationPlaceholder': 'ಸ್ಥಳವನ್ನು ಪಡೆಯಲಾಗುತ್ತಿದೆ...',
      'dashboard.locationError': 'ಸ್ಥಳವನ್ನು ಪಡೆಯಲಾಗಲಿಲ್ಲ',
      'dashboard.enableLocation': 'ದಯವಿಟ್ಟು ಸ್ಥಳ ಸೇವೆಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ',
      'dashboard.enableLocationButton': 'ಸ್ಥಳ ಸಕ್ರಿಯಗೊಳಿಸಿ',
      'dashboard.day': 'ಹಗಲು',
      'dashboard.night': 'ರಾತ್ರಿ',
    },
    // Add other language translations here (hi, ta, te)...
  };

  // Current language
  String _selectedLang = 'en'; // Default to English
  
  // State variables
  String? userId;
  bool languageLoaded = false;
  String farmerName = "";
  List<Map<String, dynamic>> produce = [];
  bool loading = true;
  bool refreshing = false;
  String errorMsg = "";
  
  // Weather state
  Map<String, dynamic>? weather;
  bool weatherLoading = true;
  String weatherError = "";
  
  // Location state
  String locationText = "";
  bool locationLoading = true;
  String locationError = "";
  double? latitude;
  double? longitude;
  
  // Edit/Add modals state
  bool savingEdit = false;
  bool addingProduce = false;
  
  // Form fields for edit / add
  Map<String, String> form = {
    'crop_name': '',
    'price_per_kg': '',
    'quantity': '',
    'status': 'in_stock',
    'image_uri': '',
    'description': '', // Added description field
  };
  
  // Notifications state
  int unreadNotificationsCount = 0;
  
  // Search / filter / sort state
  String searchQuery = "";
  String filterStock = "all"; // all | in_stock | out_of_stock
  String sortBy = "newest"; // newest | price_asc | price_desc | qty_desc
  
  // Dropdown visibility states
  bool showFilterDropdown = false;
  bool showSortDropdown = false;
  
  // Editing state
  String? editingCropId;
  Map<String, dynamic>? editingCrop;
  
  // Supabase client
  final SupabaseClient supabase = Supabase.instance.client;
  
  // Image picker
  final ImagePicker picker = ImagePicker();
  
  // Constants
  final String placeholderImage = "https://via.placeholder.com/600x400.png?text=No+Image";
  
  // Global key for scaffold messenger
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Bottom navigation index
  int _currentIndex = 0;

  // Helper method to get translation based on current language
  String t(String key) {
    return translations[_selectedLang]?[key] ?? translations['en']?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> _loadLanguageAndCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLang = prefs.getString('selectedLanguage') ?? "en";
    await _checkStoredCredentials();
  }

  Future<void> _checkStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    setState(() {
      userId = id;
    });
  }

  Future<void> initialize() async {
    try {
      // Load environment variables
      await dotenv.load(fileName: "assets/.env");
      
      // Load language and credentials
      await _loadLanguageAndCredentials();
      
      // Set language loaded state
      setState(() {
        languageLoaded = true;
      });
      
      // Fetch data if userId is available
      if (userId != null) {
        setupRealtimeSubscriptions(userId!);
        fetchAll();
      }
    } catch (err) {
      print('Error initializing dashboard: $err');
      setState(() {
        errorMsg = t('dashboard.errorLoadUserData');
        languageLoaded = true;
      });
    }
  }

  Future<void> setupRealtimeSubscriptions(String uid) async {
    try {
      // Notifications channel
      final notificationsChannel = supabase.channel('notifications');
      notificationsChannel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        callback: (payload) async {
          try {
            final newRecord = payload.newRecord;
            final userId = newRecord['user_id'];
            final read = newRecord['read'];
            
            if (userId == uid && !read) {
              final count = await fetchUnreadNotificationsCount(uid);
              if (mounted) {
                setState(() {
                  unreadNotificationsCount = count;
                });
              }
            }
          } catch (e) {
            print('Realtime notification handling error: $e');
          }
        },
      ).subscribe();
    } catch (e) {
      print('setupRealtimeSubscriptions error: $e');
    }
  }

  Future<int> fetchUnreadNotificationsCount(String uid) async {
    try {
      final data = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('read', false);
      
      return data.length;
    } catch (err) {
      print('Error fetching unread notifications: $err');
      return 0;
    }
  }

  Future<void> fetchLocation() async {
    setState(() {
      locationLoading = true;
      locationError = "";
    });
    
    try {
      bool serviceEnabled;
      LocationPermission permissionGranted;
      
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationError = t('dashboard.enableLocation');
          locationLoading = false;
        });
        return;
      }
      
      // Check location permission
      permissionGranted = await Geolocator.checkPermission();
      if (permissionGranted == LocationPermission.denied) {
        permissionGranted = await Geolocator.requestPermission();
        if (permissionGranted == LocationPermission.denied) {
          setState(() {
            locationError = t('dashboard.locationPermissionDenied');
            locationLoading = false;
          });
          return;
        }
      }
      
      if (permissionGranted == LocationPermission.deniedForever) {
        setState(() {
          locationError = t('dashboard.locationPermissionDenied');
          locationLoading = false;
        });
        return;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
          locationText = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
          locationLoading = false;
        });
      }
      
      // Cache location data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dashboard_latitude', position.latitude.toString());
      await prefs.setString('dashboard_longitude', position.longitude.toString());
    } catch (err) {
      print('fetchLocation error: $err');
      
      // Try to get cached location
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getString('dashboard_latitude');
      final cachedLon = prefs.getString('dashboard_longitude');
      
      if (cachedLat != null && cachedLon != null && mounted) {
        setState(() {
          latitude = double.tryParse(cachedLat);
          longitude = double.tryParse(cachedLon);
          locationText = "$cachedLat, $cachedLon";
          locationLoading = false;
        });
      } else if (mounted) {
        setState(() {
          locationError = t('dashboard.locationError');
          locationLoading = false;
        });
      }
    }
  }

  Future<void> fetchWeather() async {
    setState(() {
      weatherLoading = true;
      weatherError = "";
    });
    
    try {
      // Get API key from environment variables
      final String? weatherKey = dotenv.env['OPEN_WEATHER_API_KEY'];
      
      if (weatherKey == null || weatherKey.isEmpty) {
        throw Exception(t('dashboard.apiKeyMissing'));
      }
      
      // Get location if not available
      if (latitude == null || longitude == null) {
        await fetchLocation();
      }
      
      if (latitude == null || longitude == null) {
        throw Exception('Location not available');
      }
      
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherKey&units=metric'
        ),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            weather = data;
          });
        }
        
        // Cache weather data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('dashboard_weather', jsonEncode(data));
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (err) {
      print('fetchWeather error: $err');
      
      // Try to get cached weather
      final prefs = await SharedPreferences.getInstance();
      final cachedWeather = prefs.getString('dashboard_weather');
      if (cachedWeather != null && mounted) {
        setState(() {
          weather = jsonDecode(cachedWeather);
        });
      }
      
      if (mounted) {
        setState(() {
          weatherError = err.toString().contains('API key') 
              ? t('dashboard.apiKeyMissing') 
              : t('dashboard.weatherLoadError');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          weatherLoading = false;
        });
      }
    }
  }

  Future<void> fetchData() async {
    if (userId == null) return;
    
    setState(() {
      errorMsg = "";
      loading = true;
    });
    
    try {
      // Fetch farmer profile
      final profileResponse = await supabase
          .from('profiles')
          .select('name')
          .eq('id', userId!)
          .single();
      
      // Fetch produce data
      final produceResponse = await supabase
          .from('produce')
          .select('*')
          .eq('farmer_id', userId!)
          .order('created_at', ascending: false);
      
      // Fetch unread counts
      final unreadNotifCnt = await fetchUnreadNotificationsCount(userId!);
      
      // Update state
      if (mounted) {
        setState(() {
          farmerName = profileResponse['name'] ?? "";
          produce = List<Map<String, dynamic>>.from(produceResponse);
          unreadNotificationsCount = unreadNotifCnt;
        });
      }
      
      // Cache data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dashboard_farmer_name', profileResponse['name'] ?? "");
      await prefs.setString('dashboard_produce', jsonEncode(produceResponse));
    } catch (err) {
      print('fetchData error: $err');
      if (mounted) {
        setState(() {
          errorMsg = err.toString();
        });
      }
      
      // Fallback to cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final farmerNameCached = prefs.getString('dashboard_farmer_name');
        final produceCached = prefs.getString('dashboard_produce');
        
        if (mounted) {
          setState(() {
            farmerName = farmerNameCached ?? "";
            if (produceCached != null) {
              produce = List<Map<String, dynamic>>.from(jsonDecode(produceCached));
            }
          });
        }
      } catch (e) {
        print('cache fallback error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          refreshing = false;
        });
      }
    }
  }

  Future<void> fetchAll() async {
    await Future.wait([fetchLocation(), fetchWeather(), fetchData()]);
  }

  void handleDelete(String cropId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('dashboard.deleteCrop')),
        content: Text(t('dashboard.deleteCropConfirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await supabase
                    .from('produce')
                    .delete()
                    .eq('id', cropId)
                    .eq('farmer_id', userId!);
                
                if (mounted) {
                  setState(() {
                    produce = produce.where((p) => p['id'] != cropId).toList();
                  });
                  
                  // Use the global key to show snackbar
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(content: Text(t('dashboard.cropRemovedSuccess'))),
                  );
                }
              } catch (err) {
                print('Delete failed: $err');
                if (mounted) {
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(content: Text(t('dashboard.cropDeleteError'))),
                  );
                }
              }
            },
            child: Text(t('common.delete')),
          ),
        ],
      ),
    );
  }

  void startEditing(Map<String, dynamic> item) {
    setState(() {
      editingCropId = item['id'];
      editingCrop = item;
      form = {
        'crop_name': item['crop_name'] ?? '',
        'price_per_kg': (item['price_per_kg'] ?? 0).toString(),
        'quantity': (item['quantity'] ?? 0).toString(),
        'status': item['status'] == 'out_of_stock' ? 'out_of_stock' : 'in_stock',
        'image_uri': item['image_url'] ?? '',
        'description': item['description'] ?? '', // Added description field
      };
    });
  }

  void cancelEditing() {
    setState(() {
      editingCropId = null;
      editingCrop = null;
      form = {
        'crop_name': '',
        'price_per_kg': '',
        'quantity': '',
        'status': 'in_stock',
        'image_uri': '',
        'description': '', // Reset description field
      };
    });
  }

  // Helper function to validate description word count
  bool _isValidDescription(String description) {
    if (description.trim().isEmpty) return true; // Empty description is allowed
    final words = description.trim().split(RegExp(r'\s+'));
    return words.length >= 10;
  }

  Future<void> handleSaveUpdate() async {
    if (!mounted) return;
    if (editingCropId == null || editingCrop == null) return;
    
    // Validate form data
    final parsedQty = int.tryParse(form['quantity'] ?? '0') ?? 0;
    final parsedPrice = double.tryParse(form['price_per_kg'] ?? '0') ?? 0;
    
    if (parsedQty < 0) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('common.invalid')),
          content: Text(t('dashboard.quantityPositiveError')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('common.ok')),
            ),
          ],
        ),
      );
    }
    
    if (parsedPrice < 0) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('common.invalid')),
          content: Text(t('dashboard.pricePositiveError')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('common.ok')),
            ),
          ],
        ),
      );
    }
    
    // Validate description word count
    if (!_isValidDescription(form['description'] ?? '')) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('common.invalid')),
          content: Text(t('dashboard.descriptionMinWords')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('common.ok')),
            ),
          ],
        ),
      );
    }
    
    final finalStatus = parsedQty > 0 ? 'in_stock' : 'out_of_stock';
    final updatedFields = {
      'quantity': parsedQty,
      'price_per_kg': parsedPrice,
      'status': finalStatus,
      'crop_name': form['crop_name'],
      'description': form['description'], // Added description field
    };
    
    try {
      setState(() {
        savingEdit = true;
      });
      
      final response = await supabase
          .from('produce')
          .update(updatedFields)
          .eq('id', editingCropId!)
          .eq('farmer_id', userId!)
          .select();
      
      final updated = response.isNotEmpty ? response[0] : {...editingCrop!, ...updatedFields};
      
      if (mounted) {
        setState(() {
          produce = produce.map((p) => p['id'] == editingCropId ? updated : p).toList();
          editingCropId = null;
          editingCrop = null;
        });
        
        // Use the global key to show snackbar
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(t('dashboard.cropUpdateSuccess'))),
        );
      }
    } catch (err) {
      print('Save update failed: $err');
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(t('dashboard.saveUpdateError'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          savingEdit = false;
        });
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          form['image_uri'] = image.path;
        });
      }
    } catch (err) {
      print('Image pick error: $err');
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(t('dashboard.imagePickError'))),
        );
      }
    }
  }

  Future<String?> uploadImageToSupabase(String uri, {String filenamePrefix = 'produce_'}) async {
    try {
      if (uri.isEmpty) return null;
      
      final file = File(uri);
      final bytes = await file.readAsBytes();
      final ext = uri.split('.').last;
      final fileName = '$filenamePrefix${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      final response = await supabase.storage
          .from('produce-images')
          .uploadBinary(fileName, bytes);
      
      if (response.isEmpty) return null;
      
      final publicUrlResponse = supabase.storage
          .from('produce-images')
          .getPublicUrl(fileName);
      
      return publicUrlResponse;
    } catch (err) {
      print('uploadImageToSupabase error: $err');
      return null;
    }
  }

  Future<void> handleAddProduce() async {
    if (!mounted) return;
    
    // Validate form data
    if (form['crop_name']?.trim().isEmpty ?? true) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('common.invalid')),
          content: Text(t('dashboard.cropNameRequired')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('common.ok')),
            ),
          ],
        ),
      );
    }
    
    final parsedQty = int.tryParse(form['quantity'] ?? '0') ?? 0;
    final parsedPrice = double.tryParse(form['price_per_kg'] ?? '0') ?? 0;
    
    if (parsedQty < 0) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('common.invalid')),
          content: Text(t('dashboard.quantityPositiveError')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('common.ok')),
            ),
          ],
        ),
      );
    }
    
    if (parsedPrice < 0) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('common.invalid')),
          content: Text(t('dashboard.pricePositiveError')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('common.ok')),
            ),
          ],
        ),
      );
    }
    
    // Validate description word count
    if (!_isValidDescription(form['description'] ?? '')) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('common.invalid')),
          content: Text(t('dashboard.descriptionMinWords')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('common.ok')),
            ),
          ],
        ),
      );
    }
    
    try {
      setState(() {
        addingProduce = true;
      });
      
      // Upload image if provided
      String? imageUrl = form['image_uri']?.isNotEmpty == true ? form['image_uri'] : null;
      if (imageUrl != null && imageUrl.startsWith('/')) {
        final uploaded = await uploadImageToSupabase(imageUrl);
        if (uploaded != null) {
          imageUrl = uploaded;
        } else {
          if (mounted) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text(t('dashboard.imageUploadFailed'))),
            );
          }
        }
      }
      
      final insertPayload = {
        'farmer_id': userId,
        'crop_name': form['crop_name'],
        'price_per_kg': parsedPrice,
        'quantity': parsedQty,
        'status': parsedQty > 0 ? 'in_stock' : 'out_of_stock',
        'image_url': imageUrl,
        'description': form['description'], // Added description field
      };
      
      final response = await supabase
          .from('produce')
          .insert([insertPayload])
          .select();
      
      if (response.isNotEmpty && mounted) {
        setState(() {
          produce = [response[0], ...produce];
          form = {
            'crop_name': '',
            'price_per_kg': '',
            'quantity': '',
            'status': 'in_stock',
            'image_uri': '',
            'description': '', // Reset description field
          };
        });
        
        // Use the global key to show snackbar
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(t('dashboard.produceAddedSuccess'))),
        );
      }
    } catch (err) {
      print('add produce error: $err');
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(t('dashboard.addProduceError'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          addingProduce = false;
        });
      }
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
      
      Navigator.pushNamed(context, '/notifications');
    } catch (err) {
      print('Error handling notifications: $err');
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(t('dashboard.accessNotificationsError'))),
        );
      }
    }
  }

  void handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('dashboard.logout')),
        content: Text(t('dashboard.logoutConfirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                
                // Remove all Supabase channels
                await supabase.removeAllChannels();
                
                Navigator.pushReplacementNamed(context, '/login');
              } catch (err) {
                print('Logout error: $err');
                if (mounted) {
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(content: Text(t('dashboard.logoutError'))),
                  );
                }
              }
            },
            child: Text(t('dashboard.logoutButton')),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get filteredProduce {
    List<Map<String, dynamic>> list = List.from(produce);
    
    // Apply search filter
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) => (p['crop_name'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    
    // Apply stock filter
    if (filterStock == 'in_stock') {
      list = list.where((p) => (p['quantity'] ?? 0) > 0).toList();
    } else if (filterStock == 'out_of_stock') {
      list = list.where((p) => (p['quantity'] ?? 0) <= 0).toList();
    }
    
    // Apply sorting
    switch (sortBy) {
      case 'price_asc':
        list.sort((a, b) => ((a['price_per_kg'] ?? 0) as num).compareTo((b['price_per_kg'] ?? 0) as num));
        break;
      case 'price_desc':
        list.sort((a, b) => ((b['price_per_kg'] ?? 0) as num).compareTo((a['price_per_kg'] ?? 0) as num));
        break;
      case 'qty_desc':
        list.sort((a, b) => ((b['quantity'] ?? 0) as num).compareTo((a['quantity'] ?? 0) as num));
        break;
      case 'newest':
      default:
        list.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    }
    
    return list;
  }

  String displayStatus(Map<String, dynamic> item) {
    return (item['quantity'] ?? 0) > 0
        ? 'in_stock'
        : item['status'] == 'in_stock'
            ? 'in_stock'
            : 'out_of_stock';
  }

  String getWeatherEmoji(String? weatherMain, String? iconCode) {
    // First check if it's day or night based on icon code
    if (iconCode != null) {
      if (iconCode.endsWith('n')) {
        // Night time
        const nightWeatherMap = {
          '01': '🌙', // Clear night
          '02': '☁️', // Few clouds night
          '03': '☁️', // Scattered clouds night
          '04': '☁️', // Broken clouds night
          '09': '🌧️', // Shower rain night
          '10': '🌧️', // Rain night
          '11': '⛈️', // Thunderstorm night
          '13': '❄️', // Snow night
          '50': '🌫️', // Mist night
        };
        final code = iconCode.substring(0, 2);
        return nightWeatherMap[code] ?? '🌙';
      } else {
        // Day time
        const dayWeatherMap = {
          '01': '☀️', // Clear day
          '02': '⛅', // Few clouds day
          '03': '☁️', // Scattered clouds day
          '04': '☁️', // Broken clouds day
          '09': '🌧️', // Shower rain day
          '10': '🌧️', // Rain day
          '11': '⛈️', // Thunderstorm day
          '13': '❄️', // Snow day
          '50': '🌫️', // Mist day
        };
        final code = iconCode.substring(0, 2);
        return dayWeatherMap[code] ?? '☀️';
      }
    }
    
    // Fallback to weather main if icon code is not available
    const weatherMap = {
      'Clear': '☀️',
      'Clouds': '☁️',
      'Rain': '🌧️',
      'Drizzle': '🌧️',
      'Thunderstorm': '⛈️',
      'Snow': '❄️',
      'Mist': '🌫️',
      'Fog': '🌫️',
      'Haze': '🌫️',
    };
    return weatherMap[weatherMain] ?? '🌡️';
  }

  String fmtCurrency(num n) {
    return '₹${n.toStringAsFixed(2)}';
  }

  // Handle bottom navigation tap
  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Navigate to respective pages
    switch (index) {
      case 0: // Home - already on dashboard
        break;
      case 1: // Add
        Navigator.pushNamed(context, '/add_produce');
        break;
      case 2: // Suggestions
        Navigator.pushNamed(context, '/suggestions');
        break;
      case 3: // Disease
        Navigator.pushNamed(context, '/disease');
        break;
      case 4: // Chat
        Navigator.pushNamed(context, '/conversations');
        break;
      case 5: // Profile
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  // Show crop details dialog
  void _showCropDetailsDialog(Map<String, dynamic> crop) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: _buildBigCard(crop),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!languageLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomNavHeight = 56.0; // Height of bottom navigation bar
    final systemBottomPadding = MediaQuery.of(context).padding.bottom; // System navigation padding
    
    // Calculate responsive values
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isSmallScreen ? 12.0 : (isTablet ? 24.0 : 18.0);
    final cardWidth = (screenWidth - (horizontalPadding * 2) - 16) / 2; // 16 is for spacing

    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9F1),
        appBar: AppBar(
          automaticallyImplyLeading: false, // This removes the back button
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    '👨‍🌾',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('dashboard.welcomeBack'),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      farmerName.isNotEmpty ? farmerName : t('dashboard.farmer'),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Notification Button
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
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: handleNotificationsPress,
                  ),
                ),
                if (unreadNotificationsCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ]),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: handleLogout,
              ),
            ),
          ],
          backgroundColor: const Color(0xFF4CAF50),
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              refreshing = true;
            });
            await fetchAll();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding, 
                0, 
                horizontalPadding, 
                bottomNavHeight + systemBottomPadding + 20, // Add system navigation padding
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Weather and Location Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      children: [
                        // Weather section
                        weatherLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : weatherError.isNotEmpty
                                ? Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          weatherError,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  )
                                : weather != null
                                    ? Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              getWeatherEmoji(
                                                weather?['weather']?[0]?['main'],
                                                weather?['weather']?[0]?['icon'],
                                              ),
                                              style: TextStyle(fontSize: isSmallScreen ? 36 : 42),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${(weather?['main']?['temp'] ?? 0).round()}°C',
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen ? 24 : 28,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      weather?['weather']?[0]?['icon']?.toString().endsWith('n') == true
                                                          ? t('dashboard.night')
                                                          : t('dashboard.day'),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  weather?['weather']?[0]?['description'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Feels like ${(weather?['main']?['feels_like'] ?? 0).round()}°C',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          const Icon(
                                            Icons.cloud_off,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              t('dashboard.weatherUnavailable'),
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                        
                        const SizedBox(height: 16),
                        
                        // Location section
                        const Divider(height: 1, color: Colors.white30),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: locationLoading
                                  ? Text(
                                      t('dashboard.locationPlaceholder'),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    )
                                  : locationError.isNotEmpty
                                      ? Text(
                                          locationError,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        )
                                      : Text(
                                          locationText.isNotEmpty ? locationText : t('dashboard.locationError'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                            ),
                            if (!locationLoading && locationError.isEmpty)
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: fetchLocation,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Search box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Color(0xFF4CAF50),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: t('dashboard.searchCrops'),
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Filter and Sort Dropdowns
                  Row(
                    children: [
                      // Filter Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('dashboard.stock'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  showFilterDropdown = !showFilterDropdown;
                                  showSortDropdown = false;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      filterStock == 'all'
                                          ? t('dashboard.all')
                                          : filterStock == 'in_stock'
                                              ? t('dashboard.inStock')
                                              : t('dashboard.outOfStock'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      showFilterDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (showFilterDropdown)
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildDropdownOption(
                                        title: t('dashboard.all'),
                                        value: 'all',
                                        groupValue: filterStock,
                                        onChanged: (value) {
                                          setState(() {
                                            filterStock = value!;
                                            showFilterDropdown = false;
                                          });
                                        },
                                      ),
                                      const Divider(height: 1),
                                      _buildDropdownOption(
                                        title: t('dashboard.inStock'),
                                        value: 'in_stock',
                                        groupValue: filterStock,
                                        onChanged: (value) {
                                          setState(() {
                                            filterStock = value!;
                                            showFilterDropdown = false;
                                          });
                                        },
                                      ),
                                      const Divider(height: 1),
                                      _buildDropdownOption(
                                        title: t('dashboard.outOfStock'),
                                        value: 'out_of_stock',
                                        groupValue: filterStock,
                                        onChanged: (value) {
                                          setState(() {
                                            filterStock = value!;
                                            showFilterDropdown = false;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Sort Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('dashboard.sort'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  showSortDropdown = !showSortDropdown;
                                  showFilterDropdown = false;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      sortBy == 'newest'
                                          ? t('dashboard.newest')
                                          : sortBy == 'price_asc'
                                              ? t('dashboard.priceAsc')
                                              : sortBy == 'price_desc'
                                                  ? t('dashboard.priceDesc')
                                                  : t('dashboard.quantityDesc'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      showSortDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (showSortDropdown)
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 250,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        _buildDropdownOption(
                                          title: t('dashboard.newest'),
                                          value: 'newest',
                                          groupValue: sortBy,
                                          onChanged: (value) {
                                            setState(() {
                                              sortBy = value!;
                                              showSortDropdown = false;
                                            });
                                          },
                                        ),
                                        const Divider(height: 1),
                                        _buildDropdownOption(
                                          title: t('dashboard.priceAsc'),
                                          value: 'price_asc',
                                          groupValue: sortBy,
                                          onChanged: (value) {
                                            setState(() {
                                              sortBy = value!;
                                              showSortDropdown = false;
                                            });
                                          },
                                        ),
                                        const Divider(height: 1),
                                        _buildDropdownOption(
                                          title: t('dashboard.priceDesc'),
                                          value: 'price_desc',
                                          groupValue: sortBy,
                                          onChanged: (value) {
                                            setState(() {
                                              sortBy = value!;
                                              showSortDropdown = false;
                                            });
                                          },
                                        ),
                                        const Divider(height: 1),
                                        _buildDropdownOption(
                                          title: t('dashboard.quantityDesc'),
                                          value: 'qty_desc',
                                          groupValue: sortBy,
                                          onChanged: (value) {
                                            setState(() {
                                              sortBy = value!;
                                              showSortDropdown = false;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Edit Form (conditionally rendered)
                  if (editingCropId != null && editingCrop != null)
                    _buildEditForm(),
                  
                  // Crops Grid
                  if (editingCropId == null)
                    loading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                              ),
                            ),
                          )
                        : errorMsg.isNotEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFF4CAF50),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        errorMsg,
                                        style: const TextStyle(color: Color(0xFF4CAF50)),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            errorMsg = "";
                                            loading = true;
                                          });
                                          fetchAll();
                                        },
                                        child: Text(t('common.retry')),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : filteredProduce.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(40.0),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.agriculture,
                                            color: Color(0xFF4CAF50),
                                            size: 64,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            t('dashboard.noCropsListed'),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4CAF50),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            t('dashboard.addFirstCrop'),
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pushNamed(context, '/add_produce');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4CAF50),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            ),
                                            child: Text(t('dashboard.add')),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2, // Always show 2 cards in a row
                                      childAspectRatio: 0.65, // Adjusted for smaller cards
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: filteredProduce.length,
                                    itemBuilder: (context, index) {
                                      final crop = filteredProduce[index];
                                      
                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: screenHeight * 0.5, // Reduced height
                                        ),
                                        child: _buildCompactCropCard(crop),
                                      );
                                    },
                                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(systemBottomPadding),
      ),
    );
  }

  Widget _buildDropdownOption({
    required String title,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: const Color(0xFF4CAF50),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildCompactCropCard(Map<String, dynamic> crop) {
    final status = displayStatus(crop);
    final inStock = status == 'in_stock';
    
    return InkWell(
      onTap: () {
        _showCropDetailsDialog(crop);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(
                      crop['image_url'] ?? placeholderImage,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            // Crop Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop['crop_name'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmtCurrency(crop['price_per_kg'] ?? 0),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: inStock ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            inStock ? t('dashboard.inStock') : t('dashboard.outOfStock'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: inStock ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${crop['quantity'] ?? 0} kg',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
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

  Widget _buildBigCard(Map<String, dynamic> crop) {
    final status = displayStatus(crop);
    final inStock = status == 'in_stock';
    final description = crop['description'] ?? '';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                crop['crop_name'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Crop Image
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(
                  crop['image_url'] ?? placeholderImage,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Price and Quantity
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  title: 'Price',
                  value: fmtCurrency(crop['price_per_kg'] ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailItem(
                  title: 'Quantity',
                  value: '${crop['quantity'] ?? 0} kg',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: inStock ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  inStock ? t('dashboard.inStock') : t('dashboard.outOfStock'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: inStock ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
          
          // Description - only show if not empty
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              t('dashboard.description'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    startEditing(crop);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(t('common.edit')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    handleDelete(crop['id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(t('common.delete')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(double systemBottomPadding) {
    return Container(
      height: 56.0 + systemBottomPadding, // Add system navigation padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home
            _buildBottomNavItem(
              icon: Icons.home,
              label: t('dashboard.home'),
              index: 0,
            ),
            // Add
            _buildBottomNavItem(
              icon: Icons.add_circle,
              label: t('dashboard.add'),
              index: 1,
            ),
            // Suggestions
            _buildBottomNavItem(
              icon: Icons.lightbulb,
              label: t('dashboard.suggestions'),
              index: 2,
            ),
            // Disease
            _buildBottomNavItem(
              icon: Icons.sick,
              label: t('dashboard.disease'),
              index: 3,
            ),
            // Chat
            _buildBottomNavItem(
              icon: Icons.chat,
              label: t('dashboard.chat'),
              index: 4,
            ),
            // Profile
            _buildBottomNavItem(
              icon: Icons.person,
              label: t('dashboard.profile'),
              index: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTap(index),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _currentIndex == index ? const Color(0xFF4CAF50) : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _currentIndex == index ? const Color(0xFF4CAF50) : Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Edit Form (rendered inline)
  Widget _buildEditForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('dashboard.editCrop'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              IconButton(
                onPressed: cancelEditing,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Crop Name Field
          Text(
            t('dashboard.cropName'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: t('dashboard.cropNamePlaceholder'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC5E1A5)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            controller: TextEditingController(text: form['crop_name']),
            onChanged: (value) {
              setState(() {
                form['crop_name'] = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Price Field
          Text(
            t('dashboard.price'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: t('dashboard.pricePlaceholder'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC5E1A5)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            controller: TextEditingController(text: form['price_per_kg']),
            onChanged: (value) {
              setState(() {
                form['price_per_kg'] = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Quantity Field
          Text(
            t('dashboard.quantity'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: t('dashboard.quantityPlaceholder'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC5E1A5)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: form['quantity']),
            onChanged: (value) {
              setState(() {
                form['quantity'] = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Description Field
          Text(
            t('dashboard.description'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: t('dashboard.descriptionPlaceholder'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC5E1A5)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 3,
            controller: TextEditingController(text: form['description']),
            onChanged: (value) {
              setState(() {
                form['description'] = value;
              });
            },
          ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: cancelEditing,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF9E9E9E)),
                  ),
                  child: Text(t('common.cancel')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: savingEdit ? null : handleSaveUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: savingEdit
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(t('common.save')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Note
          Text(
            t('dashboard.statusAutoSetNote'),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}