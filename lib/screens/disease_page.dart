import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mime/mime.dart' as mime;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

class DiseasePage extends StatefulWidget {
  const DiseasePage({super.key});

  @override
  State<DiseasePage> createState() => _DiseasePageState();
}

enum ProcessingStep {
  idle,
  verifying,
  predicting,
  gettingSuggestions,
  generatingPdf,
}

class _DiseasePageState extends State<DiseasePage> {
  // State variables
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageType;
  ProcessingStep _currentStep = ProcessingStep.idle;
  String _disease = '';
  double _confidence = 0.0;
  String _suggestions = '';
  String? _suggestionsEnglish; // Added for English suggestions
  String _verificationMessage = '';
  String _error = '';
  bool _isHealthy = false;
  bool _languageLoaded = false;
  bool _apiInitialized = false;
  String _modelInfo = '';
  int _currentModelIndex = 0;
  int _retryCount = 0;
  String _currentLanguage = 'en'; // Default language

  // API endpoints
  String _geminiApiKey = '';
  String _diseasePredictionLink = '';
  String _geminiApiEndpoint = '';

  // Available models
  final List<Map<String, String>> _allModels = [
    {'name': 'gemini-2.5-flash-lite', 'api': 'v1beta'},
    {'name': 'gemini-2.5-pro', 'api': 'v1beta'},
    {'name': 'gemini-1.5-pro', 'api': 'v1beta'},
    {'name': 'gemini-1.5-flash', 'api': 'v1beta'},
    {'name': 'gemini-pro', 'api': 'v1beta'},
    {'name': 'gemini-pro', 'api': 'v1'},
  ];

  // Language mapping
  final Map<String, String> _languageMap = {
    'en': 'English',
    'hi': 'Hindi',
    'kn': 'Kannada',
    'ta': 'Tamil',
    'te': 'Telugu',
  };

