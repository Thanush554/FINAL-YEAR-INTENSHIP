import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = true;
  bool _showPassword = false;
  String _error = '';
  String _selectedLang = "en"; // Default language

  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ Translation map (5 languages)
  final Map<String, Map<String, String>> _t = {
    "en": {
      'login.title': 'Welcome Back',
      'login.subtitle': 'Sign in to continue',
      'login.email': 'Email',
      'login.password': 'Password',
      'login.show': 'Show',
      'login.hide': 'Hide',
      'login.loginButton': 'Login',
      'login.createAccount': 'Create Account',
      'login.forgotPassword': 'Forgot Password?',
      'login.errorEnterEmailPassword': 'Please enter email and password',
      'login.errorFetchProfile': 'Error fetching user profile',
      'login.loginSuccess': 'Login successful',
      'login.autoLoginFailed': 'Auto-login failed, please login manually',
    },
    "hi": {
      'login.title': 'वापसी पर स्वागत है',
      'login.subtitle': 'जारी रखने के लिए साइन इन करें',
      'login.email': 'ईमेल',
      'login.password': 'पासवर्ड',
      'login.show': 'दिखाएँ',
      'login.hide': 'छिपाएँ',
      'login.loginButton': 'लॉगिन',
      'login.createAccount': 'खाता बनाएँ',
      'login.forgotPassword': 'पासवर्ड भूल गए?',
      'login.errorEnterEmailPassword': 'कृपया ईमेल और पासवर्ड दर्ज करें',
      'login.errorFetchProfile': 'उपयोगकर्ता प्रोफ़ाइल प्राप्त करने में त्रुटि',
      'login.loginSuccess': 'लॉगिन सफल रहा',
      'login.autoLoginFailed': 'ऑटो-लॉगिन विफल रहा, कृपया मैन्युअल रूप से लॉगिन करें',
    },
    "kn": {
      'login.title': 'ಮತ್ತೆ ಸ್ವಾಗತ',
      'login.subtitle': 'ಮುಂದುವರಿಸಲು ಸೈನ್ ಇನ್ ಮಾಡಿ',
      'login.email': 'ಇಮೇಲ್',
      'login.password': 'ಪಾಸ್ವರ್ಡ್',
      'login.show': 'ತೋರಿಸಿ',
      'login.hide': 'ಮರೆಮಾಡಿ',
      'login.loginButton': 'ಲಾಗಿನ್',
      'login.createAccount': 'ಖಾತೆ ರಚಿಸಿ',
      'login.forgotPassword': 'ಪಾಸ್ವರ್ಡ್ ಮರೆತಿರಾ?',
      'login.errorEnterEmailPassword': 'ದಯವಿಟ್ಟು ಇಮೇಲ್ ಮತ್ತು ಪಾಸ್ವರ್ಡ್ ನಮೂದಿಸಿ',
      'login.errorFetchProfile': 'ಬಳಕೆದಾರ ಪ್ರೊಫೈಲ್ ಪಡೆಯುವಲ್ಲಿ ದೋಷ',
      'login.loginSuccess': 'ಲಾಗಿನ್ ಯಶಸ್ವಿಯಾಗಿದೆ',
      'login.autoLoginFailed': 'ಸ್ವಯಂ-ಲಾಗಿನ್ ವಿಫಲವಾಗಿದೆ, ದಯವಿಟ್ಟು ಕೈಯಲ್ಲಿ ಲಾಗಿನ್ ಮಾಡಿ',
    },
    "ta": {
      'login.title': 'மீண்டும் வருக',
      'login.subtitle': 'தொடர உள்நுழைக',
      'login.email': 'மின்னஞ்சல்',
      'login.password': 'கடவுச்சொல்',
      'login.show': 'காட்டு',
      'login.hide': 'மறை',
      'login.loginButton': 'உள்நுழைக',
      'login.createAccount': 'கணக்கை உருவாக்கவும்',
      'login.forgotPassword': 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?',
      'login.errorEnterEmailPassword': 'தயவுசெய்து மின்னஞ்சல் மற்றும் கடவுச்சொல்லை உள்ளிடவும்',
      'login.errorFetchProfile': 'பயனர் விவரங்களை பெறுவதில் பிழை',
      'login.loginSuccess': 'உள்நுழைவு வெற்றிகரமாக முடிந்தது',
      'login.autoLoginFailed': 'தானியங்கு உள்நுழைவு தோல்வியடைந்தது, தயவுசெய்து கையால் உள்நுழைக',
    },
    "te": {
      'login.title': 'తిరిగి స్వాగతం',
      'login.subtitle': 'కొనసాగేందుకు సైన్ ఇన్ చేయండి',
      'login.email': 'ఇమెయిల్',
      'login.password': 'పాస్వర్డ్',
      'login.show': 'చూపించు',
      'login.hide': 'దాచు',
      'login.loginButton': 'లాగిన్',
      'login.createAccount': 'ఖాతా సృష్టించండి',
      'login.forgotPassword': 'పాస్వర్డ్ మర్చిపోయారా?',
      'login.errorEnterEmailPassword': 'దయచేసి ఇమెయిల్ మరియు పాస్వర్డ్ నమోదు చేయండి',
      'login.errorFetchProfile': 'ప్రొఫైల్ తీసుకురావడంలో లోపం',
      'login.loginSuccess': 'లాగిన్ విజయవంతమైంది',
      'login.autoLoginFailed': 'ఆటో-లాగిన్ విఫలమైంది, దయచేసి చేతితో లాగిన్ చేయండి',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLanguageAndCredentials();
  }

  Future<void> _loadLanguageAndCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLang = prefs.getString('selectedLanguage') ?? "en";
    await _checkStoredCredentials();
  }

  // ✅ Auto-login logic (unchanged)
  Future<void> _checkStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('userEmail');
      final storedPassword = prefs.getString('userPassword');
      final storedRole = prefs.getString('userRole');

      if (storedEmail != null && storedPassword != null && storedRole != null) {
        await _attemptAutoLogin(storedEmail, storedPassword, storedRole);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      _error = _t[_selectedLang]!['login.autoLoginFailed']!;
      setState(() => _loading = false);
    }
  }
  // ---------------- Auto-login helper (unchanged) ----------------
  Future<void> _attemptAutoLogin(String email, String password, String role) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        if (session.user.email == email) {
          _redirectToDashboard(role);
          return;
        }
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final profileResponse = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .single();

        if (profileResponse['role'] == role) {
          _redirectToDashboard(role);
          return;
        }
      }

      setState(() {
        _loading = false;
        _error = _t[_selectedLang]!['login.autoLoginFailed']!;
      });
    } catch (err) {
      debugPrint('Auto-login error: $err');
      setState(() {
        _loading = false;
        _error = _t[_selectedLang]!['login.autoLoginFailed']!;
      });
    }
  }

  // ---------------- Redirect ----------------
  void _redirectToDashboard(String role) {
    if (role == 'farmer') {
      Navigator.pushReplacementNamed(context, '/farmerDashboard');
    } else if (role == 'retailer') {
      Navigator.pushReplacementNamed(context, '/retailerDashboard');
    } else {
      setState(() {
        _loading = false;
        _error = 'Could not determine user role';
      });
    }
  }

  // ---------------- Manual login (unchanged logic) ----------------
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        setState(() {
          _loading = false;
          _error = 'Invalid email or password';
        });
        return;
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select('id, role')
          .eq('id', response.user!.id)
          .single();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', _emailController.text.trim());
      await prefs.setString('userPassword', _passwordController.text);
      await prefs.setString('userRole', profileResponse['role']);
      await prefs.setString('userId', profileResponse['id']);

      _showSuccessDialog();
      _redirectToDashboard(profileResponse['role']);
    } catch (err) {
      debugPrint('Login error: $err');
      setState(() {
        _loading = false;
        _error = 'Something went wrong during login';
      });
    }
  }

  // ---------------- Helpers ----------------
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t[_selectedLang]!['login.loginSuccess']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleForgotPassword() {
    if (_emailController.text.isEmpty) {
      setState(() {
        _error = _t[_selectedLang]!['login.errorEnterEmailPassword']!;
      });
      return;
    }
    Navigator.pushNamed(context, '/changePassword');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    final labels = _t[_selectedLang]!;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // Content
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            labels['login.title']!,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 10),

                          // Subtitle
                          Text(
                            labels['login.subtitle']!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 25),

                          // Error message
                          if (_error.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _error,
                                style: const TextStyle(
                                  color: Color(0xFFFF5252),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return labels['login.errorEnterEmailPassword'];
                              }
                              return null;
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: labels['login.email'],
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(15),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                          ),

                          const SizedBox(height: 15),

                          // Password field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _passwordController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return labels['login.errorEnterEmailPassword'];
                                      }
                                      return null;
                                    },
                                    obscureText: !_showPassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: labels['login.password'],
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(15),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                    child: Text(
                                      _showPassword ? labels['login.hide']! : labels['login.show']!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Login button
                          ElevatedButton(
                            onPressed: _loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Center(
                              child: Text(
                                labels['login.loginButton']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Create account button
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    labels['login.createAccount']!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black54,
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Forgot password button
                              GestureDetector(
                                onTap: _handleForgotPassword,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    labels['login.forgotPassword']!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black54,
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
