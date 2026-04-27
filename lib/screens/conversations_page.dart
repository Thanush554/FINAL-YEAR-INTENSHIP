import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationList extends StatefulWidget {
  const ConversationList({super.key});

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> with WidgetsBindingObserver {
  final supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> conversations = [];
  bool loading = true;
  bool refreshing = false;
  String? userId;
  String? error;
  Timer? refreshTimer;
  DateTime lastRefresh = DateTime.now();
  bool _isDisposed = false;
  bool deleteMode = false;

  String _currentLanguage = 'en'; // Default to English

  static const refreshInterval = Duration(seconds: 30);
  static const placeholderImage =
      "https://via.placeholder.com/60x60.png?text=No+Image";

  final Map<String, Map<String, String>> translations = {
    'en': {
      'conversations.title': 'Conversations',
      'conversations.lastUpdated': 'Last updated',
      'conversations.noConversations': 'No conversations yet!',
      'conversations.startBrowsing': 'Start browsing crops to connect with retailers.',
      'conversations.browseCrops': 'Browse Crops',
      'conversations.retry': 'Retry',
      'conversations.loginAgain': 'Login Again',
      'conversations.userNotLoggedIn': 'User not logged in. Please log in again.',
      'conversations.failedInitialize': 'Failed to initialize user',
      'conversations.errorLoading': 'Error loading conversations',
      'conversations.unknownCrop': 'Unknown Crop',
      'conversations.unknownRetailer': 'Unknown Retailer',
      'conversations.noMessages': 'No messages yet',
      'conversations.yesterday': 'Yesterday',
      'conversations.delete': 'Delete',
      'conversations.deleteAll': 'Delete *',
      'conversations.deleteConfirmation': 'Are you sure you want to delete this conversation?',
      'conversations.deleteAllConfirmation': 'Are you sure you want to delete all conversations?',
      'conversations.deleteSuccess': 'Conversation deleted successfully',
      'conversations.deleteError': 'Error deleting conversation',
      'conversations.allDeleteSuccess': 'All conversations deleted successfully',
      'conversations.allDeleteError': 'Error deleting all conversations',
    },
    'kn': {
      'conversations.title': 'ಸಂವಾದಗಳು',
      'conversations.lastUpdated': 'ಕೊನೆಯ ಬಾರಿ ನವೀಕರಿಸಲಾಗಿದೆ',
      'conversations.noConversations': 'ಇನ್ನೂ ಯಾವುದೇ ಸಂವಾದಗಳಿಲ್ಲ!',
      'conversations.startBrowsing': 'ಚಿಲ್ಲರೆ ವ್ಯಾಪಾರಿಗಳೊಂದಿಗೆ ಸಂಪರ್ಕ ಸಾಧಿಸಲು ಬೆಳೆಗಳನ್ನು ವೀಕ್ಷಿಸಲು ಪ್ರಾರಂಭಿಸಿ.',
      'conversations.browseCrops': 'ಬೆಳೆಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
      'conversations.retry': 'ಮರುಪ್ರಯತ್ನಿಸಿ',
      'conversations.loginAgain': 'ಮತ್ತೆ ಲಾಗಿನ್ ಮಾಡಿ',
      'conversations.userNotLoggedIn': 'ಬಳಕೆದಾರ ಲಾಗಿನ್ ಆಗಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಲಾಗಿನ್ ಮಾಡಿ.',
      'conversations.failedInitialize': 'ಬಳಕೆದಾರರನ್ನು ಆರಂಭಿಸಲು ವಿಫಲವಾಗಿದೆ',
      'conversations.errorLoading': 'ಸಂವಾದಗಳನ್ನು ಲೋಡ್ ಮಾಡುವಲ್ಲಿ ದೋಷ',
      'conversations.unknownCrop': 'ತಿಳಿಯದ ಬೆಳೆ',
      'conversations.unknownRetailer': 'ತಿಳಿಯದ ಚಿಲ್ಲರೆ ವ್ಯಾಪಾರಿ',
      'conversations.noMessages': 'ಇನ್ನೂ ಸಂದೇಶಗಳಿಲ್ಲ',
      'conversations.yesterday': 'ನಿನ್ನೆ',
      'conversations.delete': 'ಅಳಿಸಿ',
      'conversations.deleteAll': 'ಎಲ್ಲವನ್ನೂ ಅಳಿಸಿ',
      'conversations.deleteConfirmation': 'ನೀವು ಈ ಸಂವಾದವನ್ನು ಅಳಿಸಲು ಖಚಿತವಾಗಿ ಬಯಸುವಿರಾ?',
      'conversations.deleteAllConfirmation': 'ನೀವು ಎಲ್ಲಾ ಸಂವಾದಗಳನ್ನು ಅಳಿಸಲು ಖಚಿತವಾಗಿ ಬಯಸುವಿರಾ?',
      'conversations.deleteSuccess': 'ಸಂವಾದವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ',
      'conversations.deleteError': 'ಸಂವಾದವನ್ನು ಅಳಿಸುವಲ್ಲಿ ದೋಷ',
      'conversations.allDeleteSuccess': 'ಎಲ್ಲಾ ಸಂವಾದಗಳನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ',
      'conversations.allDeleteError': 'ಎಲ್ಲಾ ಸಂವಾದಗಳನ್ನು ಅಳಿಸುವಲ್ಲಿ ದೋಷ',
    },
    'hi': {
      'conversations.title': 'बातचीत',
      'conversations.lastUpdated': 'आखिरी अपडेट',
      'conversations.noConversations': 'अभी तक कोई बातचीत नहीं!',
      'conversations.startBrowsing': 'खुदरा विक्रेताओं से जुड़ने के लिए फसलों को ब्राउज़ करना शुरू करें।',
      'conversations.browseCrops': 'फसलें ब्राउज़ करें',
      'conversations.retry': 'पुनः प्रयास करें',
      'conversations.loginAgain': 'फिर से लॉग इन करें',
      'conversations.userNotLoggedIn': 'उपयोगकर्ता लॉग इन नहीं है। कृपया फिर से लॉग इन करें।',
      'conversations.failedInitialize': 'उपयोगकर्ता को आरंभ करने में विफल',
      'conversations.errorLoading': 'बातचीत लोड करने में त्रुटि',
      'conversations.unknownCrop': 'अज्ञात फसल',
      'conversations.unknownRetailer': 'अज्ञात खुदरा विक्रेता',
      'conversations.noMessages': 'अभी तक कोई संदेश नहीं',
      'conversations.yesterday': 'कल',
      'conversations.delete': 'हटाएं',
      'conversations.deleteAll': 'सभी हटाएं',
      'conversations.deleteConfirmation': 'क्या आप वाकई इस बातचीत को हटाना चाहते हैं?',
      'conversations.deleteAllConfirmation': 'क्या आप वाकई सभी बातचीत हटाना चाहते हैं?',
      'conversations.deleteSuccess': 'बातचीत सफलतापूर्वक हटा दी गई',
      'conversations.deleteError': 'बातचीत हटाने में त्रुटि',
      'conversations.allDeleteSuccess': 'सभी बातचीत सफलतापूर्वक हटा दी गई',
      'conversations.allDeleteError': 'सभी बातचीत हटाने में त्रुटि',
    },
    'te': {
      'conversations.title': 'సంభాషణలు',
      'conversations.lastUpdated': 'చివరిగా నవీకరించబడినది',
      'conversations.noConversations': 'ఇంకా ఏ సంభాషణలు లేవు!',
      'conversations.startBrowsing': 'చిల్లర వ్యాపారులతో కనెక్ట్ అవ్వడానికి పంటలను బ్రౌజ్ చేయడం ప్రారంభించండి.',
      'conversations.browseCrops': 'పంటలను బ్రౌజ్ చేయండి',
      'conversations.retry': 'మళ్ళీ ప్రయత్నించండి',
      'conversations.loginAgain': 'మళ్ళీ లాగిన్ అవ్వండి',
      'conversations.userNotLoggedIn': 'వినియోగదారు లాగిన్ కాలేదు. దయచేసి మళ్ళీ లాగిన్ అవ్వండి.',
      'conversations.failedInitialize': 'వినియోగదారును ప్రారంభించడంలో విఫలమైంది',
      'conversations.errorLoading': 'సంభాషణలను లోడ్ చేయడంలో లోపం',
      'conversations.unknownCrop': 'తెలియని పంట',
      'conversations.unknownRetailer': 'తెలియని చిల్లర వ్యాపారి',
      'conversations.noMessages': 'ఇంకా సందేశాలు లేవు',
      'conversations.yesterday': 'నిన్న',
      'conversations.delete': 'తీసివేయి',
      'conversations.deleteAll': 'అన్నింటినీ తీసివేయి',
      'conversations.deleteConfirmation': 'మీరు ఖచ్చితంగా ఈ సంభాషణను తీసివేయాలనుకుంటున్నారా?',
      'conversations.deleteAllConfirmation': 'మీరు ఖచ్చితంగా అన్ని సంభాషణలను తీసివేయాలనుకుంటున్నారా?',
      'conversations.deleteSuccess': 'సంభాషణ విజయవంతంగా తీసివేయబడింది',
      'conversations.deleteError': 'సంభాషణను తీసివేయడంలో లోపం',
      'conversations.allDeleteSuccess': 'అన్ని సంభాషణలు విజయవంతంగా తీసివేయబడ్డాయి',
      'conversations.allDeleteError': 'అన్ని సంభాషణలను తీసివేయడంలో లోపం',
    },
    'ta': {
      'conversations.title': 'உரையாடல்கள்',
      'conversations.lastUpdated': 'கடைசியாக புதுப்பிக்கப்பட்டது',
      'conversations.noConversations': 'இதுவரை எந்த உரையாடல்களும் இல்லை!',
      'conversations.startBrowsing': 'சில்லறை வியாபாரிகளுடன் இணைக்க பயிர்களை உலாவத் தொடங்குங்கள்.',
      'conversations.browseCrops': 'பயிர்களை உலாவுங்கள்',
      'conversations.retry': 'மீண்டும் முயற்சி செய்யுங்கள்',
      'conversations.loginAgain': 'மீண்டும் உள்நுழைக',
      'conversations.userNotLoggedIn': 'பயனர் உள்நுழையவில்லை. தயவுசெய்து மீண்டும் உள்நுழைக.',
      'conversations.failedInitialize': 'பயனரைத் துவக்க முடியவில்லை',
      'conversations.errorLoading': 'உரையாடல்களை ஏற்றுவதில் பிழை',
      'conversations.unknownCrop': 'தெரியாத பயிர்',
      'conversations.unknownRetailer': 'தெரியாத சில்லறை வியாபாரி',
      'conversations.noMessages': 'இதுவரை செய்திகள் இல்லை',
      'conversations.yesterday': 'நேற்று',
      'conversations.delete': 'நீக்கு',
      'conversations.deleteAll': 'அனைத்தையும் நீக்கு',
      'conversations.deleteConfirmation': 'இந்த உரையாடலை நிச்சயமாக நீக்க விரும்புகிறீர்களா?',
      'conversations.deleteAllConfirmation': 'அனைத்து உரையாடல்களையும் நிச்சயமாக நீக்க விரும்புகிறீர்களா?',
      'conversations.deleteSuccess': 'உரையாடல் வெற்றிகரமாக நீக்கப்பட்டது',
      'conversations.deleteError': 'உரையாடலை நீக்குவதில் பிழை',
      'conversations.allDeleteSuccess': 'அனைத்து உரையாடல்களும் வெற்றிகரமாக நீக்கப்பட்டன',
      'conversations.allDeleteError': 'அனைத்து உரையாடல்களையும் நீக்குவதில் பிழை',
    },
  };

  String t(String key) {
    return translations[_currentLanguage]?[key] ?? translations['en']?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
    _loadLanguage();
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
    WidgetsBinding.instance.removeObserver(this);
    refreshTimer?.cancel();
    _scrollController.dispose();
    _isDisposed = true;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchConversations(isBackground: true);
    }
  }

  Future<void> _initializeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('flutter.userId');

      if (id == null) {
        final currentUser = supabase.auth.currentUser;
        if (currentUser != null) {
          await prefs.setString('flutter.userId', currentUser.id);
          setState(() => userId = currentUser.id);
        } else {
          if (_isDisposed) return;
          setState(() {
            error = t('conversations.userNotLoggedIn');
            loading = false;
          });
          return;
        }
      } else {
        setState(() => userId = id);
      }

      await _fetchConversations();

      refreshTimer =
          Timer.periodic(refreshInterval, (_) => _fetchConversations(isBackground: true));
    } catch (e) {
      print('Error initializing user: $e');
      if (_isDisposed) return;
      setState(() {
        error = "${t('conversations.failedInitialize')}: ${e.toString()}";
        loading = false;
      });
    }
  }

  Future<void> _fetchConversations({bool isBackground = false}) async {
    if (userId == null || _isDisposed) return;

    if (!isBackground) {
      if (_isDisposed) return;
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final conversationsRes = await supabase
          .from('conversations')
          .select('id, crop_id, retailer_id, created_at, crop:crop_id (crop_name, image_url), retailer:retailer_id (name)')
          .eq('farmer_id', userId!)
          .order('created_at', ascending: true);

      if (conversationsRes.isEmpty) {
        if (_isDisposed) return;
        setState(() {
          conversations = [];
          loading = false;
        });
        return;
      }

      final List<dynamic> conversationsData = conversationsRes;
      final conversationIds = conversationsData.map((c) => c['id']).toList();

      final lastMessages = await supabase
          .from('messages')
          .select('conversation_id, content, created_at')
          .inFilter('conversation_id', conversationIds)
          .order('created_at', ascending: false);

      final lastMessageMap = <String, Map<String, dynamic>>{};
      for (final msg in lastMessages) {
        final cid = msg['conversation_id']?.toString();
        if (cid != null && !lastMessageMap.containsKey(cid)) {
          lastMessageMap[cid] = msg;
        }
      }

      final unreadMessages = await supabase
          .from('messages')
          .select('conversation_id')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_id', userId!)
          .isFilter('read_at', null);

      final unreadIds = unreadMessages.map((m) => m['conversation_id']).toSet();

      final formatted = conversationsData.map((conv) {
        final convId = conv['id'].toString();
        final lastMsg = lastMessageMap[convId];

        return {
          'id': convId,
          'cropId': conv['crop_id'],
          'retailerId': conv['retailer_id'],
          'cropName': conv['crop']?['crop_name'] ?? t('conversations.unknownCrop'),
          'cropImage': conv['crop']?['image_url'] ?? placeholderImage,
          'retailerName': conv['retailer']?['name'] ?? t('conversations.unknownRetailer'),
          'lastMessage': lastMsg?['content'] ?? t('conversations.noMessages'),
          'lastMessageAt': lastMsg?['created_at'] ?? conv['created_at'],
          'hasUnread': unreadIds.contains(convId),
        };
      }).toList();

      formatted.sort((a, b) => DateTime.parse(b['lastMessageAt'])
          .compareTo(DateTime.parse(a['lastMessageAt'])));

      if (_isDisposed) return;
      setState(() {
        conversations = formatted.cast<Map<String, dynamic>>();
        lastRefresh = DateTime.now();
        loading = false;
        refreshing = false;
      });
    } catch (e) {
      print('Error fetching conversations: $e');
      if (_isDisposed) return;
      if (!isBackground) {
        setState(() {
          error = "${t('conversations.errorLoading')}: ${e.toString()}";
          loading = false;
          refreshing = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    if (refreshing) return;
    if (_isDisposed) return;
    setState(() => refreshing = true);
    await _fetchConversations();
  }

  void _openConversation(Map<String, dynamic> conversation) {
    Navigator.pushNamed(
      context,
      '/negotiation',
      arguments: {
        'conversationId': conversation['id'],
        'cropId': conversation['cropId'],
        'retailerId': conversation['retailerId'],
        'cropName': conversation['cropName'],
        'retailerName': conversation['retailerName'],
      },
    );
  }

  void _deleteConversation(String conversationId) async {
    try {
      await supabase.from('conversations').delete().eq('id', conversationId);
      setState(() {
        conversations.removeWhere((c) => c['id'] == conversationId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('conversations.deleteSuccess')),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('conversations.deleteError')),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _deleteAllConversations() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('conversations.deleteAll')),
        content: Text(t('conversations.deleteAllConfirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('conversations.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await supabase.from('conversations').delete().eq('farmer_id', userId!);
                setState(() {
                  conversations.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(t('conversations.allDeleteSuccess')),
                  backgroundColor: Colors.green,
                ));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(t('conversations.allDeleteError')),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: Text(t('conversations.deleteAll'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.tryParse(timestamp)?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    final diffHours = now.difference(date).inHours;
    if (diffHours < 24) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (diffHours < 48) {
      return t('conversations.yesterday');
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF25D366),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Text(
          t('conversations.title'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/farmerDashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            tooltip: t('conversations.deleteAll'),
            onPressed: _deleteAllConversations,
          ),
          IconButton(
            icon: refreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: refreshing ? null : _onRefresh,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "${t('conversations.lastUpdated')}: ${lastRefresh.hour}:${lastRefresh.minute.toString().padLeft(2, '0')}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
    } else if (error != null) {
      return Center(child: Text(error!));
    } else if (conversations.isEmpty) {
      return _buildEmptyState();
    } else {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF128C7E),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) =>
              _buildConversationCard(conversations[index]),
        ),
      );
    }
  }

  Widget _buildConversationCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _openConversation(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item['hasUnread'] ? const Color(0xFFF8F9FA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.network(
                item['cropImage'],
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['cropName'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(item['retailerName'],
                      style: const TextStyle(fontSize: 14, color: Color(0xFF128C7E))),
                  const SizedBox(height: 4),
                  Text(item['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteConversation(item['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.message_outlined, color: Color(0xFF25D366), size: 60),
            const SizedBox(height: 16),
            Text(
              t('conversations.noConversations'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              t('conversations.startBrowsing'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/farmerDashboard'),
              child: Text(
                t('conversations.browseCrops'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}