  // Translation map for multiple languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'disease.title': 'Crop Disease Detection',
      'disease.subtitle': 'Upload an image of a plant leaf to detect diseases',
      'disease.capture': 'Capture',
      'disease.gallery': 'Gallery',
      'disease.analyze': 'Analyze',
      'disease.diagnosis': 'Diagnosis',
      'disease.healthyLeaf': 'Healthy Leaf',
      'disease.healthyMessage': 'The leaf appears to be healthy with no visible signs of disease.',
      'disease.confidence': 'Confidence',
      'disease.treatmentSuggestions': 'Treatment Suggestions',
      'disease.professionalAdvisory': 'Professional Advisory',
      'disease.advisoryText': 'This is an AI-generated recommendation. Please consult with a local agricultural expert for proper diagnosis and treatment.',
      'disease.downloadReport': 'Download Report as PDF',
      'disease.processing': 'Processing...',
      'disease.noImageSelected': 'No Image Selected',
      'disease.pleaseSelectImage': 'Please select an image to analyze',
      'disease.apiInitializing': 'Initializing app...',
      'disease.retry': 'Retry',
      'disease.tryDifferentModel': 'Try Different Model',
      'disease.modelSwitched': 'Model Switched',
      'disease.modelSwitchedSuccess': 'Successfully switched to',
      'disease.pleaseTryAgain': 'Please try analyzing your image again.',
      'disease.verificationFailed': 'Verification failed',
      'disease.notALeaf': 'Not a valid leaf image',
      'disease.leafVerified': 'Leaf verified with disease symptoms',
      'disease.leafHealthyVerified': 'Healthy leaf verified',
      'disease.prevention': 'Prevention',
      'disease.treatment': 'Treatment',
      'disease.medications': 'Medications',
      'disease.generalCare': 'General Care',
      'disease.pdfDownloaded': 'PDF downloaded successfully',
      'disease.pdfSaved': 'PDF saved to',
      'disease.pdfGenerateFailed': 'Failed to generate PDF',
      'disease.imageSelectionFailed': 'Image Selection Failed',
      'disease.cameraPermission': 'Camera permission is required to take photos. Please grant permission in settings.',
      'disease.storagePermission': 'Storage permission is required to select images. Please grant permission in settings.',
      'disease.failedSelectImage': 'Failed to select image. Please try again.',
      'disease.apiNotInitialized': 'API is still initializing. Please try again in a moment.',
      'disease.apiKeyMissing': 'GEMINI_API_KEY is missing. Check your .env file',
      'disease.diseaseLinkMissing': 'DISEASE_LINK is missing. Check your .env file',
      'disease.apiInitFailed': 'Failed to initialize API',
      'disease.verificationError': 'Verification error',
      'disease.predictionError': 'Disease prediction failed',
      'disease.suggestionsError': 'Treatment suggestions error',
      'disease.modelOverloaded': 'The AI model is currently experiencing high demand. Please try again later.',
      'disease.serviceUnavailable': 'The service is temporarily unavailable. Please try again later.',
      'disease.internalError': 'The service encountered an internal error. Please try again later.',
      'disease.tooManyRequests': 'Too many requests. Please wait a moment before trying again.',
      'disease.switchModelFailed': 'Failed to switch models',
      'disease.reportTitle': 'Crop Disease Diagnosis Report',
    },
    'kn': {
      'disease.title': 'ಬೆಳೆ ರೋಗ ಪತ್ತೆ',
      'disease.subtitle': 'ರೋಗಗಳನ್ನು ಪತ್ತೆಹಚ್ಚಲು ಸಸ್ಯೆ ಎಲೆಯ ಚಿತ್ರವನ್ನು ಅಪ್ಲೋಡ್ ಮಾಡಿ',
      'disease.capture': 'ಸೆರೆದುಕೊಳ್ಳಿ',
      'disease.gallery': 'ಗ್ಯಾಲರಿ',
      'disease.analyze': 'ವಿಶ್ಲೇಷಿಸಿ',
      'disease.diagnosis': 'ರೋಗನಿರ್ಣಯ',
      'disease.healthyLeaf': 'ಆರೋಗ್ಯಕರ ಎಲೆ',
      'disease.healthyMessage': 'ಎಲೆಯು ರೋಗದ ಯಾವುದೇ ಲಕ್ಷಣಗಳಿಲ್ಲದೆ ಆರೋಗ್ಯಕರವಾಗಿ ಕಾಣುತ್ತದೆ.',
      'disease.confidence': 'ವಿಶ್ವಾಸ',
      'disease.treatmentSuggestions': 'ಚಿಕಿತ್ಸೆ ಸಲಹೆಗಳು',
      'disease.professionalAdvisory': 'ವೃತ್ತಿಪರ ಸಲಹೆ',
      'disease.advisoryText': 'ಇದು AI ಉತ್ಪಾದಿಸಿದ ಶಿಫಾರಸು. ಸರಿಯಾದ ರೋಗನಿರ್ಣಯ ಮತ್ತು ಚಿಕಿತ್ಸೆಗಾಗಿ ದಯವಿಟ್ಟು ಸ್ಥಳೀಯ ಕೃಷಿ ತಜ್ಞರನ್ನು ಸಂಪರ್ಕಿಸಿ.',
      'disease.downloadReport': 'PDF ವರದಿಯನ್ನು ಡೌನ್ಲೋಡ್ ಮಾಡಿ',
      'disease.processing': 'ಪ್ರಕ್ರಿಯೆ...',
      'disease.noImageSelected': 'ಯಾವುದೇ ಚಿತ್ರ ಆಯ್ಕೆ ಮಾಡಿಲ್ಲ',
      'disease.pleaseSelectImage': 'ವಿಶ್ಲೇಷಿಸಲು ದಯವಿಟ್ಟು ಚಿತ್ರವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
      'disease.apiInitializing': 'ಅಪ್ಲಿಕೇಶನ್ ಆರಂಭಿಸಲಾಗುತ್ತಿದೆ...',
      'disease.retry': 'ಮರುಪ್ರಯತ್ನಿಸಿ',
      'disease.tryDifferentModel': 'ವಿಭಿನ್ನ ಮಾದರಿಯನ್ನು ಪ್ರಯತ್ನಿಸಿ',
      'disease.modelSwitched': 'ಮಾದರಿ ಬದಲಾಯಿಸಲಾಗಿದೆ',
      'disease.modelSwitchedSuccess': 'ಯಶಸ್ವಿಯಾಗಿ ಬದಲಾಯಿಸಲಾಗಿದೆ',
      'disease.pleaseTryAgain': 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಚಿತ್ರವನ್ನು ಮತ್ತೆ ವಿಶ್ಲೇಷಿಸಲು ಪ್ರಯತ್ನಿಸಿ.',
      'disease.verificationFailed': 'ಪರಿಶೀಲನೆ ವಿಫಲವಾಗಿದೆ',
      'disease.notALeaf': 'ಮಾನ್ಯ ಎಲೆಯ ಚಿತ್ರವಲ್ಲ',
      'disease.leafVerified': 'ರೋಗ ಲಕ್ಷಣಗಳೊಂದಿಗೆ ಎಲೆಯನ್ನು ಪರಿಶೀಲಿಸಲಾಗಿದೆ',
      'disease.leafHealthyVerified': 'ಆರೋಗ್ಯಕರ ಎಲೆಯನ್ನು ಪರಿಶೀಲಿಸಲಾಗಿದೆ',
      'disease.prevention': 'ತಡೆಗಟ್ಟುವಿಕೆ',
      'disease.treatment': 'ಚಿಕಿತ್ಸೆ',
      'disease.medications': 'ಔಷಧಿಗಳು',
      'disease.generalCare': 'ಸಾಮಾನ್ಯ ಆರೈಕೆ',
      'disease.pdfDownloaded': 'PDF ಯಶಸ್ವಿಯಾಗಿ ಡೌನ್ಲೋಡ್ ಆಯಿತು',
      'disease.pdfSaved': 'PDF ಉಳಿಸಲಾಗಿದೆ',
      'disease.pdfGenerateFailed': 'PDF ರಚಿಸಲು ವಿಫಲವಾಯಿತು',
      'disease.imageSelectionFailed': 'ಚಿತ್ರ ಆಯ್ಕೆ ವಿಫಲವಾಯಿತು',
      'disease.cameraPermission': 'ಫೋಟೋ ತೆಗೆಯಲು ಕ್ಯಾಮೆರಾ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ. ದಯವಿಟ್ಟು ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಅನುಮತಿಯನ್ನು ನೀಡಿ.',
      'disease.storagePermission': 'ಚಿತ್ರಗಳನ್ನು ಆಯ್ಕೆ ಮಾಡಲು ಸಂಗ್ರಹಣೆ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ. ದಯವಿಟ್ಟು ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಅನುಮತಿಯನ್ನು ನೀಡಿ.',
      'disease.failedSelectImage': 'ಚಿತ್ರವನ್ನು ಆಯ್ಕೆ ಮಾಡಲು ವಿಫಲವಾಯಿತು. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'disease.apiNotInitialized': 'API ಇನ್ನೂ ಆರಂಭಿಸಲಾಗುತ್ತಿದೆ. ದಯವಿಟ್ಟು ಕ್ಷಣದಲ್ಲಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'disease.apiKeyMissing': 'GEMINI_API_KEY ಕಾಣೆಯಾಗಿಲ್ಲ. ನಿಮ್ಮ .env ಫೈಲ್ ಅನ್ನು ಪರಿಶೀಲಿಸಿ',
      'disease.diseaseLinkMissing': 'DISEASE_LINK ಕಾಣೆಯಾಗಿಲ್ಲ. ನಿಮ್ಮ .env ಫೈಲ್ ಅನ್ನು ಪರಿಶೀಲಿಸಿ',
      'disease.apiInitFailed': 'API ಅನ್ನು ಆರಂಭಿಸಲು ವಿಫಲವಾಯಿತು',
      'disease.verificationError': 'ಪರಿಶೀಲನೆ ದೋಷ',
      'disease.predictionError': 'ರೋಗ ಊಹೆ ವಿಫಲವಾಯಿತು',
      'disease.suggestionsError': 'ಚಿಕಿತ್ಸೆ ಸಲಹೆಗಳ ದೋಷ',
      'disease.modelOverloaded': 'AI ಮಾದರಿಯು ಪ್ರಸ್ತುತ ಹೆಚ್ಚಿನ ಬೇಡಿಕೆಯನ್ನು ಎದುರಿಸುತ್ತಿದೆ. ದಯವಿಟ್ಟು ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'disease.serviceUnavailable': 'ಸೇವೆ ತಾತ್ಕಾಲಿಕವಾಗಿ ಲಭ್ಯವಿಲ್ಲ. ದಯವಿಟ್ಟು ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'disease.internalError': 'ಸೇವೆಗೆ ಆಂತರಿಕ ದೋಷ ಎದುರಾಯಿತು. ದಯವಿಟ್ಟು ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'disease.tooManyRequests': 'ತುಂಬಾ ವಿನಂತಿಗಳು. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸುವ ಮೊದಲು ದಯವಿಟ್ಟು ಕ್ಷಣ ಕಾಯಿರಿ.',
      'disease.switchModelFailed': 'ಮಾದರಿಗಳನ್ನು ಬದಲಾಯಿಸಲು ವಿಫಲವಾಯಿತು',
      'disease.reportTitle': 'ಬೆಳೆ ರೋಗ ನಿರ್ಣಯ ವರದಿ',
    },
    'hi': {
      'disease.title': 'फसल रोग का पता लगाएं',
      'disease.subtitle': 'रोगों का पता लगाने के लिए पौधे की पत्ती का चित्र अपलोड करें',
      'disease.capture': 'कैप्चर करें',
      'disease.gallery': 'गैलरी',
      'disease.analyze': 'विश्लेषित करें',
      'disease.diagnosis': 'निदान',
      'disease.healthyLeaf': 'स्वस्थ पत्ती',
      'disease.healthyMessage': 'पत्ती बिना किसी दृश्य रोग के लक्षणों के स्वस्थ प्रतीत होती है',
      'disease.confidence': 'आत्मविश्वास',
      'disease.treatmentSuggestions': 'उपचार सुझाव',
      'disease.professionalAdvisory': 'पेशेवरी सलाह',
      'disease.advisoryText': 'यह AI द्वारा उत्पन्न सिफारिश है। उचित निदान और उपचार के लिए कृपया स्थानीय कृषि विशेषज्ञ से परामर्श करें।',
      'disease.downloadReport': 'PDF रिपोर्ट डाउनलोड करें',
      'disease.processing': 'प्रसंस्करण...',
      'disease.noImageSelected': 'कोई चित्र चयनित नहीं',
      'disease.pleaseSelectImage': 'विश्लेषण के लिए कृपया एक चित्र चुनें',
      'disease.apiInitializing': 'ऐप इनिशियलाइज़ हो रही है...',
      'disease.retry': 'पुनः प्रयास करें',
      'disease.tryDifferentModel': 'अलग मॉडल आज़माएं',
      'disease.modelSwitched': 'मॉडल बदल दिया गया',
      'disease.modelSwitchedSuccess': 'सफलतापूर्वक बदला गया',
      'disease.pleaseTryAgain': 'कृपया अपनी छवि का विश्लेषण करने के लिए पुनः प्रयास करें।',
      'disease.verificationFailed': 'सत्यापन विफल',
      'disease.notALeaf': 'एक वैध पत्ती छवि नहीं',
      'disease.leafVerified': 'रोग के लक्षणों के साथ पत्ती सत्यापित',
      'disease.leafHealthyVerified': 'स्वस्थ पत्ती सत्यापित',
      'disease.prevention': 'रोकथाम',
      'disease.treatment': 'इलाज',
      'disease.medications': 'दवाएं',
      'disease.generalCare': 'सामान्य देखभाल',
      'disease.pdfDownloaded': 'PDF सफलतापूर्वक डाउनलोड किया गया',
      'disease.pdfSaved': 'PDF सहेज़ गया',
      'disease.pdfGenerateFailed': 'PDF जनरेट करने में विफल',
      'disease.imageSelectionFailed': 'छवि चयन विफल',
      'disease.cameraPermission': 'फोटो खींचने के लिए कैमरा अनुमति आवश्यक है। कृपया सेटिंग्स में अनुमति दें।',
      'disease.storagePermission': 'छवियों का चयन करने के लिए स्टोरेज अनुमति आवश्यक है। कृपया सेटिंग्स में अनुमति दें।',
      'disease.failedSelectImage': 'छवि चुनने में विफल। कृपया पुन: प्रयास करें।',
      'disease.apiNotInitialized': 'API अभी इनिशियलाइज़ हो रहा है। कृपया क्षण भर बाद पुन: प्रयास करें।',
      'disease.apiKeyMissing': 'GEMINI_API_KEY गुम है। अपनी .env फ़ाइल जांचें',
      'disease.diseaseLinkMissing': 'DISEASE_LINK गुम है। अपनी .env फ़ाइल जांचें',
      'disease.apiInitFailed': 'API इनिशियलाइज़ करने में विफल',
      'disease.verificationError': 'सत्यापन त्रुटि',
      'disease.predictionError': 'रोग पूर्वानुमान विफल',
      'disease.suggestionsError': 'उपचार सुझाव त्रुटि',
      'disease.modelOverloaded': 'AI मॉडल वर्तमान में उच्च मांग का अनुभव कर रहा है। कृपया बाद में पुन: प्रयास करें।',
      'disease.serviceUnavailable': 'सेवा अस्थायी रूप से अनुपलब्ध है। कृपया बाद में पुन: प्रयास करें।',
      'disease.internalError': 'सेवा में आंतरिक त्रुटि आई। कृपया बाद में पुन: प्रयास करें।',
      'disease.tooManyRequests': 'बहुत सारे अनुरोध। कृपया पुन: प्रयास करने से पहले एक पल प्रतीक्षा करें।',
      'disease.switchModelFailed': 'मॉडल बदलने में विफल',
      'disease.reportTitle': 'फसल रोग निदान रिपोर्ट',
    },
    'ta': {
      'disease.title': 'பயிர் நோய் கண்டறியுங்கள்',
      'disease.subtitle': 'நோய்களைக் கண்டறிய ஒரு தாவரத்தின் இலை படத்தைப் பதிவேற்றவும்',
      'disease.capture': 'பிடிப்பு',
      'disease.gallery': 'கேலரி',
      'disease.analyze': 'பகுப்பாய்வு செய்',
      'disease.diagnosis': 'நோயறிதல்',
      'disease.healthyLeaf': 'ஆரோக்கிய இலை',
      'disease.healthyMessage': 'இலை நோயின் எந்தவொரு தெரியும் அறிகுறிகள் இல்லாமல் ஆரோக்கியதாகத் தெரிகிறது.',
      'disease.confidence': 'நம்பிக்கம்',
      'disease.treatmentSuggestions': 'சிகிச்சை பரிந்துரைகள்',
      'disease.professionalAdvisory': 'தொழில்முறை ஆலோசனை',
      'disease.advisoryText': 'இது AI உருவாக்கிய பரிந்துரை. சரியான நோயறிதல் மற்றும் சிகிச்சைக்கு உள்ளூர் வேளாண்மை நிபுணரைப் பாருங்கள்.',
      'disease.downloadReport': 'PDF அறிக்கையைப் பதிவிறக்கவும்',
      'disease.processing': 'செயலாக்குகிறது...',
      'disease.noImageSelected': 'படம் தேர்ந்தெடுக்கப்படவில்லை',
      'disease.pleaseSelectImage': 'பகுப்பாய்வு செய்ய ஒரு படத்தைத் தேர்ந்தெடுக்கவும்',
      'disease.apiInitializing': 'பயன்பாட்டைத் துவக்குகிறது...',
      'disease.retry': 'மீண்டும் முயற்சிக்க',
      'disease.tryDifferentModel': 'வேறு மாதிரியை முயற்சிக்க',
      'disease.modelSwitched': 'மாதிரி மாற்றப்பட்டது',
      'disease.modelSwitchedSuccess': 'வெற்றிகரமாக மாற்றப்பட்டது',
      'disease.pleaseTryAgain': 'உங்கள் படத்தை மீண்டும் பகுப்பாய்வு செய்ய முயற்சிக்கவும்.',
      'disease.verificationFailed': 'சரிபார்ப்பு தோல்வியடைந்தது',
      'disease.notALeaf': 'சரியான இலைப் படம் இல்லை',
      'disease.leafVerified': 'நோய் அறிகுறிகளுடன் இலை சரிபார்ப்பு செய்யப்பட்டது',
      'disease.leafHealthyVerified': 'ஆரோக்கிய இலை சரிபார்ப்பு செய்யப்பட்டது',
      'disease.prevention': 'தடுப்பு',
      'disease.treatment': 'சிகிச்சை',
      'disease.medications': 'மருந்துகள்',
      'disease.generalCare': 'பொதுவான கவனிப்பு',
      'disease.pdfDownloaded': 'PDF வெற்றிகரமாகப் பதிவிறக்கப்பட்டது',
      'disease.pdfSaved': 'PDF சேமிக்கப்பட்டது',
      'disease.pdfGenerateFailed': 'PDF உருவாக்குவதில் தோல்வி',
      'disease.imageSelectionFailed': 'படத் தேர்வு தோல்வியடைந்தது',
      'disease.cameraPermission': 'புகைப்படம் எடுப்பதற்கு கேமரா அனுமதி தேவை. தயவுசெய்து அமைப்புகளில் அனுமதியளிக்கவும்.',
      'disease.storagePermission': 'படங்களைத் தேர்ந்தெடுப்பதற்கு சேமிப்பக அனுமதி தேவை. தயவுசெய்து அமைப்புகளில் அனுமதியளிக்கவும்.',
      'disease.failedSelectImage': 'படத்தைத் தேர்ந்தெடுப்பதில் தோல்வி. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.',
      'disease.apiNotInitialized': 'API இன்னும் துவக்கப்படுகிறது. தயவுசெய்து ஒரு கணம் கழித்து மீண்டும் முயற்சிக்கவும்.',
      'disease.apiKeyMissing': 'GEMINI_API_KEY காணவில்லை. உங்களின் .env கோப்பைச் சரிபார்க்கவும்',
      'disease.diseaseLinkMissing': 'DISEASE_LINK காணவில்லை. உங்களின் .env கோப்பைச் சரிபார்க்கவும்',
      'disease.apiInitFailed': 'API துவக்குவதில் தோல்வி',
      'disease.verificationError': 'சரிபார்ப்பு பிழை',
      'disease.predictionError': 'நோய் கணிப்பில் பிழை',
      'disease.suggestionsError': 'சிகிச்சை பரிந்துரைகளில் பிழை',
      'disease.modelOverloaded': 'AI மாதிரி தற்போது அதிக தேவையை எதிர்கொள்கிறது. தயவுசெய்து பின்னால் மீண்டும் முயற்சிக்கவும்.',
      'disease.serviceUnavailable': 'சேவை தற்காலிக்கு இல்லை. தயவுசெய்து பின்னால் மீண்டும் முயற்சிக்கவும்.',
      'disease.internalError': 'சேவைக்கு உள்ளார்ந்த பிழை ஏற்பட்டது. தயவுசெய்து பின்னால் மீண்டும் முயற்சிக்கவும்.',
      'disease.tooManyRequests': 'பல கோரிக்கைகள். மீண்டும் முயற்சிப்பதற்கு முன் ஒரு கணம் காத்திருங்கள்.',
      'disease.switchModelFailed': 'மாதிரிகளை மாற்றுவதில் தோல்வி',
      'disease.reportTitle': 'பயிர் நோய் கண்டறிதல் அறிக்கை',
    },
    'te': {
      'disease.title': 'పంట రోగాల గుర్తింపు',
      'disease.subtitle': 'రోగాలను గుర్తించడానికి మొక్క ఆకువ ఆకు చిత్రాన్ని అప్‌లోడ్ చేయండి',
      'disease.capture': 'సెరెదుకోండి',
      'disease.gallery': 'గ్యాలరీ',
      'disease.analyze': 'విశ్లేషించండి',
      'disease.diagnosis': 'రోగ నిర్ధారణ',
      'disease.healthyLeaf': 'ఆరోగ్యకరమైన ఆకు',
      'disease.healthyMessage': 'ఆకు రోగపూరిత లక్షణాలు లేకుండా ఆరోగ్యకరంగా కనిపిస్తుంది.',
      'disease.confidence': 'విశ్వాసం',
      'disease.treatmentSuggestions': 'చికిత్స సూచనలు',
      'disease.professionalAdvisory': 'ప్రొఫెషనల్ సలహా',
      'disease.advisoryText': 'ఇది AI ద్వారా ఉత్పత్తి చేసిన సిఫారిసు. సరైన రోగ నిర్ధారణ మరియు చికిత్స కోసం దయచేసి స్థానిక వ్యవసాయ నిపుణుడిని సంప్రదించండి.',
      'disease.downloadReport': 'PDF నివేదికను డౌన్‌లోడ్ చేయండి',
      'disease.processing': 'ప్రాసెస్ అవుతోంది...',
      'disease.noImageSelected': 'ఎటువంటి చిత్ర ఎంచుకోలేదు',
      'disease.pleaseSelectImage': 'విశ్లేషించడానికి దయచేసి ఒక చిత్రను ఎంచుకోండి',
      'disease.apiInitializing': 'యాప్ ఇనిషియలైజ్ అవుతోంది...',
      'disease.retry': 'మళ్ళీ ప్రయత్నించండి',
      'disease.tryDifferentModel': 'వేరే మోడల్‌ను ప్రయత్నించండి',
      'disease.modelSwitched': 'మోడల్ మార్చబడింది',
      'disease.modelSwitchedSuccess': 'విజయవంతంగా మార్చబడింది',
      'disease.pleaseTryAgain': 'దయచేసి మీ చిత్రను మళ్ళీ విశ్లేషించడానికి ప్రయత్నించండి.',
      'disease.verificationFailed': 'ధృవీకరణ విఫలమైంది',
      'disease.notALeaf': 'చెల్లని ఆకు చిత్ర కాదు',
      'disease.leafVerified': 'రోగ లక్షణాలతో ఆకు ధృవీకరించబడింది',
      'disease.leafHealthyVerified': 'ఆరోగ్యకరమైన ఆకు ధృవీకరించబడింది',
      'disease.prevention': 'నివారణ',
      'disease.treatment': 'చికిత్స',
      'disease.medications': 'మందులు',
      'disease.generalCare': 'సాధారణ సంరక్షణ',
      'disease.pdfDownloaded': 'PDF విజయవంతంగా డౌన్‌లోడ్ చేయబడింది',
      'disease.pdfSaved': 'PDF సేవ్ చేయబడింది',
      'disease.pdfGenerateFailed': 'PDF జనరేట్ చేయడంలో విఫలమైంది',
      'disease.imageSelectionFailed': 'చిత్ర ఎంపిక విఫలమైంది',
      'disease.cameraPermission': 'ఫోటో తీయడానికి కెమెరా అనుమతి అవసరం. దయచేసి సెట్టింగ్‌లలో అనుమతిని ఇవ్వండి.',
      'disease.storagePermission': 'చిత్రలను ఎంచుకోవడానికి నిల్వన అనుమతి అవసరం. దయచేసి సెట్టింగ్‌లలో అనుమతిని ఇవ్వండి.',
      'disease.failedSelectImage': 'చిత్రను ఎంచుకోవడంలో విఫలమైంది. దయచేసి మళ్ళీ ప్రయత్నించండి.',
      'disease.apiNotInitialized': 'API ఇంకా ఇనిషియలైజ్ అవుతోంది. దయచేసి క్షణం తర్వాత మళ్ళీ ప్రయత్నించండి.',
      'disease.apiKeyMissing': 'GEMINI_API_KEY కనిపించలేదు. మీ .env ఫైల్‌ను తనిఖీ చేయండి',
      'disease.diseaseLinkMissing': 'DISEASE_LINK కనిపించలేదు. మీ .env ఫైల్‌ను తనిఖీ చేయండి',
      'disease.apiInitFailed': 'API ఇనిషియలైజ్ చేయడంలో విఫలమైంది',
      'disease.verificationError': 'ధృవీకరణ లోపం',
      'disease.predictionError': 'రోగ అంచనలో లోపం',
      'disease.suggestionsError': 'చికిత్స సూచనలలో లోపం',
      'disease.modelOverloaded': 'AI మోడల్ ప్రస్తుతం అధిక డిమాండ్‌ను ఎదుర్కొంటోంది. దయచేసి తర్వాత మళ్ళీ ప్రయత్నించండి.',
      'disease.serviceUnavailable': 'సేవ తాత్కాలికంగా అందుబాటులో లేదు. దయచేసి తర్వాత మళ్ళీ ప్రయత్నించండి.',
      'disease.internalError': 'సేవకు అంతర్గత లోపం ఎదురైంది. దయచేసి తర్వాత మళ్ళీ ప్రయత్నించండి.',
      'disease.tooManyRequests': 'చాలా అభ్యర్థాలు. మళ్ళీ ప్రయత్నించే ముందు దయచేసి క్షణం ఆగండి.',
      'disease.switchModelFailed': 'మోడల్‌లను మార్చడంలో విఫలమైంది',
      'disease.reportTitle': 'పంట రోగ నిర్ధారణ నివేదిక',
    },
  };

  // Helper method to get translation based on current language
  String t(String key) {
    return translations[_currentLanguage]?[key] ?? translations['en']?[key] ?? key;
  }

  // Helper method to get translation for a specific language
  String tForLanguage(String key, String languageCode) {
    return translations[languageCode]?[key] ?? translations['en']?[key] ?? key;
  }

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeApi();
    _initializeLanguage();
  }

  @override
  void dispose() {
    // Clean up resources
    _imageFile = null;
    _imageBytes = null;
    super.dispose();
  }

  // Initialize API
  Future<void> _initializeApi() async {
    try {
      _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      _diseasePredictionLink = dotenv.env['DISEASE_LINK'] ?? '';

      if (_geminiApiKey.isEmpty) {
        setState(() {
          _error = t('disease.apiKeyMissing');
          _apiInitialized = true;
        });
        return;
      }

      if (_diseasePredictionLink.isEmpty) {
        setState(() {
          _error = t('disease.diseaseLinkMissing');
          _apiInitialized = true;
        });
        return;
      }

      final result = await _checkAvailableModels();
      if (result['success']) {
        setState(() {
          _modelInfo = 'Using ${result['modelName']} (${result['apiVersion']})';
          _geminiApiEndpoint = result['endpoint'];
          _currentModelIndex = result['modelIndex'] ?? 0;
        });
      } else {
        setState(() {
          _modelInfo = 'Using fallback model: ${result['modelName']} (${result['apiVersion']})';
          _geminiApiEndpoint = result['endpoint'];
          _currentModelIndex = result['modelIndex'] ?? 0;
        });
      }

      setState(() {
        _apiInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = '${t('disease.apiInitFailed')}: ${e.toString()}';
        _apiInitialized = true;
      });
    }
  }

  // Initialize language
  Future<void> _initializeLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('selectedLanguage');
      if (savedLanguage != null && _languageMap.containsKey(savedLanguage)) {
        setState(() {
          _currentLanguage = savedLanguage;
        });
      }
    } catch (error) {
      print('Error loading language preference: $error');
    } finally {
      setState(() {
        _languageLoaded = true;
      });
    }
  }

  // Check available models
  Future<Map<String, dynamic>> _checkAvailableModels() async {
    for (int i = 0; i < _allModels.length; i++) {
      final model = _allModels[i];
      try {
        print('Trying model: ${model['name']} with API ${model['api']}');
        
        final testEndpoint = 'https://generativelanguage.googleapis.com/${model['api']}/models/${model['name']}:generateContent?key=$_geminiApiKey';
        
        final testResponse = await http.post(
          Uri.parse(testEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [{'parts': [{'text': 'Test'}]}],
            'generationConfig': {'maxOutputTokens': 1}
          }),
        ).timeout(const Duration(seconds: 10));
        
        if (testResponse.statusCode == 200) {
          print('✅ Model ${model['name']} works!');
          return {
            'success': true,
            'modelName': model['name'],
            'apiVersion': model['api'],
            'endpoint': testEndpoint,
            'modelIndex': i,
          };
        } else {
          final errorData = jsonDecode(testResponse.body);
          print('❌ Model ${model['name']} failed: ${errorData['error']?['message'] ?? testResponse.reasonPhrase}');
        }
      } catch (error) {
        print('❌ Error testing model ${model['name']}: $error');
      }
    }
    
    final fallbackModel = _allModels[0];
    print('⚠️ All models failed, using fallback: ${fallbackModel['name']}');
    final fallbackEndpoint = 'https://generativelanguage.googleapis.com/${fallbackModel['api']}/models/${fallbackModel['name']}:generateContent?key=$_geminiApiKey';
    
    return {
      'success': false,
      'modelName': fallbackModel['name'],
      'apiVersion': fallbackModel['api'],
      'endpoint': fallbackEndpoint,
      'modelIndex': 0,
    };
  }

  // Helper function for API requests with retry
  Future<http.Response> _fetchWithRetry(
    String url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 3,
    int initialDelay = 1000,
  }) async {
    int attempt = 1;
    Object? lastError;
    
    while (attempt <= maxRetries) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          return response;
        }
        
        String errorMessage = '';
        if (response.statusCode == 503) {
          errorMessage = t('disease.serviceUnavailable');
        } else if (response.statusCode == 429) {
          errorMessage = t('disease.tooManyRequests');
        } else if (response.statusCode == 500) {
          errorMessage = t('disease.internalError');
        } else {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = 'API Error: ${errorData['error']?['message'] ?? response.reasonPhrase}';
          } catch (e) {
            errorMessage = 'API Error: ${response.reasonPhrase}';
          }
        }
        
        lastError = errorMessage;
        print('Attempt $attempt/$maxRetries: $errorMessage, retrying...');
        
        if (attempt == maxRetries) {
          throw Exception(lastError);
        }
        
        final delay = initialDelay * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delay));
        
      } catch (error) {
        lastError = error;
        
        if (error.toString().contains("overloaded") || 
            error.toString().contains("Service unavailable") ||
            error.toString().contains("Too many requests") ||
            error.toString().contains("Internal server error") ||
            error.toString().contains("Network request failed") ||
            error is TimeoutException) {
          print('Attempt $attempt/$maxRetries: $error, retrying...');
          
          if (attempt == maxRetries) {
            rethrow;
          }
          
          final delay = initialDelay * (1 << (attempt - 1));
          await Future.delayed(Duration(milliseconds: delay));
        } else {
          rethrow;
        }
      }
      
      attempt++;
    }
    
    throw Exception(lastError);
  }

  // Try alternative model
  Future<Map<String, dynamic>> _tryAlternativeModel() async {
    final nextModelIndex = (_currentModelIndex + 1) % _allModels.length;
    final nextModel = _allModels[nextModelIndex];
    
    print('Trying alternative model: ${nextModel['name']} with API ${nextModel['api']}');
    
    final newEndpoint = 'https://generativelanguage.googleapis.com/${nextModel['api']}/models/${nextModel['name']}:generateContent?key=$_geminiApiKey';
    
    setState(() {
      _geminiApiEndpoint = newEndpoint;
      _currentModelIndex = nextModelIndex;
      _modelInfo = 'Switched to ${nextModel['name']} (${nextModel['api']})';
      _retryCount = 0;
    });
    
    return {
      'success': true,
      'modelName': nextModel['name'],
      'apiVersion': nextModel['api'],
      'modelIndex': nextModelIndex,
    };
  }

  // Handle image selection
  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (image != null) {
        _resetResults();
        
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _imageType = mime.lookupMimeType(image.name) ?? 'image/jpeg';
          });
        } else {
          setState(() {
            _imageFile = File(image.path);
            _imageType = mime.lookupMimeType(image.path) ?? 'image/jpeg';
          });
        }
        
        setState(() {
          _error = '';
        });
      }
    } catch (error) {
      print('Image selection error: $error');
      
      String errorMessage = t('disease.failedSelectImage');
      if (error.toString().contains('permission') || 
          error.toString().contains('denied') ||
          error.toString().contains('restricted')) {
        if (source == ImageSource.camera) {
          errorMessage = t('disease.cameraPermission');
        } else {
          errorMessage = t('disease.storagePermission');
        }
      }
      
      setState(() {
        _error = errorMessage;
      });
      _showErrorDialog(t('disease.imageSelectionFailed'), errorMessage);
    }
  }

  // Reset results
  void _resetResults() {
    setState(() {
      _disease = '';
      _confidence = 0.0;
      _suggestions = '';
      _suggestionsEnglish = null; // Reset English suggestions
      _verificationMessage = '';
      _error = '';
      _isHealthy = false;
      _currentStep = ProcessingStep.idle;
      _retryCount = 0;
    });
  }

  // Process image for analysis
  Future<void> _processImageForAnalysis() async {
    if (_imageFile == null && _imageBytes == null) {
      _showErrorDialog(t('disease.noImageSelected'), t('disease.pleaseSelectImage'));
      return;
    }
    
    if (!_apiInitialized) {
      setState(() {
        _error = t('disease.apiNotInitialized');
      });
      return;
    }
    
    _resetResults();
    setState(() {
      _currentStep = ProcessingStep.verifying;
      _error = '';
      _retryCount = 0;
    });
    
    try {
      final verificationResult = await _verifyPlantLeafImage();
      
      if (!verificationResult['isLeaf']) {
        setState(() {
          _currentStep = ProcessingStep.idle;
        });
        return;
      }
      
      if (verificationResult['isHealthy']) {
        setState(() {
          _isHealthy = true;
          _verificationMessage = t('disease.leafHealthyVerified');
          _currentStep = ProcessingStep.idle;
        });
        return;
      }
      
      setState(() {
        _currentStep = ProcessingStep.predicting;
      });
      final predictionData = await _getDiseasePrediction();
      
      setState(() {
        _currentStep = ProcessingStep.gettingSuggestions;
      });
      await _getTreatmentSuggestions(predictionData['prediction']);
      
      setState(() {
        _disease = predictionData['prediction'];
        _confidence = predictionData['confidence'];
        _currentStep = ProcessingStep.idle;
      });
    } catch (err) {
      print('Analysis Error: $err');
      setState(() {
        _error = err.toString() ?? t('disease.failedSelectImage');
        _verificationMessage = '';
        _currentStep = ProcessingStep.idle;
      });
    }
  }

  // Verify plant leaf image
  Future<Map<String, dynamic>> _verifyPlantLeafImage() async {
    try {
      String base64Data;
      
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        base64Data = base64Encode(bytes);
      } else if (_imageBytes != null) {
        base64Data = base64Encode(_imageBytes!);
      } else {
        throw Exception('No image data available');
      }
      
      final currentLanguage = _languageMap[_currentLanguage] ?? 'English';
      
      final prompt = {
        'contents': [
          {
            'parts': [
              {
                'text': 'Analyze this image and determine if it contains a plant leaf. '
                    'Respond in $currentLanguage. '
                    'If it does contain a plant leaf, also check if it appears healthy (no spots, discoloration, marks, or signs of disease). '
                    'Respond in one of these formats:\n'
                    '1. "LEAF_HEALTHY"\n'
                    '2. "LEAF_UNHEALTHY"\n'
                    '3. "NOT_LEAF"'
              },
              {
                'inline_data': {
                  'mime_type': _imageType ?? 'image/jpeg',
                  'data': base64Data
                }
              }
            ],
          },
        ],
      };
      
      late http.Response response;
      int modelTries = 0;
      final maxModelTries = 3;
      
      while (modelTries < maxModelTries) {
        try {
          response = await _fetchWithRetry(
            _geminiApiEndpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': prompt['contents'],
              'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 50},
            }),
            maxRetries: 2,
            initialDelay: 1000,
          );
          
          break;
        } catch (error) {
          modelTries++;
          setState(() {
            _retryCount = _retryCount + 1;
          });
          
          if (modelTries >= maxModelTries) {
            rethrow;
          }
          
          print('Current model failed, trying alternative model...');
          await _tryAlternativeModel();
        }
      }
      
      final data = jsonDecode(response.body);
      
      if (data['candidates'] == null || 
          data['candidates'][0] == null || 
          data['candidates'][0]['content'] == null || 
          data['candidates'][0]['content']['parts'] == null || 
          data['candidates'][0]['content']['parts'][0] == null) {
        throw Exception('Invalid API response');
      }
      
      final resultText = data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
      
      if (resultText == "LEAF_HEALTHY") {
        return {'isLeaf': true, 'isHealthy': true};
      } else if (resultText == "LEAF_UNHEALTHY") {
        setState(() {
          _verificationMessage = t('disease.leafVerified');
        });
        return {'isLeaf': true, 'isHealthy': false};
      } else if (resultText == "NOT_LEAF") {
        setState(() {
          _verificationMessage = t('disease.notALeaf');
        });
        return {'isLeaf': false, 'isHealthy': false};
      } else {
        setState(() {
          _verificationMessage = t('disease.verificationFailed');
        });
        return {'isLeaf': false, 'isHealthy': false};
      }
    } catch (err) {
      print('Verification error: $err');
      
      String errorMessage = err.toString();
      if (errorMessage.contains("overloaded")) {
        throw Exception(t('disease.modelOverloaded'));
      } else if (errorMessage.contains("Service unavailable") || errorMessage.contains("503")) {
        throw Exception(t('disease.serviceUnavailable'));
      } else if (errorMessage.contains("Internal server error") || errorMessage.contains("500")) {
        throw Exception(t('disease.internalError'));
      } else if (errorMessage.contains("Too many requests") || errorMessage.contains("429")) {
        throw Exception(t('disease.tooManyRequests'));
      }
      
      setState(() {
        _verificationMessage = t('disease.verificationFailed');
      });
      rethrow;
    }
  }

  // Get disease prediction
  Future<Map<String, dynamic>> _getDiseasePrediction() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(_diseasePredictionLink),
      );
      
      if (_imageFile != null) {
        final file = await http.MultipartFile.fromPath(
          'file',
          _imageFile!.path,
          contentType: MediaType.parse(_imageType ?? 'image/jpeg'),
        );
        request.files.add(file);
      } else if (_imageBytes != null) {
        final file = http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: 'plant-leaf.${_imageType?.split('/').last ?? 'jpg'}',
          contentType: MediaType.parse(_imageType ?? 'image/jpeg'),
        );
        request.files.add(file);
      }
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode != 200) {
        throw Exception('${t('disease.predictionError')}: ${response.reasonPhrase} - ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      
      if (data['prediction'] == null || data['confidence'] == null) {
        throw Exception('Invalid prediction data');
      }
      
      // Normalize confidence to be between 0 and 1
      double confidence = double.parse(data['confidence'].toString());
      if (confidence > 1.0) {
        confidence = confidence / 100.0;
      }
      
      return {
        'prediction': data['prediction'],
        'confidence': confidence,
      };
    } catch (err) {
      print('Disease prediction error: $err');
      throw Exception(t('disease.predictionError'));
    }
  }

  // Get treatment suggestions in current language and English
  Future<void> _getTreatmentSuggestions(String diseaseName) async {
    try {
      // Get suggestions in current language
      final currentSuggestions = await _getTreatmentSuggestionsForLanguage(diseaseName, _currentLanguage);
      
      // Get suggestions in English if current language is not English
      String? englishSuggestions;
      if (_currentLanguage != 'en') {
        englishSuggestions = await _getTreatmentSuggestionsForLanguage(diseaseName, 'en');
      }
      
      setState(() {
        _suggestions = currentSuggestions;
        _suggestionsEnglish = englishSuggestions;
      });
    } catch (err) {
      print('Treatment suggestions error: $err');
      setState(() {
        _suggestions = t('disease.failedSelectImage');
      });
      rethrow;
    }
  }

  // Get treatment suggestions for a specific language
  Future<String> _getTreatmentSuggestionsForLanguage(String diseaseName, String languageCode) async {
    try {
      final currentLanguage = _languageMap[languageCode] ?? 'English';
      
      final prevention = tForLanguage('disease.prevention', languageCode);
      final treatment = tForLanguage('disease.treatment', languageCode);
      final medications = tForLanguage('disease.medications', languageCode);
      final generalCare = tForLanguage('disease.generalCare', languageCode);
      
      final prompt = {
        'contents': [
          {
            'parts': [
              {
                'text': 'As an agricultural expert, provide clear and simple advice for "$diseaseName" in this format:\n'
                    '$prevention:\n'
                    'List prevention methods as plain text without any markdown formatting\n'
                    '$treatment:\n'
                    'List treatment methods as plain text without any markdown formatting\n'
                    '$medications:\n'
                    'List medications or treatments as plain text without any markdown formatting. This section is compulsory to include.\n'
                    '$generalCare:\n'
                    'List general care advice as plain text without any markdown formatting\n'
                    'Do not use asterisks (*) or any markdown formatting in your response.\n'
                    'Respond in $currentLanguage.'
              },
            ],
          },
        ],
      };
      
      late http.Response response;
      int modelTries = 0;
      final maxModelTries = 3;
      
      while (modelTries < maxModelTries) {
        try {
          response = await _fetchWithRetry(
            _geminiApiEndpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': prompt['contents'],
              'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 250},
            }),
            maxRetries: 2,
            initialDelay: 1000,
          );
          
          break;
        } catch (error) {
          modelTries++;
          setState(() {
            _retryCount = _retryCount + 1;
          });
          
          if (modelTries >= maxModelTries) {
            rethrow;
          }
          
          print('Current model failed, trying alternative model...');
          await _tryAlternativeModel();
        }
      }
      
      final data = jsonDecode(response.body);
      
      if (data['candidates'] == null || 
          data['candidates'][0] == null || 
          data['candidates'][0]['content'] == null || 
          data['candidates'][0]['content']['parts'] == null || 
          data['candidates'][0]['content']['parts'][0] == null) {
        throw Exception('Invalid API response');
      }
      
      return data['candidates'][0]['content']['parts'][0]['text'] ?? 'No suggestions available';
    } catch (err) {
      print('Treatment suggestions error: $err');
      
      String errorMessage = err.toString();
      if (errorMessage.contains("overloaded")) {
        throw Exception(t('disease.modelOverloaded'));
      } else if (errorMessage.contains("Service unavailable") || errorMessage.contains("503")) {
        throw Exception(t('disease.serviceUnavailable'));
      } else if (errorMessage.contains("Internal server error") || errorMessage.contains("500")) {
        throw Exception(t('disease.internalError'));
      } else if (errorMessage.contains("Too many requests") || errorMessage.contains("429")) {
        throw Exception(t('disease.tooManyRequests'));
      }
      
      return t('disease.failedSelectImage');
    }
  }

  // Format suggestions text
  List<Widget> _formatSuggestions(String text) {
    if (text.isEmpty) return [];
    
    String formattedText = text.replaceAll('*', '');
    
    List<String> sections = formattedText.split('\n\n');
    
    return sections.map((section) {
      if (section.trim().isEmpty) return const SizedBox.shrink();
      
      List<String> lines = section.split('\n');
      if (lines.isEmpty) return const SizedBox.shrink();
      
      String header = lines[0].trim();
      String content = lines.skip(1).join('\n').trim();
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF344e41),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Format suggestions for PDF
  List<pw.Widget> _formatSuggestionsForPdf(String text) {
    if (text.isEmpty) return [pw.SizedBox()];
    
    String formattedText = text.replaceAll('*', '');
    List<String> sections = formattedText.split('\n\n');
    List<pw.Widget> widgets = [];

    for (final section in sections) {
      if (section.trim().isEmpty) continue;
      
      List<String> lines = section.split('\n');
      if (lines.isEmpty) continue;
      
      String header = lines[0].trim();
      String content = lines.skip(1).where((line) => line.trim().isNotEmpty).join('\n').trim();
      
      if (content.isEmpty) continue;

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFe9ecef),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF495057),
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8),
              child: pw.Text(
                content,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFF333333),
                  lineSpacing: 1.3,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
      );
    }
    
    return widgets;
  }

  // Generate and save PDF in English only
  Future<void> _generateAndSavePdf() async {
    setState(() => _currentStep = ProcessingStep.generatingPdf);

    try {
      final pdf = pw.Document();

      // Get image bytes if available
      Uint8List? imageBytes;
      if (_imageFile != null) {
        imageBytes = await _imageFile!.readAsBytes();
      } else if (_imageBytes != null) {
        imageBytes = _imageBytes;
      }

      // Normalize confidence to percentage
      final confidencePercentage = _confidence * 100;

      // Always generate report in English
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return _buildPdfPageContent(
              langCode: 'en', // Force English
              imageBytes: imageBytes,
              confidencePercentage: confidencePercentage,
              context: context,
            );
          },
        ),
      );

      // Generate filename with timestamp and English indicator
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'crop_disease_report_English_$timestamp.pdf';

      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        await _savePdfForWeb(pdfBytes, fileName);
      } else {
        await _savePdfForMobile(pdfBytes, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('disease.pdfGenerateFailed')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _currentStep = ProcessingStep.idle);
    }
  }

  // Build PDF page content for the selected language
  pw.Widget _buildPdfPageContent({
    required String langCode,
    required Uint8List? imageBytes,
    required double confidencePercentage,
    required pw.Context context,
  }) {
    // Always use English for PDF content
    final languageName = 'English';
    
    final content = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with language indicator
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              tForLanguage('disease.reportTitle', 'en'), // Force English
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF3a5a40),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFe9edc9),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                languageName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF606c38),
                ),
              ),
            ),
          ],
        ),
        
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColor.fromInt(0xFFdad7cd), thickness: 1),
        pw.SizedBox(height: 20),

        // Image section
        if (imageBytes != null)
          pw.Center(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xFFa3b18a), width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(
                  pw.MemoryImage(imageBytes),
                  height: 200,
                  width: 200,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          ),
        
        if (imageBytes != null) pw.SizedBox(height: 20),

        // Diagnosis section
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFf8f9fa),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColor.fromInt(0xFFdee2e6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                tForLanguage('disease.diagnosis', 'en'), // Force English
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF3a5a40),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                _isHealthy ? tForLanguage('disease.healthyLeaf', 'en') : _disease, // Force English
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF344e41),
                ),
              ),
              if (!_isHealthy) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  '${tForLanguage('disease.confidence', 'en')}: ${confidencePercentage.toStringAsFixed(2)}%', // Force English
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColor.fromInt(0xFF606c38),
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        if (!_isHealthy && (_suggestionsEnglish ?? _suggestions).isNotEmpty) ...[
          // Treatment Suggestions section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFfff3cd),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFffeaa7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  tForLanguage('disease.treatmentSuggestions', 'en'), // Force English
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF856404),
                  ),
                ),
                pw.SizedBox(height: 10),
                ..._formatSuggestionsForPdf(_suggestionsEnglish ?? _suggestions),
              ],
            ),
          ),

          pw.SizedBox(height: 20),
        ],

        if (_isHealthy) ...[
          // Healthy leaf message
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFd1e7dd),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFbadbcc)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  tForLanguage('disease.healthyLeaf', 'en'), // Force English
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0f5132),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  tForLanguage('disease.healthyMessage', 'en'), // Force English
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColor.fromInt(0xFF0f5132),
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
        ],

        // Additional Information section
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFcfe2ff),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColor.fromInt(0xFF9ec5fe)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Additional Information',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF052c65),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Report Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFF052c65),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'AI Model: ${_allModels[_currentModelIndex]['name']}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFF052c65),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Language: $languageName',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFF052c65),
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Professional advisory section
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFf8d7da),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColor.fromInt(0xFFf1aeb5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                tForLanguage('disease.professionalAdvisory', 'en'), // Force English
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF58151c),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                tForLanguage('disease.advisoryText', 'en'), // Force English
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFF58151c),
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        // Footer
        pw.SizedBox(height: 30),
        pw.Divider(color: PdfColor.fromInt(0xFFdad7cd), thickness: 1),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount} - $languageName Version',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF6c757d),
            ),
          ),
        ),
      ],
    );

    return content;
  }

  // Retry with different model
  Future<void> _handleRetryWithDifferentModel() async {
    try {
      setState(() {
        _currentStep = ProcessingStep.idle;
        _error = '';
      });
      
      final nextModelIndex = (_currentModelIndex + 1) % _allModels.length;
      final nextModel = _allModels[nextModelIndex];
      
      print('Retrying with model: ${nextModel['name']} with API ${nextModel['api']}');
      
      final newEndpoint = 'https://generativelanguage.googleapis.com/${nextModel['api']}/models/${nextModel['name']}:generateContent?key=$_geminiApiKey';
      
      final testResponse = await http.post(
        Uri.parse(newEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': 'Test'}]}],
          'generationConfig': {'maxOutputTokens': 1}
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (testResponse.statusCode == 200) {
        setState(() {
          _geminiApiEndpoint = newEndpoint;
          _currentModelIndex = nextModelIndex;
          _modelInfo = 'Switched to ${nextModel['name']} (${nextModel['api']})';
        });
        
        _showSuccessDialog(
          t('disease.modelSwitched'),
          '${t('disease.modelSwitchedSuccess')} ${nextModel['name']}. ${t('disease.pleaseTryAgain')}',
        );
      } else {
        throw Exception('${t('disease.switchModelFailed')} ${nextModel['name']}');
      }
    } catch (error) {
      print('Error switching models: $error');
      setState(() {
        _error = '${t('disease.switchModelFailed')}: ${error.toString()}';
      });
    }
  }

  // Save PDF for web platform
  Future<void> _savePdfForWeb(Uint8List pdfBytes, String fileName) async {
    try {
      // Convert bytes to base64
      final base64 = base64Encode(pdfBytes);
      final url = 'data:application/pdf;base64,$base64';
      
      // Create a blob and trigger download using JavaScript
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
      
      // Create a temporary anchor element to trigger download
      final anchor = html.AnchorElement(href: downloadUrl)
        ..setAttribute('download', fileName)
        ..style.display = 'none'
        ..click();
      
      // Clean up
      html.Url.revokeObjectUrl(downloadUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('disease.pdfDownloaded')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('disease.pdfGenerateFailed')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save PDF for mobile platforms
  Future<void> _savePdfForMobile(Uint8List pdfBytes, String fileName) async {
    try {
      Directory? output;
      
      // Get appropriate directory based on platform
      if (Platform.isAndroid) {
        output = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        output = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms (desktop, etc.)
        output = await getApplicationDocumentsDirectory();
      }

      if (output == null) {
        throw Exception('Could not access storage directory');
      }

      // Create a file in the directory
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('disease.pdfSaved')}: ${file.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('disease.pdfGenerateFailed')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show success dialog
  void _showSuccessDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Build UI components
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF3a5a40),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Text(
            t('disease.title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('disease.subtitle'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFe6e6dc),
            ),
            textAlign: TextAlign.center,
          ),
          if (_modelInfo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _modelInfo,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFe6e6dc),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFf8d7da),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFf5c6cb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _error,
            style: const TextStyle(color: Color(0xFF721c24)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF721c24),
                  ),
                  onPressed: () => setState(() => _error = ''),
                  child: Text(t('disease.retry'), style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              if (_error.contains("overloaded") || 
                  _error.contains("Service unavailable") || 
                  _error.contains("Too many requests") ||
                  _error.contains("Internal server error"))
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6c757d),
                    ),
                    onPressed: _currentStep != ProcessingStep.idle ? null : _handleRetryWithDifferentModel,
                    child: Text(t('disease.tryDifferentModel'), style: const TextStyle(color: Colors.white)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelectionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF588157),
                disabledBackgroundColor: Colors.grey,
              ),
              onPressed: _currentStep != ProcessingStep.idle 
                  ? null 
                  : () => _handleImageSelection(ImageSource.camera),
              child: Text(t('disease.capture'), style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFa3b18a),
                disabledBackgroundColor: Colors.grey,
              ),
              onPressed: _currentStep != ProcessingStep.idle 
                  ? null 
                  : () => _handleImageSelection(ImageSource.gallery),
              child: Text(t('disease.gallery'), style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: _currentStep != ProcessingStep.idle ? null : () {
                  setState(() {
                    _imageFile = null;
                    _imageBytes = null;
                    _resetResults();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (kIsWeb) {
      if (_imageBytes == null) {
        return Container(
          width: double.infinity,
          height: 300,
          color: Colors.grey[200],
          child: const Icon(
            Icons.broken_image,
            size: 50,
            color: Colors.grey,
          ),
        );
      }
      
      return Image.memory(
        _imageBytes!,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      if (_imageFile == null) {
        return Container(
          width: double.infinity,
          height: 300,
          color: Colors.grey[200],
          child: const Icon(
            Icons.broken_image,
            size: 50,
            color: Colors.grey,
          ),
        );
      }
      
      return Image.file(
        _imageFile!,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      );
    }
  }

  Widget _buildVerificationMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        _verificationMessage,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF606c38),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    String message;
    switch (_currentStep) {
      case ProcessingStep.verifying:
        message = '${t('disease.processing')} - Verifying leaf...';
        break;
      case ProcessingStep.predicting:
        message = '${t('disease.processing')} - Predicting disease...';
        break;
      case ProcessingStep.gettingSuggestions:
        message = '${t('disease.processing')} - Getting suggestions...';
        break;
      case ProcessingStep.generatingPdf:
        message = '${t('disease.processing')} - Generating PDF...';
        break;
      default:
        message = t('disease.processing');
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF3a5a40)),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF606c38)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3a5a40),
          disabledBackgroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: (_imageFile == null && _imageBytes == null) || _currentStep != ProcessingStep.idle
            ? null
            : _processImageForAnalysis,
        child: Text(
          t('disease.analyze'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHealthyResult() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFdad7cd)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('disease.diagnosis'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3a5a40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('disease.healthyLeaf'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF344e41),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('disease.healthyMessage'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseResult() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFdad7cd)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('disease.diagnosis'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3a5a40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _disease,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF344e41),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${t('disease.confidence')}: ${(_confidence * 100).toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF606c38),
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const SizedBox(height: 20),
          Text(
            t('disease.treatmentSuggestions'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3a5a40),
            ),
          ),
          const SizedBox(height: 10),
          ..._formatSuggestions(_suggestions),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFfefae0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFdda15e)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('disease.professionalAdvisory'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFbc6c25),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('disease.advisoryText'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF606c38),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_languageLoaded || !_apiInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF4CAF50)),
              const SizedBox(height: 16),
              Text(t('disease.apiInitializing')),
              if (_modelInfo.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_modelInfo, style: const TextStyle(fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_error.isNotEmpty) _buildErrorSection(),
            _buildImageSelectionButtons(),
            if (_imageFile != null || _imageBytes != null) _buildImagePreview(),
            if (_verificationMessage.isNotEmpty) _buildVerificationMessage(),
            if (_currentStep != ProcessingStep.idle) _buildLoadingIndicator(),
            _buildAnalyzeButton(),
            if (_isHealthy) _buildHealthyResult(),
            if (_disease.isNotEmpty && !_isHealthy) _buildDiseaseResult(),
          ],
        ),
      ),
    );
  }
}