import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool loading = true;
  Map<String, dynamic>? profile;
  bool showPassword = false;
  String _currentLanguage = 'en'; // Default language is English

  // Translation map with support for multiple languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'profile.loading': 'Loading profile...',
      'profile.noProfileFound': 'No profile found',
      'profile.farmerProfile': 'Farmer Profile',
      'profile.retailerProfile': 'Retailer Profile',
      'profile.name': 'Name',
      'profile.email': 'Email',
      'profile.role': 'Role',
      'profile.joinedOn': 'Joined On',
      'profile.password': 'Password',
      'profile.earnings': 'Earnings',
      'profile.changePassword': 'Change Password',
      'profile.footer': '© 2023 Namma Raitha. All rights reserved.',
    },
    'kn': {
      'profile.loading': 'ಪ್ರೊಫೈಲ್ ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
      'profile.noProfileFound': 'ಯಾವುದೇ ಪ್ರೊಫೈಲ್ ಕಂಡುಬಂದಿಲ್ಲ',
      'profile.farmerProfile': 'ರೈತರ ಪ್ರೊಫೈಲ್',
      'profile.retailerProfile': 'ಚಿಲ್ಲರೆ ವ್ಯಾಪಾರಿ ಪ್ರೊಫೈಲ್',
      'profile.name': 'ಹೆಸರು',
      'profile.email': 'ಇಮೇಲ್',
      'profile.role': 'ಪಾತ್ರ',
      'profile.joinedOn': 'ಸೇರಿದ ದಿನಾಂಕ',
      'profile.password': 'ಪಾಸ್‌ವರ್ಡ್',
      'profile.earnings': 'ಗಳಿಕೆಗಳು',
      'profile.changePassword': 'ಪಾಸ್‌ವರ್ಡ್ ಬದಲಾಯಿಸಿ',
      'profile.footer': '© 2023 ನಮ್ಮ ರೈತ. ಎಲ್ಲಾ ಹಕ್ಕುಗಳು ಕಾಯ್ದಿರಿಸಲ್ಪಟ್ಟಿವೆ.',
    },
    'hi': {
      'profile.loading': 'प्रोफ़ाइल लोड हो रही है...',
      'profile.noProfileFound': 'कोई प्रोफ़ाइल नहीं मिली',
      'profile.farmerProfile': 'किसान प्रोफ़ाइल',
      'profile.retailerProfile': 'खुदरा विक्रेता प्रोफ़ाइल',
      'profile.name': 'नाम',
      'profile.email': 'ईमेल',
      'profile.role': 'भूमिका',
      'profile.joinedOn': 'जुड़ने की तिथि',
      'profile.password': 'पासवर्ड',
      'profile.earnings': 'कमाई',
      'profile.changePassword': 'पासवर्ड बदलें',
      'profile.footer': '© 2023 नम्मा रैथा. सर्वाधिकार सुरक्षित.',
    },
    'te': {
      'profile.loading': 'ప్రొఫైల్ లోడ్ అవుతోంది...',
      'profile.noProfileFound': 'ప్రొఫైల్ కనుగొనబడలేదు',
      'profile.farmerProfile': 'రైతు ప్రొఫైల్',
      'profile.retailerProfile': 'చిల్లర వ్యాపారి ప్రొఫైల్',
      'profile.name': 'పేరు',
      'profile.email': 'ఇమెయిల్',
      'profile.role': 'పాత్ర',
      'profile.joinedOn': 'చేరిన తేదీ',
      'profile.password': 'పాస్వర్డ్',
      'profile.earnings': 'ఆదాయాలు',
      'profile.changePassword': 'పాస్వర్డ్ మార్చండి',
      'profile.footer': '© 2023 నమ్మ రైతు. అన్ని హక్కులు ప్రత్యేకించబడ్డాయి.',
    },
    'ta': {
      'profile.loading': 'சுயவிவரம் ஏற்றப்படுகிறது...',
      'profile.noProfileFound': 'சுயவிவரம் கிடைக்கவில்லை',
      'profile.farmerProfile': 'விவசாயி சுயவிவரம்',
      'profile.retailerProfile': 'சில்லறை வியாபாரி சுயவிவரம்',
      'profile.name': 'பெயர்',
      'profile.email': 'மின்னஞ்சல்',
      'profile.role': 'பங்கு',
      'profile.joinedOn': 'சேர்ந்த தேதி',
      'profile.password': 'கடவுச்சொல்',
      'profile.earnings': 'வருமானம்',
      'profile.changePassword': 'கடவுச்சொல்லை மாற்றவும்',
      'profile.footer': '© 2023 நம்ம ரைதா. அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை.',
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
    fetchProfile();
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

  Future<void> fetchProfile() async {
    try {
      setState(() {
        loading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        profile = response;
        loading = false;
      });
    } catch (err) {
      print('Error fetching profile: $err');
      setState(() {
        loading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${err.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 16),
              Text(t('profile.loading')),
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Text(t('profile.noProfileFound')),
        ),
      );
    }

    final isFarmer = profile?['role'] == 'farmer';
    final theme = isFarmer ? farmerTheme : retailerTheme;

    return Scaffold(
      backgroundColor: theme['bg']!,
      appBar: AppBar(
        title: Text(
          isFarmer ? t('profile.farmerProfile') : t('profile.retailerProfile'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme['headerBg']!,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/languages');
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme['accent']!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: theme['accent']!.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileItem(
                        label: t('profile.name'),
                        value: profile?['name'] ?? '',
                        theme: theme,
                      ),
                      _buildProfileItem(
                        label: t('profile.email'),
                        value: profile?['email'] ?? '',
                        theme: theme,
                      ),
                      _buildProfileItem(
                        label: t('profile.role'),
                        value: profile?['role'] ?? '',
                        theme: theme,
                      ),
                      _buildProfileItem(
                        label: t('profile.joinedOn'),
                        value: profile?['created_at'] != null 
                            ? _formatDate(DateTime.parse(profile?['created_at']))
                            : '',
                        theme: theme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Password Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('profile.password'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme['accent']!,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: theme['passwordBg']!,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme['accent']!, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                obscureText: !showPassword,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: TextStyle(color: theme['text']!),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                style: TextStyle(color: theme['text']!),
                                // Set the actual password value if available
                                controller: TextEditingController(
                                  text: showPassword ? (profile?['password'] ?? '••••••••') : '••••••••',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                showPassword ? Icons.visibility_off : Icons.visibility,
                                color: theme['accent']!,
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Farmer Earnings Button
            if (isFarmer)
              _buildProfileButton(
                icon: Icons.attach_money,
                text: t('profile.earnings'),
                theme: theme,
                onPressed: () {
                  Navigator.pushNamed(context, '/earnings');
                },
              ),

            // Change Password Button
            _buildProfileButton(
              icon: Icons.lock,
              text: t('profile.changePassword'),
              theme: theme,
              onPressed: () {
                Navigator.pushNamed(context, '/changePassword');
              },
            ),

            // Footer
            Container(
              margin: const EdgeInsets.only(top: 40, bottom: 20),
              child: Text(
                t('profile.footer'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme['accent']!,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildProfileItem({
    required String label,
    required String value,
    required Map<String, Color> theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme['accent']!,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String text,
    required Map<String, Color> theme,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme['accent']!,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 5,
          shadowColor: theme['accent']!.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Theme definitions
final farmerTheme = {
  'bg': const Color(0xFFF8FBF5),
  'headerBg': const Color(0xFF2E7D32),
  'accent': const Color(0xFF388E3C),
  'text': const Color(0xFF2E7D32),
  'passwordBg': const Color(0x0D388E3C),
};

final retailerTheme = {
  'bg': const Color(0xFFF5F9FF),
  'headerBg': const Color(0xFF1565C0),
  'accent': const Color(0xFF1976D2),
  'text': const Color(0xFF1565C0),
  'passwordBg': const Color(0x0D1976D2),
};