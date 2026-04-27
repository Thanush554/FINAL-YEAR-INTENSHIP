import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // Import for ImageFilter

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _manualEmailController = TextEditingController();
  
  final bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _emailConfirmed = false;
  bool _emailRejected = false;
  bool _processing = false;
  
  String? _userEmail;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String _currentLanguage = 'en'; // Default language

  // Translation map with 5 languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'changePassword': 'Change Password',
      'loadingUserData': 'Loading user data...',
      'isThisYourEmail': 'Is this your email?',
      'yes': 'Yes',
      'no': 'No',
      'enterYourEmail': 'Enter your email',
      'newPassword': 'New Password',
      'confirmPassword': 'Confirm Password',
      'emailRequired': 'Email is required',
      'emailInvalid': 'Email is invalid',
      'emailNotFound': 'Email not found',
      'passwordRequired': 'Password is required',
      'passwordInvalid': 'Password must be at least 8 characters with uppercase, lowercase, number and special character',
      'passwordMismatch': 'Passwords do not match',
      'passwordUpdated': 'Password updated successfully',
      'passwordUpdateFailed': 'Failed to update password',
      'updatePassword': 'Update Password',
      'success': 'Success',
      'error': 'Error',
      'submit': 'Submit',
      'cancel': 'Cancel',
    },
    'kn': {
      'changePassword': 'ಪಾಸ್‌ವರ್ಡ್ ಬದಲಿಸಿ',
      'loadingUserData': 'ಬಳಕೆದಾರರ ಡೇಟಾವನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'isThisYourEmail': 'ಇದು ನಿಮ್ಮ ಇಮೇಲ್ ಆಗಿದೆಯೇ?',
      'yes': 'ಹೌದು',
      'no': 'ಇಲ್ಲ',
      'enterYourEmail': 'ನಿಮ್ಮ ಇಮೇಲ್ ಅನ್ನು ನಮೂದಿಸಿ',
      'newPassword': 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್',
      'confirmPassword': 'ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ',
      'emailRequired': 'ಇಮೇಲ್ ಅಗತ್ಯವಿದೆ',
      'emailInvalid': 'ಇಮೇಲ್ ಅಮಾನ್ಯವಾಗಿದೆ',
      'emailNotFound': 'ಇಮೇಲ್ ಸಿಗಲಿಲ್ಲ',
      'passwordRequired': 'ಪಾಸ್‌ವರ್ಡ್ ಅಗತ್ಯವಿದೆ',
      'passwordInvalid': 'ಪಾಸ್‌ವರ್ಡ್ ಕನಿಷ್ಠ 8 ಅಕ್ಷರಗಳನ್ನು ಹೊಂದಿರಬೇಕು, ದೊಡ್ಡ ಅಕ್ಷರ, ಸಣ್ಣ ಅಕ್ಷರ ಮತ್ತು ವಿಶೇಷ ಅಕ್ಷರವನ್ನು ಹೊಂದಿರಬೇಕು',
      'passwordMismatch': 'ಪಾಸ್‌ವರ್ಡ್‌ಗಳು ಹೊಂದಿಕೊಳ್ಳುವಿಲ್ಲ',
      'passwordUpdated': 'ಪಾಸ್‌ವರ್ಡ್ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ',
      'passwordUpdateFailed': 'ಪಾಸ್‌ವರ್ಡ್ ನವೀಕರಿಸಲು ವಿಫಲವಾಗಿದೆ',
      'updatePassword': 'ಪಾಸ್‌ವರ್ಡ್ ನವೀಕರಿಸಿ',
      'success': 'ಯಶಸ್ಸು',
      'error': 'ದೋಷ',
      'submit': 'ಸಲ್ಲಿಸಿ',
      'cancel': 'ರದ್ದುಮಾಡಿ',
    },
    'hi': {
      'changePassword': 'पासवर्ड बदलें',
      'loadingUserData': 'उपयोगकर्ता डेटा लोड हो रहा है...',
      'isThisYourEmail': 'क्या यह आपका ईमेल है?',
      'yes': 'हाँ',
      'no': 'नहीं',
      'enterYourEmail': 'अपना ईमेल दर्ज करें',
      'newPassword': 'नया पासवर्ड',
      'confirmPassword': 'पासवर्ड की पुष्टि करें',
      'emailRequired': 'ईमेल आवश्यक है',
      'emailInvalid': 'ईमेल अमान्य है',
      'emailNotFound': 'ईमेल नहीं मिला',
      'passwordRequired': 'पासवर्ड आवश्यक है',
      'passwordInvalid': 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए जिसमें बड़े अक्षर, छोटे अक्षर, संख्या और विशेष अक्षर हो',
      'passwordMismatch': 'पासवर्ड मेल नहीं खा रहे',
      'passwordUpdated': 'पासवर्ड सफलतापूर्वक अपडेट किया गया',
      'passwordUpdateFailed': 'पासवर्ड अपडेट करने में विफल',
      'updatePassword': 'पासवर्ड अपडेट करें',
      'success': 'सफलता',
      'error': 'त्रुटि',
      'submit': 'जमा करें',
      'cancel': 'रद्द करें',
    },
    'te': {
      'changePassword': 'పాస్‌వర్డ్ మార్చు',
      'loadingUserData': 'వినియోగదారు డేటాను లోడ్ అవుతోంది...',
      'isThisYourEmail': 'ఇది మీ ఇమెయిల్ అవుతుందా?',
      'yes': 'అవును',
      'no': 'కాదు',
      'enterYourEmail': 'మీ ఇమెయిల్ నమోదు చేయండి',
      'newPassword': 'కొత్త పాస్‌వర్డ్',
      'confirmPassword': 'పాస్‌వర్డ్ నిర్ధారించండి',
      'emailRequired': 'ఇమెయిల్ అవసరం',
      'emailInvalid': 'ఇమెయిల్ చెల్లదు',
      'emailNotFound': 'ఇమెయిల్ కనుగోలేదు',
      'passwordRequired': 'పాస్‌వర్డ్ అవసరం',
      'passwordInvalid': 'పాస్‌వర్డ్ కనీసి 8 అక్షరాలు ఉండాలి, పెద్ద అక్షరాలు, చిన్న అక్షరాలు, సంఖ్య మరియు ప్రత్యేక అక్షరాలు ఉండాలి',
      'passwordMismatch': 'పాస్‌వర్డ్‌లు సరిపోలేదు',
      'passwordUpdated': 'పాస్‌వర్డ్ విజయవంతంగా నవీకరించబడింది',
      'passwordUpdateFailed': 'పాస్‌వర్డ్ నవీకరించడం విఫలమైంది',
      'updatePassword': 'పాస్‌వర్డ్ నవీకరించు',
      'success': 'విజయం',
      'error': 'లోపం',
      'submit': 'సమర్పించు',
      'cancel': 'రద్దుచేయి',
    },
    'ta': {
      'changePassword': 'கடவுச்சொல்லை மாற்று',
      'loadingUserData': 'பயனர் தரவு ஏற்றப்படுகிறது...',
      'isThisYourEmail': 'இது உங்கள் மின்னஞ்சலா?',
      'yes': 'ஆம்',
      'no': 'இல்லை',
      'enterYourEmail': 'உங்கள் மின்னஞ்சலை உள்ளிடவும்',
      'newPassword': 'புதிய கடவுச்சொல்',
      'confirmPassword': 'கடவுச்சொல்லை உறுதிப்பு செய்யவும்',
      'emailRequired': 'மின்னஞ்சல் தேவை',
      'emailInvalid': 'மின்னஞ்சல் தவறானது',
      'emailNotFound': 'மின்னஞ்சல் கிடைப்படவில்லை',
      'passwordRequired': 'கடவுச்சொல் தேவை',
      'passwordInvalid': 'கடவுச்சொல் குறைந்தது 8 எழுத்துகள், பெரிய எழுத்து, சிறிய எழுத்து, எண் மற்றும் சிறப்பெழுத்து ஆகியிருக்க வேண்டும்',
      'passwordMismatch': 'கடவுச்சொற்கள் பொருந்தவில்லை',
      'passwordUpdated': 'கடவுச்சொல் வெற்றிகரமாக புதுப்பிக்கப்பட்டது',
      'passwordUpdateFailed': 'கடவுச்சொல்லை புதுப்பிக்க முடியவில்லை',
      'updatePassword': 'கடவுச்சொல்லை புதுப்பிக்கவும்',
      'success': 'வெற்றி',
      'error': 'பிழை',
      'submit': 'சமர்ப்பி',
      'cancel': 'ரத்து செய்யவும்',
    },
  };

  // Function to get translation based on current language
  String t(String key) {
    return translations[_currentLanguage]?[key] ?? translations['en']?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _fetchUserEmail();
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _manualEmailController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserEmail() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _emailRejected = true;
        });
        return;
      }
      
      setState(() {
        _userEmail = user.email;
      });
    } catch (e) {
      setState(() {
        _emailRejected = true;
      });
    }
  }

  // Email validation regex
  bool _validateEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.(com|in)$').hasMatch(email);
  }
  
  // Password validation regex
  bool _validatePassword(String password) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$').hasMatch(password);
  }

  Future<void> _changePassword() async {
    // Reset errors
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final email = _emailConfirmed ? _userEmail : _manualEmailController.text.trim();
    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Email validation
    if (email == null || email.isEmpty) {
      setState(() {
        _emailError = t('emailRequired');
      });
      return;
    } else if (!_validateEmail(email)) {
      setState(() {
        _emailError = t('emailInvalid');
      });
      return;
    }
    
    // Password validation
    if (password.isEmpty) {
      setState(() {
        _passwordError = t('passwordRequired');
      });
      return;
    } else if (!_validatePassword(password)) {
      setState(() {
        _passwordError = t('passwordInvalid');
      });
      return;
    }
    
    // Confirm password validation
    if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = t('passwordMismatch');
      });
      return;
    }
    
    try {
      setState(() {
        _processing = true;
      });
      
      if (_emailConfirmed) {
        // Update current user's password
        final response = await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: password),
        );
        
        if (response.user == null) {
          throw Exception('Failed to update password');
        }
        
        // Get current user id
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception('User not found');
        
        // Update the profiles table
        final error = await Supabase.instance.client
            .from('profiles')
            .update({'password': password})
            .eq('id', user.id)
            .then((value) => null, onError: (error) => error);
            
        if (error != null) throw error;
        
        // Save password locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userPassword", password);
        
        _showSuccessDialog();
      } else {
        // For another user, get user id from profiles by email
        final response = await Supabase.instance.client
            .from("profiles")
            .select("id")
            .eq("email", email)
            .single();
            
        if (response.isEmpty) {
          setState(() {
            _emailError = t('emailNotFound');
          });
          return;
        }
        
        // FIXED: Use named parameter for RPC call
        final rpcResponse = await Supabase.instance.client
            .rpc('update_user_password', params: {
              'user_id': response['id'],
              'new_password': password
            });
            
        if (rpcResponse.error != null) throw rpcResponse.error!;
        
        _showSuccessDialog();
      }
    } catch (error) {
      _showErrorDialog(error.toString());
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('success')),
        content: Text(t('passwordUpdated')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(t('submit')),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/changepassword.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  // Fully transparent container with only border
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.7),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Text(
                            t('changePassword'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Email confirmation section
                          if (!_emailConfirmed && _userEmail != null && !_emailRejected)
                            _buildEmailConfirmation(),
                          
                          // Manual email input section
                          if ((_emailRejected || _userEmail == null) && !_emailConfirmed)
                            _buildManualEmailInput(),
                          
                          // New password input
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: t('newPassword'),
                            obscureText: _obscureNewPassword,
                            toggleObscure: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                            errorText: _passwordError,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Confirm password input
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: t('confirmPassword'),
                            obscureText: _obscureConfirmPassword,
                            toggleObscure: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            errorText: _confirmPasswordError,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Submit button
                          ElevatedButton(
                            onPressed: _processing ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 5,
                            ),
                            child: _processing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(t('updatePassword')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailConfirmation() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      // Fully transparent container with only border
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('isThisYourEmail'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userEmail!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _emailConfirmed = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(t('yes')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _emailRejected = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(t('no')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only border, no background fill
        TextFormField(
          controller: _manualEmailController,
          decoration: InputDecoration(
            labelText: t('enterYourEmail'),
            labelStyle: const TextStyle(color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.7), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            errorText: _emailError,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return t('emailRequired');
            } else if (!_validateEmail(value)) {
              return t('emailInvalid');
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleObscure,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorText: errorText,
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: toggleObscure,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return t('passwordRequired');
        } else if (!_validatePassword(value)) {
          return t('passwordInvalid');
        }
        return null;
      },
    );
  }
}