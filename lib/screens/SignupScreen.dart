import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  String _selectedRole = '';
  String _errorMessage = '';
  Map<String, String> _labels = {};

  final SupabaseClient _supabase = Supabase.instance.client;

  // ---------------- Language Labels ----------------
  final Map<String, Map<String, String>> languageLabels = {
    "en": {
      "createAccount": "Create Account",
      "email": "Email",
      "fullName": "Full Name",
      "password": "Password",
      "confirmPassword": "Confirm Password",
      "showPassword": "Show Password",
      "hidePassword": "Hide Password",
      "signUp": "Sign Up",
      "alreadyHaveAccount": "Already have an account? Login",
      "roleFarmer": "Farmer",
      "roleRetailer": "Retailer",
      "selectRole": "Please select a role",
      "required": "Required",
      "passwordMismatch": "Passwords do not match",
      "welcome": "Welcome Aboard!",
      "accountCreated": "Your account has been created successfully",
      "goToLogin": "Go to Login"
    },
    "hi": {
      "createAccount": "खाता बनाएं",
      "email": "ईमेल",
      "fullName": "पूरा नाम",
      "password": "पासवर्ड",
      "confirmPassword": "पासवर्ड की पुष्टि करें",
      "showPassword": "पासवर्ड दिखाएं",
      "hidePassword": "पासवर्ड छिपाएं",
      "signUp": "साइन अप करें",
      "alreadyHaveAccount": "क्या आपका खाता है? लॉगिन करें",
      "roleFarmer": "किसान",
      "roleRetailer": "खुदरा विक्रेता",
      "selectRole": "कृपया भूमिका चुनें",
      "required": "अनिवार्य",
      "passwordMismatch": "पासवर्ड मेल नहीं खाते",
      "welcome": "स्वागत है!",
      "accountCreated": "आपका खाता सफलतापूर्वक बनाया गया है",
      "goToLogin": "लॉगिन पर जाएं"
    },
    "kn": {
      "createAccount": "ಖಾತೆ ಸೃಷ್ಟಿಸಿ",
      "email": "ಇಮೇಲ್",
      "fullName": "ಪೂರ್ಣ ಹೆಸರು",
      "password": "ಪಾಸ್ವರ್ಡ್",
      "confirmPassword": "ಪಾಸ್ವರ್ಡ್ ದೃಢಪಡಿಸಿ",
      "showPassword": "ಪಾಸ್ವರ್ಡ್ ತೋರಿಸಿ",
      "hidePassword": "ಪಾಸ್ವರ್ಡ್ ಮರೆಮಾಡಿ",
      "signUp": "ನೋಂದಣಿ ಮಾಡಿ",
      "alreadyHaveAccount": "ಈಗಾಗಲೇ ಖಾತೆ ಇದೆಯೇ? ಲಾಗಿನ್ ಮಾಡಿ",
      "roleFarmer": "ರೈತ",
      "roleRetailer": "ಚಿಲ್ಲರೆ ವ್ಯಾಪಾರಿ",
      "selectRole": "ದಯವಿಟ್ಟು ಪಾತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ",
      "required": "ಅತ್ಯಾವಶ್ಯಕ",
      "passwordMismatch": "ಪಾಸ್ವರ್ಡ್ ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ",
      "welcome": "ಸ್ವಾಗತ!",
      "accountCreated": "ನಿಮ್ಮ ಖಾತೆ ಯಶಸ್ವಿಯಾಗಿ ಸೃಷ್ಟಿಸಲಾಗಿದೆ",
      "goToLogin": "ಲಾಗಿನ್‌ಗೆ ಹೋಗಿ"
    },
    "te": {
      "createAccount": "ఖాతా సృష్టించండి",
      "email": "ఇమెయిల్",
      "fullName": "పూర్తి పేరు",
      "password": "పాస్వర్డ్",
      "confirmPassword": "పాస్వర్డ్‌ను నిర్ధారించండి",
      "showPassword": "పాస్వర్డ్ చూపించు",
      "hidePassword": "పాస్వర్డ్ దాచు",
      "signUp": "సైన్ అప్ చేయండి",
      "alreadyHaveAccount": "ఖాతా ఉన్నదా? లాగిన్ చేయండి",
      "roleFarmer": "రైతు",
      "roleRetailer": "చిల్లర వ్యాపారి",
      "selectRole": "దయచేసి పాత్రను ఎంచుకోండి",
      "required": "అవసరం",
      "passwordMismatch": "పాస్వర్డ్స్ సరిపోలడం లేదు",
      "welcome": "స్వాగతం!",
      "accountCreated": "మీ ఖాతా విజయవంతంగా సృష్టించబడింది",
      "goToLogin": "లాగిన్‌కు వెళ్ళు"
    },
    "ta": {
      "createAccount": "கணக்கை உருவாக்கவும்",
      "email": "மின்னஞ்சல்",
      "fullName": "முழு பெயர்",
      "password": "கடவுச்சொல்",
      "confirmPassword": "கடவுச்சொல்லை உறுதிப்படுத்தவும்",
      "showPassword": "கடவுச்சொல்லை காண்பிக்கவும்",
      "hidePassword": "கடவுச்சொல்லை மறைக்கவும்",
      "signUp": "பதிவு செய்யவும்",
      "alreadyHaveAccount": "ஏற்கனவே கணக்கு உள்ளதா? உள்நுழையவும்",
      "roleFarmer": "விவசாயி",
      "roleRetailer": "சில்லறை விற்பனையாளர்",
      "selectRole": "தயவுசெய்து பங்கு தேர்வு செய்யவும்",
      "required": "தேவை",
      "passwordMismatch": "கடவுச்சொற்கள் பொருந்தவில்லை",
      "welcome": "வரவேற்பு!",
      "accountCreated": "உங்கள் கணக்கு வெற்றிகரமாக உருவாக்கப்பட்டது",
      "goToLogin": "உள்நுழைவிற்கு செல்லவும்"
    },
  };

  // ---------------- Init & Language ----------------
  @override
  void initState() {
    super.initState();
    _loadLanguageLabels();
  }

  Future<void> _loadLanguageLabels() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString("selectedLanguage") ?? "en";
    _labels = languageLabels[lang] ?? languageLabels["en"]!;
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------- Signup Logic ----------------
  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole.isEmpty) {
      setState(() => _errorMessage = _labels["selectRole"]!);
      return;
    }

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      setState(() => _errorMessage = _labels["passwordMismatch"]!);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authResponse = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign up failed. Please try again.';
        });
        return;
      }

      final userId = authResponse.user!.id;

      // Insert into profiles table (with password for demo)
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'role': _selectedRole,
        'password': _passwordController.text.trim(),
      }).select();

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', _emailController.text.trim());
      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('userRole', _selectedRole);
      await prefs.setString('userId', userId);

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      print('Signup error: $e');
      setState(() => _errorMessage = 'Something went wrong. Check console.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset('assets/images/signup-bg.jpeg', fit: BoxFit.cover),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3))),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  Text(_labels["createAccount"]!,
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMessage,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 15),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration(_labels["email"]!),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) =>
                        v!.isEmpty ? _labels["required"] : null,
                  ),
                  const SizedBox(height: 15),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(_labels["fullName"]!),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) =>
                        v!.isEmpty ? _labels["required"] : null,
                  ),
                  const SizedBox(height: 15),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: _inputDecoration(_labels["password"]!),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) =>
                        v!.isEmpty ? _labels["required"] : null,
                  ),
                  const SizedBox(height: 15),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_showPassword,
                    decoration:
                        _inputDecoration(_labels["confirmPassword"]!),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) =>
                        v!.isEmpty ? _labels["required"] : null,
                  ),

                  TextButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    child: Text(
                        _showPassword
                            ? _labels["hidePassword"]!
                            : _labels["showPassword"]!,
                        style: const TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 10),

                  // Role selection
                  Row(
                      children: ['farmer', 'retailer'].map((role) {
                    final selected = _selectedRole == role;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = role),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.green.withOpacity(0.4)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected ? Colors.green : Colors.white70),
                          ),
                          child: Center(
                            child: Text(
                              role == 'farmer'
                                  ? _labels["roleFarmer"]!
                                  : _labels["roleRetailer"]!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 20),

                  // Sign up button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signupUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_labels["signUp"]!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18)),
                  ),
                  const SizedBox(height: 15),

                  // Go to Login
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(_labels["alreadyHaveAccount"]!,
                        style: const TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline)),
                  )
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green)),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(_labels["welcome"]!,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(_labels["accountCreated"]!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(_labels["goToLogin"]!),
            )
          ]),
        ),
      ),
    );
  }
}
