import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectorPage extends StatefulWidget {
  final String? redirectTo; // optional navigation target

  const LanguageSelectorPage({super.key, this.redirectTo});

  @override
  State<LanguageSelectorPage> createState() => _LanguageSelectorPageState();
}

class _LanguageSelectorPageState extends State<LanguageSelectorPage> {
  String _language = "en";
  bool _loading = true;

  // Supported languages
  final Map<String, String> languages = {
    "en": "English",
    "hi": "Hindi",
    "kn": "Kannada",
    "te": "Telugu",
    "ta": "Tamil",
  };

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedLang = prefs.getString("selectedLanguage");
      if (storedLang != null && languages.containsKey(storedLang)) {
        setState(() => _language = storedLang);
      }
    } catch (e) {
      debugPrint("Error loading language: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _changeLanguage(String langCode) async {
    if (!languages.containsKey(langCode)) return;
    setState(() => _language = langCode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("selectedLanguage", langCode);
    } catch (e) {
      debugPrint("Error saving language: $e");
    }
  }

  Future<void> _handleLanguageSelect(String langCode) async {
    await _changeLanguage(langCode);
    if (!mounted) return;
    // Always redirect to home after selection
    Navigator.pushReplacementNamed(context, "/home");
  }

  void _handleClose() {
    if (widget.redirectTo == "signup") {
      Navigator.pushReplacementNamed(context, "/signup");
    } else if (widget.redirectTo == "profile") {
      Navigator.pushReplacementNamed(context, "/profile");
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Select Language",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Language options
              ...languages.keys.map((code) {
                final isSelected = _language == code;
                return GestureDetector(
                  onTap: () => _handleLanguageSelect(code),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF32CD32) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        languages[code]!,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 30),

              // Close Button
              GestureDetector(
                onTap: _handleClose,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
