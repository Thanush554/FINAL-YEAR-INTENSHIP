import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key});

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  String n = '', p = '', k = '', ph = '';
  bool loading = false;
  bool languageLoaded = false;
  Map<String, dynamic>? weatherData;
  List<Map<String, dynamic>> recommendations = [];

  late final String apiEndpoint;
  
  // Language support
  String _selectedLang = 'en'; // Default to English
  
  // Translation map for multiple languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'suggestions.title': '🌱 Crop Recommendations',
      'suggestions.subtitle': 'Based on Soil & Weather',
      'suggestions.nitrogen': 'Nitrogen (N)',
      'suggestions.phosphorus': 'Phosphorus (P)',
      'suggestions.potassium': 'Potassium (K)',
      'suggestions.ph': 'pH Level',
      'suggestions.weather': 'Weather Insights',
      'suggestions.noWeather': 'No weather data available',
      'suggestions.temp': 'Temp',
      'suggestions.humidity': 'Humidity',
      'suggestions.rain': 'Rain',
      'suggestions.getRecommendations': 'Get Crop Recommendations',
      'suggestions.recommendedCrops': 'Recommended Crops',
      'suggestions.confidence': 'confidence',
      'suggestions.noRecommendations': 'No crop recommendations found',
      'suggestions.error': 'Error',
      'suggestions.somethingWrong': 'Something went wrong. Please try again.',
      'suggestions.suggestedCrop': 'Suggested crop',
      'suggestions.ok': 'OK',
    },
    'kn': {
      'suggestions.title': '🌱 ಬೆಳೆ ಶಿಫಾರಸುಗಳು',
      'suggestions.subtitle': 'ಮಣ್ಣು ಮತ್ತು ಹವಾಮಾನ ಆಧಾರಿತ',
      'suggestions.nitrogen': 'ನೈಟ್ರೋಜನ್ (N)',
      'suggestions.phosphorus': 'ಫಾಸ್ಫರಸ್ (P)',
      'suggestions.potassium': 'ಪೊಟ್ಯಾಸಿಯಮ್ (K)',
      'suggestions.ph': 'pH ಮಟ್ಟ',
      'suggestions.weather': 'ಹವಾಮಾನ ಮಾಹಿತಿ',
      'suggestions.noWeather': 'ಹವಾಮಾನ ಡೇಟಾ ಲಭ್ಯವಿಲ್ಲ',
      'suggestions.temp': 'ತಾಪಮಾನ',
      'suggestions.humidity': 'ಆರ್ದ್ರತೆ',
      'suggestions.rain': 'ಮಳೆ',
      'suggestions.getRecommendations': 'ಬೆಳೆ ಶಿಫಾರಸುಗಳನ್ನು ಪಡೆಯಿರಿ',
      'suggestions.recommendedCrops': 'ಶಿಫಾರಸು ಮಾಡಿದ ಬೆಳೆಗಳು',
      'suggestions.confidence': 'ವಿಶ್ವಾಸ',
      'suggestions.noRecommendations': 'ಯಾವುದೇ ಬೆಳೆ ಶಿಫಾರಸುಗಳು ಕಂಡುಬಂದಿಲ್ಲ',
      'suggestions.error': 'ದೋಷ',
      'suggestions.somethingWrong': 'ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'suggestions.suggestedCrop': 'ಸೂಚಿಸಿದ ಬೆಳೆ',
      'suggestions.ok': 'ಸರಿ',
    },
    'hi': {
      'suggestions.title': '🌱 फसल की सिफारिशें',
      'suggestions.subtitle': 'मिट्टी और मौसम के आधार पर',
      'suggestions.nitrogen': 'नाइट्रोजन (N)',
      'suggestions.phosphorus': 'फास्फोरस (P)',
      'suggestions.potassium': 'पोटैशियम (K)',
      'suggestions.ph': 'पीएच स्तर',
      'suggestions.weather': 'मौसम की जानकारी',
      'suggestions.noWeather': 'कोई मौसम डेटा उपलब्ध नहीं',
      'suggestions.temp': 'तापमान',
      'suggestions.humidity': 'नमी',
      'suggestions.rain': 'बारिश',
      'suggestions.getRecommendations': 'फसल की सिफारिशें प्राप्त करें',
      'suggestions.recommendedCrops': 'अनुशंसित फसलें',
      'suggestions.confidence': 'विश्वास',
      'suggestions.noRecommendations': 'कोई फसल सिफारिशें नहीं मिलीं',
      'suggestions.error': 'त्रुटि',
      'suggestions.somethingWrong': 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।',
      'suggestions.suggestedCrop': 'सुझाई गई फसल',
      'suggestions.ok': 'ठीक है',
    },
    'ta': {
      'suggestions.title': '🌱 பயிர் பரிந்துரைகள்',
      'suggestions.subtitle': 'மண் மற்றும் வானிலை அடிப்படையில்',
      'suggestions.nitrogen': 'நைட்ரஜன் (N)',
      'suggestions.phosphorus': 'பாஸ்பரஸ் (P)',
      'suggestions.potassium': 'பொட்டாசியம் (K)',
      'suggestions.ph': 'pH அளவு',
      'suggestions.weather': 'வானிலை நுண்ணறிவுகள்',
      'suggestions.noWeather': 'வானிலை தரவு இல்லை',
      'suggestions.temp': 'வெப்பநிலை',
      'suggestions.humidity': 'ஈரப்பதம்',
      'suggestions.rain': 'மழை',
      'suggestions.getRecommendations': 'பயிர் பரிந்துரைகளைப் பெறுங்கள்',
      'suggestions.recommendedCrops': 'பரிந்துரைக்கப்பட்ட பயிர்கள்',
      'suggestions.confidence': 'நம்பகம்',
      'suggestions.noRecommendations': 'பயிர் பரிந்துரைகள் எதுவும் இல்லை',
      'suggestions.error': 'பிழை',
      'suggestions.somethingWrong': 'ஏதோ தவறு நடந்துள்ளது. தயவுசெய்து மீண்டும் முயற்சி செய்யவும்.',
      'suggestions.suggestedCrop': 'பரிந்துரைக்கப்பட்ட பயிர்',
      'suggestions.ok': 'சரி',
    },
    'te': {
      'suggestions.title': '🌱 పంటల సిఫార్సులు',
      'suggestions.subtitle': 'నేల మరియు వాతావరణం ఆధారంగా',
      'suggestions.nitrogen': 'నత్రజన్ (N)',
      'suggestions.phosphorus': 'ఫాస్ఫరస్ (P)',
      'suggestions.potassium': 'పొటాషియం (K)',
      'suggestions.ph': 'pH స్థాయి',
      'suggestions.weather': 'వాతావరణ అంతర్దృష్టాలు',
      'suggestions.noWeather': 'వాతావరణ డేటా అందుబాటులో లేదు',
      'suggestions.temp': 'ఉష్ణోగ్రత',
      'suggestions.humidity': 'తేమ',
      'suggestions.rain': 'వర్షం',
      'suggestions.getRecommendations': 'పంటల సిఫార్సులను పొందండి',
      'suggestions.recommendedCrops': 'సిఫార్సు చేసిన పంటలు',
      'suggestions.confidence': 'విశ్వాసం',
      'suggestions.noRecommendations': 'పంటల సిఫార్సులు ఏవీ కనుగొనబడలేదు',
      'suggestions.error': 'లోపం',
      'suggestions.somethingWrong': 'ఏదో తప్పు జరిగింది. దయచేసి మళ్ళీ ప్రయత్నించండి.',
      'suggestions.suggestedCrop': 'సూచించిన పంట',
      'suggestions.ok': 'సరే',
    },
  };

  // Helper method to get translation based on current language
  String t(String key) {
    return translations[_selectedLang]?[key] ?? translations['en']?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
    _fetchWeatherData();

    final cropRecommendationLink =
        dotenv.env['CROP_RECOMMENDATION_LINK'] ?? 'https://default-api-url.com';
    apiEndpoint = '$cropRecommendationLink/predict';
  }

  Future<void> _initializeLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedLang = prefs.getString('selectedLanguage') ?? 'en';
        languageLoaded = true;
      });
    } catch (error) {
      debugPrint('Error loading language preference: $error');
      setState(() => languageLoaded = true);
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherString = prefs.getString('dashboard_weather');
      if (weatherString != null) {
        setState(() => weatherData = jsonDecode(weatherString));
      }
    } catch (err) {
      debugPrint('Error fetching weather data: $err');
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      loading = true;
      recommendations = [];
    });

    try {
      final inputData = {
        'N': double.tryParse(n) ?? 0.0,
        'P': double.tryParse(p) ?? 0.0,
        'K': double.tryParse(k) ?? 0.0,
        'temperature': weatherData?['main']?['temp'] ?? 0.0,
        'humidity': weatherData?['main']?['humidity'] ?? 0.0,
        'ph': double.tryParse(ph) ?? 0.0,
        'rainfall': weatherData?['rain']?['1h'] ?? 0.0,
      };

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(inputData),
      );

      final data = jsonDecode(response.body);
      debugPrint('API Response: $data');

      if (data['recommendations'] != null && data['recommendations'] is List) {
        setState(() {
          recommendations =
              List<Map<String, dynamic>>.from(data['recommendations']);
        });
      } else if (data['crop'] != null) {
        _showAlert(t('suggestions.error'), '${t('suggestions.suggestedCrop')}: ${data['crop']}');
      } else {
        _showAlert(t('suggestions.error'), t('suggestions.noRecommendations'));
      }
    } catch (err) {
      debugPrint('Error: $err');
      _showAlert(t('suggestions.error'), t('suggestions.somethingWrong'));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showAlert(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t('suggestions.ok'), style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!languageLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A2A6C), Color(0xFFB21F1F), Color(0xFF1A2A6C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.eco, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    t('suggestions.title'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, offset: Offset(1,1), blurRadius: 2)],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    t('suggestions.subtitle'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Input Fields
                  _buildInputField(Icons.water_drop, Colors.blue, t('suggestions.nitrogen'), n, (val) => setState(() => n = val)),
                  const SizedBox(height: 16),
                  _buildInputField(Icons.grass, Colors.green, t('suggestions.phosphorus'), p, (val) => setState(() => p = val)),
                  const SizedBox(height: 16),
                  _buildInputField(Icons.spa, Colors.orange, t('suggestions.potassium'), k, (val) => setState(() => k = val)),
                  const SizedBox(height: 16),
                  _buildInputField(Icons.science, Colors.purple, t('suggestions.ph'), ph, (val) => setState(() => ph = val)),

                  const SizedBox(height: 20),
                  _buildWeatherCard(),
                  const SizedBox(height: 20),

                  // Submit Button
                  GestureDetector(
                    onTap: loading ? null : _handleSubmit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                t('suggestions.getRecommendations'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            // Recommendations
            if (recommendations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      t('suggestions.recommendedCrops'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...recommendations.map((item) {
                      final confidence = (item['confidence'] as num).toDouble();
                      return _buildRecommendationCard(item['crop'], confidence);
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(IconData icon, Color color, String hint, String value, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: color),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0,3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(t('suggestions.weather'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          weatherData != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _weatherItem(Icons.thermostat, t('suggestions.temp'), "${weatherData!['main']['temp'].toStringAsFixed(1)}°C"),
                    _weatherItem(Icons.water_drop, t('suggestions.humidity'), "${weatherData!['main']['humidity']}%"),
                    _weatherItem(Icons.grain, t('suggestions.rain'), "${weatherData!['rain']?['1h'] ?? 0} mm"),
                  ],
                )
              : Text(t('suggestions.noWeather'), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  static Widget _weatherItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }

  Widget _buildRecommendationCard(String crop, double confidence) {
    final confidencePercentage = (confidence * 100).toStringAsFixed(1);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.15), blurRadius: 10, offset: const Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_outlined, color: Colors.green, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("$confidencePercentage% ${t('suggestions.confidence')}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: confidence,
            color: Colors.green,
            backgroundColor: Colors.grey.shade200,
            minHeight: 10,
          ),
        ],
      ),
    );
  }
}