import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';
import 'dart:convert';

class AddProducePage extends StatefulWidget {
  const AddProducePage({super.key});

  @override
  State<AddProducePage> createState() => _AddProducePageState();
}

class _AddProducePageState extends State<AddProducePage> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _fetchingPrice = false;
  Map<String, dynamic>? _priceData;
  Map<String, dynamic>? _marketPrices;

  double? _latitude;
  double? _longitude;
  String _selectedType = 'vegetable';
  String _selectedLanguage = 'en'; // Default language

  final supabase = Supabase.instance.client;
  
  // Add bucket name constant
  static const String bucketName = 'produce-images';

  // Translation map for multiple languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'addProduce.title': 'Add Produce',
      'addProduce.cropName': 'Crop Name',
      'addProduce.cropNamePlaceholder': 'Enter crop name',
      'addProduce.getPrice': 'Get Price',
      'addProduce.yourPrice': 'Your Price (₹/kg)',
      'addProduce.yourPricePlaceholder': 'Enter price per kg',
      'addProduce.quantity': 'Quantity (kg)',
      'addProduce.quantityPlaceholder': 'Enter quantity',
      'addProduce.type': 'Type',
      'addProduce.vegetable':'Vegetable',
      'addProduce.fruit':'Fruit',
      'addProduce.description': 'Description',
      'addProduce.descriptionPlaceholder': 'Enter crop description (minimum 10 words)',
      'addProduce.imagePickerText': 'Tap to upload crop image',
      'addProduce.submitText': 'Submit Produce',
      'addProduce.marketPricesFor': 'Market Prices for',
      'addProduce.minPrice': 'Min Price',
      'addProduce.medianPrice': 'Median Price',
      'addProduce.maxPrice': 'Max Price',
      'addProduce.suggestedPrice': '💡 Suggested Price',
      'addProduce.viewDetailedPrices': 'View Detailed Prices',
      'addProduce.selectRecommendedPrice': 'Select Recommended Price',
      'addProduce.recommended': 'Recommended',
      'addProduce.marketPrices': 'Market Prices',
      'addProduce.close': 'Close',
      'addProduce.pricePerKg': '/kg',
      'addProduce.validation.cropNameRequired': 'Please enter crop name',
      'addProduce.validation.priceRequired': 'Please enter price per kg',
      'addProduce.validation.quantityRequired': 'Please enter quantity',
      'addProduce.validation.imageRequired': 'Please select an image',
      'addProduce.validation.descriptionRequired': 'Please enter description (minimum 10 words)',
      'addProduce.success.message': 'Produce added successfully ✅',
      'addProduce.error.locationMessage': 'Waiting for location... Please retry.',
      'addProduce.error.locationPermissionDenied': 'Location permission denied',
      'addProduce.error.locationPermanentlyDenied': 'Location permanently denied',
      'addProduce.error.enableLocationServices': 'Please enable location services',
      'addProduce.error.priceFetchFailed': 'Price fetch failed',
      'addProduce.error.uploadFailed': 'Upload failed',
      'common.pleaseEnter': 'Please enter',
      'common.pleaseSelect': 'Please select',
    },
    'kn': {
      'addProduce.title': 'ಉತ್ಪನ್ನವನ್ನು ಸೇರಿಸಿ',
      'addProduce.cropName': 'ಬೆಳೆಯ ಹೆಸರು',
      'addProduce.cropNamePlaceholder': 'ಬೆಳೆಯ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
      'addProduce.getPrice': 'ಬೆಲೆ ಪಡೆಯಿರಿ',
      'addProduce.yourPrice': 'ನಿಮ್ಮ ಬೆಲೆ (₹/ಕೆಜಿ)',
      'addProduce.yourPricePlaceholder': 'ಪ್ರತಿ ಕೆಜಿ ಬೆಲೆಯನ್ನು ನಮೂದಿಸಿ',
      'addProduce.quantity': 'ಪ್ರಮಾಣ (ಕೆಜಿ)',
      'addProduce.quantityPlaceholder': 'ಪ್ರಮಾಣವನ್ನು ನಮೂದಿಸಿ',
      'addProduce.type': 'ಪ್ರಕಾರ',
      'addProduce.description': 'ವಿವರಣೆ',
      'addProduce.descriptionPlaceholder': 'ಬೆಳೆಯ ವಿವರಣೆಯನ್ನು ನಮೂದಿಸಿ (ಕನಿಷ್ಠ 10 ಪದಗಳು)',
      'addProduce.imagePickerText': 'ಬೆಳೆಯ ಚಿತ್ರವನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ',
      'addProduce.submitText': 'ಉತ್ಪನ್ನವನ್ನು ಸಲ್ಲಿಸಿ',
      'addProduce.marketPricesFor': 'ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು',
      'addProduce.minPrice': 'ಕನಿಷ್ಠ ಬೆಲೆ',
      'addProduce.medianPrice': 'ಮಧ್ಯಮ ಬೆಲೆ',
      'addProduce.maxPrice': 'ಗರಿಷ್ಠ ಬೆಲೆ',
      'addProduce.suggestedPrice': '💡 ಸೂಚಿಸಿದ ಬೆಲೆ',
      'addProduce.viewDetailedPrices': 'ವಿವರವಾದ ಬೆಲೆಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
      'addProduce.selectRecommendedPrice': 'ಶಿಫಾರಸಿದ ಬೆಲೆಯನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
      'addProduce.recommended': 'ಶಿಫಾರಸ್ ಮಾಡಲಾಗಿದೆ',
      'addProduce.marketPrices': 'ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು',
      'addProduce.close': 'ಮುಚ್ಚಿ',
      'addProduce.pricePerKg': '/ಕೆಜಿ',
      'addProduce.validation.cropNameRequired': 'ದಯವಿಟ್ಟು ಬೆಳೆಯ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
      'addProduce.validation.priceRequired': 'ದಯವಿಟ್ಟು ಪ್ರತಿ ಕೆಜಿ ಬೆಲೆಯನ್ನು ನಮೂದಿಸಿ',
      'addProduce.validation.quantityRequired': 'ದಯವಿಟ್ಟು ಪ್ರಮಾಣವನ್ನು ನಮೂದಿಸಿ',
      'addProduce.validation.imageRequired': 'ದಯವಿಟ್ಟು ಚಿತ್ರವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
      'addProduce.validation.descriptionRequired': 'ದಯವಿಟ್ಟು ವಿವರಣೆಯನ್ನು ನಮೂದಿಸಿ (ಕನಿಷ್ಠ 10 ಪದಗಳು)',
      'addProduce.success.message': 'ಉತ್ಪನ್ನವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಸೇರಿಸಲಾಗಿದೆ ✅',
      'addProduce.error.locationMessage': 'ಸ್ಥಳವನ್ನು ಕಾಯುತ್ತಿದ್ದೇವೆ... ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'addProduce.error.locationPermissionDenied': 'ಸ್ಥಳ ಅನುಮತಿ ನಿರಾಕರಿಸಲಾಗಿದೆ',
      'addProduce.error.locationPermanentlyDenied': 'ಸ್ಥಳ ಶಾಶ್ವತವಾಗಿ ನಿರಾಕರಿಸಲಾಗಿದೆ',
      'addProduce.error.enableLocationServices': 'ದಯವಿಟ್ಟು ಸ್ಥಳ ಸೇವೆಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ',
      'addProduce.error.priceFetchFailed': 'ಬೆಲೆ ಪಡೆಯುವಲ್ಲಿ ವಿಫಲವಾಗಿದೆ',
      'addProduce.error.uploadFailed': 'ಅಪ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ',
      'common.pleaseEnter': 'ದಯವಿಟ್ಟು ನಮೂದಿಸಿ',
      'common.pleaseSelect': 'ದಯವಿಟ್ಟು ಆಯ್ಕೆ ಮಾಡಿ',
    },
    'hi': {
      'addProduce.title': 'उत्पाद जोड़ें',
      'addProduce.cropName': 'फसल का नाम',
      'addProduce.cropNamePlaceholder': 'फसल का नाम दर्ज करें',
      'addProduce.getPrice': 'मूल्य प्राप्त करें',
      'addProduce.yourPrice': 'आपका मूल्य (₹/किग्रा)',
      'addProduce.yourPricePlaceholder': 'प्रति किलोग्राम मूल्य दर्ज करें',
      'addProduce.quantity': 'मात्रा (किग्रा)',
      'addProduce.quantityPlaceholder': 'मात्रा दर्ज करें',
      'addProduce.type': 'प्रकार',
      'addProduce.description': 'विवरण',
      'addProduce.descriptionPlaceholder': 'फसल का विवरण दर्ज करें (न्यूनतम 10 शब्द)',
      'addProduce.vegetable':'सब्ज़ी',
      'addProduce.fruit':'फल',
      'addProduce.imagePickerText': 'फसल की छवि अपलोड करने के लिए टैप करें',
      'addProduce.submitText': 'उत्पाद जमा करें',
      'addProduce.marketPricesFor': 'के लिए बाजार मूल्य',
      'addProduce.minPrice': 'न्यूनतम मूल्य',
      'addProduce.medianPrice': 'मध्य मूल्य',
      'addProduce.maxPrice': 'अधिकतम मूल्य',
      'addProduce.suggestedPrice': '💡 सुझाया गया मूल्य',
      'addProduce.viewDetailedPrices': 'विस्तृत मूल्य देखें',
      'addProduce.selectRecommendedPrice': 'अनुशंसित मूल्य चुनें',
      'addProduce.recommended': 'अनुशंसित',
      'addProduce.marketPrices': 'बाजार मूल्य',
      'addProduce.close': 'बंद करें',
      'addProduce.pricePerKg': '/किग्रा',
      'addProduce.validation.cropNameRequired': 'कृपया फसल का नाम दर्ज करें',
      'addProduce.validation.priceRequired': 'कृपया प्रति किलोग्राम मूल्य दर्ज करें',
      'addProduce.validation.quantityRequired': 'कृपया मात्रा दर्ज करें',
      'addProduce.validation.imageRequired': 'कृपया छवि चुनें',
      'addProduce.validation.descriptionRequired': 'कृपया विवरण दर्ज करें (न्यूनतम 10 शब्द)',
      'addProduce.success.message': 'उत्पाद सफलतापूर्वक जोड़ा गया ✅',
      'addProduce.error.locationMessage': 'स्थान की प्रतीक्षा की जा रही है... कृपया पुन: प्रयास करें.',
      'addProduce.error.locationPermissionDenied': 'स्थान अनुमति अस्वीकृत',
      'addProduce.error.locationPermanentlyDenied': 'स्थान स्थायी रूप से अस्वीकृत',
      'addProduce.error.enableLocationServices': 'कृपया स्थान सेवाएं सक्षम करें',
      'addProduce.error.priceFetchFailed': 'मूल्य प्राप्त करना विफल',
      'addProduce.error.uploadFailed': 'अपलोड विफल',
      'common.pleaseEnter': 'कृपया दर्ज करें',
      'common.pleaseSelect': 'कृपया चुनें',
    },
    'ta': {
      'addProduce.title': 'தயாரிப்பைச் சேர்க்கவும்',
      'addProduce.cropName': 'பயிர் பெயர்',
      'addProduce.cropNamePlaceholder': 'பயிர் பெயரை உள்ளிடவும்',
      'addProduce.getPrice': 'விலையைப் பெறுங்கள்',
      'addProduce.yourPrice': 'உங்கள் விலை (₹/கிகி)',
      'addProduce.yourPricePlaceholder': 'ஒரு கிலோவுக்கு விலையை உள்ளிடவும்',
      'addProduce.quantity': 'அளவு (கிகி)',
      'addProduce.quantityPlaceholder': 'அளவை உள்ளிடவும்',
      'addProduce.type': 'வகை',
      'addProduce.description': 'விளக்கம்',
      'addProduce.descriptionPlaceholder': 'பயிர் விளக்கத்தை உள்ளிடவும் (குறைந்தது 10 சொற்கள்)',
      'addProduce.vegetable':'காய்கறி',
      'addProduce.fruit':'பழம்',
      'addProduce.imagePickerText': 'பயிர் படத்தைப் பதிவேற்ற தட்டவும்',
      'addProduce.submitText': 'தயாரிப்பைச் சமர்ப்பிக்கவும்',
      'addProduce.marketPricesFor': 'க்கான சந்தை விலைகள்',
      'addProduce.minPrice': 'குறைந்த விலை',
      'addProduce.medianPrice': 'இடைத்த விலை',
      'addProduce.maxPrice': 'அதிகபட்ச விலை',
      'addProduce.suggestedPrice': '💡 பரிந்துரைக்கப்பட்ட விலை',
      'addProduce.viewDetailedPrices': 'விரிவான விலைகளைக் காண்க',
      'addProduce.selectRecommendedPrice': 'பரிந்துரைக்கப்பட்ட விலையைத் தேர்ந்தெடுக்கவும்',
      'addProduce.recommended': 'பரிந்துரைக்கப்பட்டது',
      'addProduce.marketPrices': 'சந்தை விலைகள்',
      'addProduce.close': 'மூடுக',
      'addProduce.pricePerKg': '/கிகி',
      'addProduce.validation.cropNameRequired': 'தயவுசெய்து பயிர் பெயரை உள்ளிடவும்',
      'addProduce.validation.priceRequired': 'தயவுசெய்து ஒரு கிலோவுக்கு விலையை உள்ளிடவும்',
      'addProduce.validation.quantityRequired': 'தயவுசெய்து அளவை உள்ளிடவும்',
      'addProduce.validation.imageRequired': 'தயவுசெய்து படத்தைத் தேர்ந்தெடுக்கவும்',
      'addProduce.validation.descriptionRequired': 'தயவுசெய்து விளக்கத்தை உள்ளிடவும் (குறைந்தது 10 சொற்கள்)',
      'addProduce.success.message': 'தயாரிப்பு வெற்றிகரமாகச் சேர்க்கப்பட்டது ✅',
      'addProduce.error.locationMessage': 'இருப்பிடத்தைக் காத்திருக்கிறது... தயவுசெய்து மீண்டும் முயற்சிக்கவும்.',
      'addProduce.error.locationPermissionDenied': 'இருப்பிட அனுமதி மறுக்கப்பட்டது',
      'addProduce.error.locationPermanentlyDenied': 'இருப்பிடம் நிரந்தரமாக மறுக்கப்பட்டது',
      'addProduce.error.enableLocationServices': 'தயவுசெய்து இருப்பிட சேவைகளை இயக்கவும்',
      'addProduce.error.priceFetchFailed': 'விலை பெறுவதில் தோல்வி',
      'addProduce.error.uploadFailed': 'பதிவேற்றம் தோல்வியடைந்தது',
      'common.pleaseEnter': 'தயவுசெய்து உள்ளிடவும்',
      'common.pleaseSelect': 'தயவுசெய்து தேர்ந்தெடுக்கவும்',
    },
    'te': {
      'addProduce.title': 'ఉత్పత్తిని జోడించండి',
      'addProduce.cropName': 'పంట పేరు',
      'addProduce.cropNamePlaceholder': 'పంట పేరును నమోదు చేయండి',
      'addProduce.getPrice': 'ధర పొందండి',
      'addProduce.yourPrice': 'మీ ధర (₹/కిలో)',
      'addProduce.yourPricePlaceholder': 'ప్రతి కిలోకు ధరను నమోదు చేయండి',
      'addProduce.quantity': 'పరిమాణం (కిలోలు)',
      'addProduce.quantityPlaceholder': 'పరిమాణాన్ని నమోదు చేయండి',
      'addProduce.type': 'రకం',
      'addProduce.description': 'వివరణ',
      'addProduce.descriptionPlaceholder': 'పంట వివరణను నమోదు చేయండి (కనీసి 10 పదాలు)',
      'addProduce.vegetable':'కూరగాయ', 
      'addProduce.fruit':'పండు',
      'addProduce.imagePickerText': 'పంట చిత్రాన్ని అప్‌లోడ్ చేయడానికి ట్యాప్ చేయండి',
      'addProduce.submitText': 'ఉత్పత్తిని సమర్పించండి',
      'addProduce.marketPricesFor': 'కోసం మార్కెట్ ధరలు',
      'addProduce.minPrice': 'కనిష్ట ధర',
      'addProduce.medianPrice': 'మధ్య ధర',
      'addProduce.maxPrice': 'గరిష్ట ధర',
      'addProduce.suggestedPrice': '💡 సూచించిన ధర',
      'addProduce.viewDetailedPrices': 'వివరాల ధరలను వీక్షించండి',
      'addProduce.selectRecommendedPrice': 'సిఫార్స్ చేసిన ధరను ఎంచుకోండి',
      'addProduce.recommended': 'సిఫార్స్ చేయబడింది',
      'addProduce.marketPrices': 'మార్కెట్ ధరలు',
      'addProduce.close': 'మూసివేయి',
      'addProduce.pricePerKg': '/కిలో',
      'addProduce.validation.cropNameRequired': 'దయచేసి పంట పేరును నమోదు చేయండి',
      'addProduce.validation.priceRequired': 'దయచేసి ప్రతి కిలోకు ధరను నమోదు చేయండి',
      'addProduce.validation.quantityRequired': 'దయచేసి పరిమాణాన్ని నమోదు చేయండి',
      'addProduce.validation.imageRequired': 'దయచేసి చిత్రాన్ని ఎంచుకోండి',
      'addProduce.validation.descriptionRequired': 'దయచేసి వివరణను నమోదు చేయండి (కనీసి 10 పదాలు)',
      'addProduce.success.message': 'ఉత్పత్తి విజయవంతంగా జోడించబడింది ✅',
      'addProduce.error.locationMessage': 'స్థానం కోసం వేచి ఉన్నాము... దయచేసి మళ్ళీ ప్రయత్నించండి.',
      'addProduce.error.locationPermissionDenied': 'స్థానం అనుమతి తిరస్కరించబడింది',
      'addProduce.error.locationPermanentlyDenied': 'స్థానం శాశ్వతంగా తిరస్కరించబడింది',
      'addProduce.error.enableLocationServices': 'దయచేసి స్థాన సేవలను ప్రారంభించండి',
      'addProduce.error.priceFetchFailed': 'ధర పొందడం విఫలమైంది',
      'addProduce.error.uploadFailed': 'అప్‌లోడ్ విఫలమైంది',
      'common.pleaseEnter': 'దయచేసి నమోదు చేయండి',
      'common.pleaseSelect': 'దయచేసి ఎంచుకోండి',
    },
  };

  // Helper method to get translation based on current language
  String t(String key) {
    return translations[_selectedLanguage]?[key] ?? translations['en']?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _getUserLocation();
  }

  @override
  void dispose() {
    _cropController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'en';
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('addProduce.error.enableLocationServices'))),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('addProduce.error.locationPermissionDenied'))),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('addProduce.error.locationPermanentlyDenied'))),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _fetchPriceData(String cropName) async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('addProduce.error.locationMessage'))),
      );
      await _getUserLocation();
      return;
    }

    setState(() => _fetchingPrice = true);
    try {
      final baseUrl = dotenv.env['CROP_SUGGESTIONS_LINK'];
      final url =
          '$baseUrl/crop-prices?lat=$_latitude&lon=$_longitude&crop=$cropName';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Failed to fetch price');

      final data = jsonDecode(response.body);
      final analysis = data['analysis'];

      setState(() {
        _priceData = {
          'min': analysis['min_price'],
          'median': analysis['median_price'],
          'max': analysis['max_price'],
          'suggested': (analysis['median_price'] ?? 0) + 5
        };
        _marketPrices = data;
        _priceController.text = _priceData!['suggested'].toStringAsFixed(2);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('addProduce.error.priceFetchFailed')}: $e')),
      );
    } finally {
      setState(() => _fetchingPrice = false);
    }
  }

  Future<String?> _uploadImage(String fileName) async {
    try {
      // Use the bucket name constant here
      final filePath = '$bucketName/$fileName';
      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            _imageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );
      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }

  // Helper function to validate description word count
  bool _validateDescription(String description) {
    if (description.trim().isEmpty) return false;
    final words = description.trim().split(RegExp(r'\s+'));
    return words.length >= 10;
  }

  Future<void> _submitProduce() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('addProduce.validation.imageRequired'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get the current user from Supabase auth
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final imageUrl = await _uploadImage('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Align with database schema
      await supabase.from('produce').insert({
        'farmer_id': user.id,
        'crop_name': _cropController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'price_per_kg': double.parse(_priceController.text.trim()),
        'image_url': imageUrl,
        'type': _selectedType,
        'status': 'in_stock',
        'description': _descriptionController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('addProduce.success.message'))),
      );

      _formKey.currentState!.reset();
      setState(() {
        _imageBytes = null;
        _priceData = null;
        _marketPrices = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${t('addProduce.error.uploadFailed')}: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPriceModal() {
    if (_priceData == null || _marketPrices == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(
                  '${t('addProduce.marketPricesFor')} ${_cropController.text}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Price Analysis Cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('addProduce.selectRecommendedPrice'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildPriceCard(
                                  title: t('addProduce.minPrice'),
                                  price: _priceData!['min'],
                                  onTap: () {
                                    _priceController.text = _priceData!['min'].toString();
                                    Navigator.pop(context);
                                  },
                                ),
                                _buildPriceCard(
                                  title: t('addProduce.medianPrice'),
                                  price: _priceData!['median'],
                                  isRecommended: true,
                                  onTap: () {
                                    _priceController.text = _priceData!['median'].toString();
                                    Navigator.pop(context);
                                  },
                                ),
                                _buildPriceCard(
                                  title: t('addProduce.maxPrice'),
                                  price: _priceData!['max'],
                                  onTap: () {
                                    _priceController.text = _priceData!['max'].toString();
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Market Prices
                      Text(
                        t('addProduce.marketPrices'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          shrinkWrap: true,
                          itemCount: _marketPrices?['top5']?.length ?? 0,
                          itemBuilder: (context, index) {
                            final market = _marketPrices!['top5'][index];
                            return _buildMarketCard(
                              marketName: '${market['Market']}, ${market['District']}',
                              date: market['Arrival_Date'],
                              price: market['Modal_Price_num'],
                              onTap: () {
                                _priceController.text = market['Modal_Price_num'].toString();
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: Text(t('addProduce.close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard({
    required String title,
    required double price,
    bool isRecommended = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRecommended ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRecommended ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: isRecommended ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${price.toStringAsFixed(2)}${t('addProduce.pricePerKg')}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            if (isRecommended)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8E6C9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t('addProduce.recommended'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketCard({
    required String marketName,
    required String date,
    required double price,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marketName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${price.toStringAsFixed(2)}${t('addProduce.pricePerKg')}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('addProduce.title')),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Crop name + Fetch button
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cropController,
                      decoration: InputDecoration(
                        labelText: t('addProduce.cropName'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: t('addProduce.cropNamePlaceholder'),
                      ),
                      validator: (v) => v!.isEmpty ? t('addProduce.validation.cropNameRequired') : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _fetchingPrice
                      ? const SizedBox(
                          width: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            if (_cropController.text.isNotEmpty) {
                              _fetchPriceData(_cropController.text.trim());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(t('addProduce.getPrice')),
                        ),
                ],
              ),
              const SizedBox(height: 12),

              // Display prices
              if (_priceData != null)
                Card(
                  color: const Color(0xFFE8F5E9),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFC8E6C9)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t('addProduce.marketPricesFor')} ${_cropController.text}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${t('addProduce.minPrice')}: ₹${_priceData!['min']}${t('addProduce.pricePerKg')}'),
                            Text('${t('addProduce.medianPrice')}: ₹${_priceData!['median']}${t('addProduce.pricePerKg')}'),
                            Text('${t('addProduce.maxPrice')}: ₹${_priceData!['max']}${t('addProduce.pricePerKg')}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${t('addProduce.suggestedPrice')}: ₹${_priceData!['suggested']}${t('addProduce.pricePerKg')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _showPriceModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: Text(t('addProduce.viewDetailedPrices')),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Price field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: t('addProduce.yourPrice'),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: t('addProduce.yourPricePlaceholder'),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? t('addProduce.validation.priceRequired') : null,
              ),
              const SizedBox(height: 12),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: t('addProduce.quantity'),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: t('addProduce.quantityPlaceholder'),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? t('addProduce.validation.quantityRequired') : null,
              ),
              const SizedBox(height: 12),

              // Type selection
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: t('addProduce.type'),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: [
                  DropdownMenuItem(value: 'vegetable', child: Text(t('addProduce.vegetable') ?? 'Vegetable')),
                  DropdownMenuItem(value: 'fruit', child: Text(t('addProduce.fruit') ?? 'Fruit')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                validator: (v) => v == null ? t('common.pleaseSelect') : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t('addProduce.description'),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: t('addProduce.descriptionPlaceholder'),
                ),
                validator: (v) {
                  if (v!.isEmpty) {
                    return t('addProduce.validation.descriptionRequired');
                  }
                  if (!_validateDescription(v)) {
                    return t('addProduce.validation.descriptionRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: _imageBytes != null
                      ? Stack(
                          children: [
                            Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageBytes = null),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(child: Text(t('addProduce.imagePickerText'))),
                ),
              ),
              const SizedBox(height: 20),

              // Submit
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _submitProduce,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(t('addProduce.submitText')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BC34A),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}