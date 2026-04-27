import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _loading = true;
  String selectedLang = "en"; // Default language

  // 🌐 Language Texts
  final Map<String, Map<String, String>> languageTexts = {
    "en": {
      "welcome": "Welcome to Namma Raitha",
      "description":
          "Empowering Farmers and Retailers with Direct Market Access. Sell, Buy, Negotiate, and Predict Crop Health.",
      "getStarted": "Get Started",
    },
    "hi": {
      "welcome": "नम्मा रैथा में आपका स्वागत है",
      "description":
          "किसानों और खुदरा विक्रेताओं को सीधी बाजार पहुँच के साथ सशक्त बनाना। बेचें, खरीदें, बातचीत करें और फसल की सेहत का पूर्वानुमान लगाएं।",
      "getStarted": "शुरू करें",
    },
    "kn": {
      "welcome": "ನಮ್ಮ ರೈತಕ್ಕೆ ಸ್ವಾಗತ",
      "description":
          "ಕೃಷಿಕರು ಮತ್ತು ಚಿಲ್ಲರೆ ವ್ಯಾಪಾರಿಗಳಿಗೆ ನೇರ ಮಾರುಕಟ್ಟೆ ಪ್ರವೇಶದ ಮೂಲಕ ಶಕ್ತಿ ನೀಡುವುದು. ಮಾರಾಟ ಮಾಡಿ, ಖರೀದಿಸಿ, ಮಾತುಕತೆ ನಡೆಸಿ, ಬೆಳೆ ಆರೋಗ್ಯವನ್ನು ಊಹಿಸಿ",
      "getStarted": "ಪ್ರಾರಂಭಿಸಿ",
    },
    "ta": {
      "welcome": "நம்ம ரைத்தாவிற்கு வரவேற்பு",
      "description":
          "விவசாயிகள் மற்றும் சில்லறை விற்பனையாளர்களுக்கு நேரடி சந்தை அணுகுமுறையால் அதிகாரமளித்தல். விற்கவும், வாங்கவும், பேச்சுவார்த்தை நடத்தவும், பயிர் ஆரோக்கியத்தை கணிக்கவும்.",
      "getStarted": "தொடங்கவும்",
    },
    "te": {
      "welcome": "నమ్మ రైతకు స్వాగతం",
      "description":
          "రైతులు మరియు చిల్లర వ్యాపారులను నేరుగా మార్కెట్ ప్రాప్తితో సాధికారులను చేయడం. అమ్మండి, కొనండి, చర్చించండి, పంట ఆరోగ్యాన్ని అంచనా వేయండి.",
      "getStarted": "ప్రారంభించండి",
    },
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    selectedLang = prefs.getString('selectedLanguage') ?? "en";

    setState(() {
      _loading = false;
    });
  }

  void _handleGetStarted() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // NEW: Method to navigate to language selection screen
  void _navigateToLanguage() {
    Navigator.of(context).pushNamed('/languages');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = languageTexts[selectedLang]!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/farm.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          
          // NEW: Language selector button positioned at top right
          Positioned(
            top: 40, // Adjust this value for proper positioning below status bar
            right: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: _navigateToLanguage,
                icon: const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 28,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0),
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                tooltip: 'Change Language',
              ),
            ),
          ),
          
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          else
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text["welcome"]!,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        text["description"]!,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFFEEEEEE),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _handleGetStarted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 40,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          text["getStarted"]!,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}