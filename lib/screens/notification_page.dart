import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  bool isDeleting = false;
  String? errorMessage;
  String _currentLanguage = 'en'; // Default language

  // Translation map with 5 languages
  final Map<String, Map<String, String>> translations = {
    'en': {
      'notifications.title': 'Notifications',
      'notifications.loading': 'Loading notifications...',
      'notifications.error': 'Failed to load notifications. Please try again.',
      'notifications.noNotifications': 'No Notifications',
      'notifications.noNewNotifications': 'You have no new notifications',
      'notifications.unknownCrop': 'Unknown Crop',
      'notifications.message': 'Message',
      'notifications.ok': 'OK',
      'notifications.removedSuccessfully': 'Notification removed successfully',
      'notifications.failedToRemove': 'Failed to remove notification',
      'notifications.failedToOpen': 'Failed to open notification',
      'notifications.deleteConfirmation': 'Are you sure you want to delete this notification?',
      'notifications.cancel': 'Cancel',
      'notifications.delete': 'Delete',
    },
    'kn': {
      'notifications.title': 'ಅಧಿಸೂಚನೆಗಳು',
      'notifications.loading': 'ಅಧಿಸೂಚನೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'notifications.error': 'ಅಧಿಸೂಚನೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'notifications.noNotifications': 'ಯಾವುದೇ ಅಧಿಸೂಚನೆಗಳಿಲ್ಲ',
      'notifications.noNewNotifications': 'ನಿಮಗೆ ಹೊಸ ಅಧಿಸೂಚನೆಗಳಿಲ್ಲ',
      'notifications.unknownCrop': 'ತಿಳಿಯದ ಬೆಳೆ',
      'notifications.message': 'ಸಂದೇಶ',
      'notifications.ok': 'ಸರಿ',
      'notifications.removedSuccessfully': 'ಅಧಿಸೂಚನೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
      'notifications.failedToRemove': 'ಅಧಿಸೂಚನೆಯನ್ನು ತೆಗೆದುಹಾಕಲು ವಿಫಲವಾಗಿದೆ',
      'notifications.failedToOpen': 'ಅಧಿಸೂಚನೆಯನ್ನು ತೆರೆಯಲು ವಿಫಲವಾಗಿದೆ',
      'notifications.deleteConfirmation': 'ನೀವು ಖಚಿತವಾಗಿ ಈ ಅಧಿಸೂಚನೆಯನ್ನು ಅಳಿಸಲು ಬಯಸುವಿರಾ?',
      'notifications.cancel': 'ರದ್ದುಮಾಡಿ',
      'notifications.delete': 'ಅಳಿಸಿ',
    },
    'hi': {
      'notifications.title': 'सूचनाएं',
      'notifications.loading': 'सूचनाएं लोड हो रही हैं...',
      'notifications.error': 'सूचनाएं लोड करने में विफल। कृपया पुनः प्रयास करें।',
      'notifications.noNotifications': 'कोई सूचनाएं नहीं',
      'notifications.noNewNotifications': 'आपके पास कोई नई सूचनाएं नहीं हैं',
      'notifications.unknownCrop': 'अज्ञात फसल',
      'notifications.message': 'संदेश',
      'notifications.ok': 'ठीक है',
      'notifications.removedSuccessfully': 'सूचना सफलतापूर्वक हटा दी गई',
      'notifications.failedToRemove': 'सूचना हटाने में विफल',
      'notifications.failedToOpen': 'सूचना खोलने में विफल',
      'notifications.deleteConfirmation': 'क्या आप वाकई इस सूचना को हटाना चाहते हैं?',
      'notifications.cancel': 'रद्द करें',
      'notifications.delete': 'हटाएं',
    },
    'te': {
      'notifications.title': 'నోటిఫికేషన్లు',
      'notifications.loading': 'నోటిఫికేషన్లు లోడ్ అవుతున్నాయి...',
      'notifications.error': 'నోటిఫికేషన్లు లోడ్ చేయడంలో విఫలమైంది. దయచేసి మళ్ళీ ప్రయత్నించండి.',
      'notifications.noNotifications': 'నోటిఫికేషన్లు లేవు',
      'notifications.noNewNotifications': 'మీకు కొత్త నోటిఫికేషన్లు లేవు',
      'notifications.unknownCrop': 'తెలియని పంట',
      'notifications.message': 'సందేశం',
      'notifications.ok': 'సరే',
      'notifications.removedSuccessfully': 'నోటిఫికేషన్ విజయవంతంగా తీసివేయబడింది',
      'notifications.failedToRemove': 'నోటిఫికేషన్ తీసివేయడంలో విఫలమైంది',
      'notifications.failedToOpen': 'నోటిఫికేషన్ తెరవడంలో విఫలమైంది',
      'notifications.deleteConfirmation': 'మీరు ఖచ్చితంగా ఈ నోటిఫికేషన్ను తీసివేయాలనుకుంటున్నారా?',
      'notifications.cancel': 'రద్దు చేయండి',
      'notifications.delete': 'తీసివేయండి',
    },
    'ta': {
      'notifications.title': 'அறிவிப்புகள்',
      'notifications.loading': 'அறிவிப்புகள் ஏற்றப்படுகின்றன...',
      'notifications.error': 'அறிவிப்புகளை ஏற்றுவதில் தோல்வி. தயவுசெய்து மீண்டும் முயற்சி செய்யவும்.',
      'notifications.noNotifications': 'அறிவிப்புகள் இல்லை',
      'notifications.noNewNotifications': 'உங்களுக்கு புதிய அறிவிப்புகள் இல்லை',
      'notifications.unknownCrop': 'தெரியாத பயிர்',
      'notifications.message': 'செய்தி',
      'notifications.ok': 'சரி',
      'notifications.removedSuccessfully': 'அறிவிப்பு வெற்றிகரமாக அகற்றப்பட்டது',
      'notifications.failedToRemove': 'அறிவிப்பை அகற்றுவதில் தோல்வி',
      'notifications.failedToOpen': 'அறிவிப்பைத் திறப்பதில் தோல்வி',
      'notifications.deleteConfirmation': 'இந்த அறிவிப்பை நிச்சயமாக நீக்க விரும்புகிறீர்களா?',
      'notifications.cancel': 'ரத்து செய்',
      'notifications.delete': 'நீக்கு',
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
    fetchNotifications();
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

  Future<void> fetchNotifications() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch notifications (returns List directly)
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false) as List<dynamic>;

      final notifs =
          response.map((e) => Map<String, dynamic>.from(e)).toList();

      // Process notifications to add crop names
      List<Map<String, dynamic>> formatted = [];

      for (var notif in notifs) {
        String cropName = t('notifications.unknownCrop');
        try {
          // Message notifications
          if (notif['type'] == 'message' && notif['related_id'] != null) {
            final messageResponse = await supabase
                .from('messages')
                .select('conversation_id')
                .eq('id', notif['related_id'])
                .maybeSingle();

            if (messageResponse != null &&
                messageResponse['conversation_id'] != null) {
              final conversationResponse = await supabase
                  .from('conversations')
                  .select('crop_id')
                  .eq('id', messageResponse['conversation_id'])
                  .maybeSingle();

              if (conversationResponse != null &&
                  conversationResponse['crop_id'] != null) {
                final produceResponse = await supabase
                    .from('produce')
                    .select('crop_name')
                    .eq('id', conversationResponse['crop_id'])
                    .maybeSingle();

                if (produceResponse != null &&
                    produceResponse['crop_name'] != null) {
                  cropName = produceResponse['crop_name'];
                }
              }
            }
          }

          // Order notifications
          if (notif['type'] == 'order' && notif['related_id'] != null) {
            final orderItems = await supabase
                .from('order_items')
                .select('crop_id')
                .eq('order_id', notif['related_id'])
                .limit(1) as List<dynamic>;

            if (orderItems.isNotEmpty) {
              final cropId = orderItems[0]['crop_id'];
              final produceResponse = await supabase
                  .from('produce')
                  .select('crop_name')
                  .eq('id', cropId)
                  .maybeSingle();

              if (produceResponse != null &&
                  produceResponse['crop_name'] != null) {
                cropName = produceResponse['crop_name'];
              }
            }
          }

          formatted.add({...notif, 'crop_name': cropName});
        } catch (e) {
          print('Error processing notification ${notif['id']}: $e');
          formatted.add({...notif, 'crop_name': t('notifications.unknownCrop')});
        }
      }

      if (mounted) {
        setState(() {
          notifications = formatted;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = t('notifications.error');
        });
      }
    }
  }

  Future<void> removeNotification(String id) async {
    if (isDeleting) return;

    if (mounted) {
      setState(() {
        isDeleting = true;
      });
    }

    try {
      // Delete notification
      await supabase
          .from('notifications')
          .delete()
          .eq('id', id);

      if (mounted) {
        setState(() {
          notifications.removeWhere((n) => n['id'].toString() == id);
          isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('notifications.removedSuccessfully')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting notification: $e');
      if (mounted) {
        setState(() {
          isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('notifications.failedToRemove')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void handlePress(Map<String, dynamic> item) {
    try {
      if (item['type'] == 'order') {
        Navigator.pushNamed(context, '/orderScreen');
      } else if (item['type'] == 'message') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t('notifications.message')),
            content:
                Text(item['message_content'] ?? item['body'] ?? t('notifications.noNewNotifications')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('notifications.ok')))
            ],
          ),
        );
      }
    } catch (e) {
      print('Error handling notification press: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t('notifications.failedToOpen')}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (e) {
      print('Error formatting date: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF6a11cb), Color(0xFF2575fc)])),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          const Icon(FeatherIcons.arrowLeft, color: Colors.white),
                    ),
                  ),
                  Text(
                    t('notifications.title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Error
            if (errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FeatherIcons.bellOff,
                                  size: 60, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                t('notifications.noNotifications'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t('notifications.noNewNotifications'),
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchNotifications,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final item = notifications[index];
                              final isOrder = item['type'] == 'order';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Header gradient
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isOrder
                                              ? [Color(0xFF4CAF50), Color(0xFF388E3C)]
                                              : [Color(0xFF2196F3), Color(0xFF1976D2)],
                                        ),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Icon(
                                                  isOrder
                                                      ? FeatherIcons.shoppingCart
                                                      : FeatherIcons.mail,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                item['title'] ?? t('notifications.title'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          GestureDetector(
                                            onTap: () => showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(t('notifications.delete')),
                                                content: Text(t('notifications.deleteConfirmation')),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: Text(t('notifications.cancel')),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      removeNotification(item['id'].toString());
                                                    },
                                                    child: Text(t('notifications.delete'), style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            child: const Icon(
                                              FeatherIcons.xCircle,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Content
                                    GestureDetector(
                                      onTap: () => handlePress(item),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        color: Colors.white,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  FeatherIcons.feather,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    item['crop_name'] ?? t('notifications.unknownCrop'),
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.green,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (item['type'] == 'message' &&
                                                item['message_content'] != null)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(vertical: 8),
                                                child: Text(
                                                  item['message_content'],
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.black87,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  FeatherIcons.clock,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  formatDateTime(item['created_at']),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}