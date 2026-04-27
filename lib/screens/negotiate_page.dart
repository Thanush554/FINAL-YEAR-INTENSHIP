import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class NegotiationChatPage extends StatefulWidget {
  final String cropId;
  final String farmerId;
  final String retailerId;
  final String currentUserId;
  final String? cropName;
  final String? farmerName;
  final String? retailerName;

  const NegotiationChatPage({
    super.key,
    required this.cropId,
    required this.farmerId,
    required this.retailerId,
    required this.currentUserId,
    this.cropName,
    this.farmerName,
    this.retailerName,
  });

  @override
  State<NegotiationChatPage> createState() => _NegotiationChatPageState();
}

class _NegotiationChatPageState extends State<NegotiationChatPage> {
  // Constants
  static const String _translateGoogle =
      "https://translate.googleapis.com/translate_a/single";
  static const String _defaultBg = "assets/images/chatbg.jpeg";
  static const int _offlineQueueMax = 200;
  static const List<String> _supportedLanguages = ['en', 'hi', 'kn', 'te', 'ta'];

  // Supabase & TTS
  final SupabaseClient supabase = Supabase.instance.client;
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();

  // State variables
  List<types.Message> _messages = [];
  bool _loading = true;
  bool _isRecording = false;
  bool _voiceReady = false;
  bool _mute = false;
  String _speechStatusMessage = "";
  List<Map<String, dynamic>> _offlineQueue = [];
  String? _conversationId;
  String? _currentUserId;
  String _currentUserName = "User";
  String? _selectedLanguage;

  // Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _supabaseChannel;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _supabaseChannel?.unsubscribe();
    flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadOfflineQueue();
    await _detectLanguage();
    await _initUser();
    await _initSpeech();
    await _initTts();
  }

  Future<void> _loadOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueStr = prefs.getString("offlineQueueMessages");
      if (queueStr != null) {
        final List<dynamic> decoded = json.decode(queueStr);
        _offlineQueue = decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Offline queue load failed: $e");
    }
  }

  Future<void> _detectLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedLang = prefs.getString("selectedLanguage");
      if (storedLang != null && _supportedLanguages.contains(storedLang)) {
        _selectedLanguage = storedLang;
      } else {
        _selectedLanguage = 'en';
        await prefs.setString("selectedLanguage", 'en');
      }
    } catch (e) {
      print("Language detection failed: $e");
      _selectedLanguage = 'en';
    }
  }

  Future<void> _initUser() async {
    _currentUserId = widget.currentUserId;
    _currentUserName = widget.farmerName ?? "Farmer";
    await _getOrCreateConversation();
    await _setupRealtimeSubscription();
  }

  Future<void> _initSpeech() async {
    try {
      _voiceReady = await speech.initialize(
        onStatus: (status) {
          setState(() {
            _isRecording = status == 'listening';
            _speechStatusMessage = status == 'listening' ? "Listening..." : "";
          });
        },
        onError: (error) {
          setState(() {
            _isRecording = false;
            _voiceReady = false;
            _speechStatusMessage = "Speech error";
          });
          _showError("Speech Error", error.errorMsg);
        },
      );
    } catch (e) {
      _voiceReady = false;
      print("Speech init failed: $e");
    }
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setLanguage(_getLanguageCode(_selectedLanguage));
      await flutterTts.setSpeechRate(0.4);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(0.8);
    } catch (e) {
      print("TTS init failed: $e");
    }
  }

  String _getLanguageCode(String? lang) {
    switch (lang) {
      case 'kn':
        return 'kn-IN';
      case 'hi':
        return 'hi-IN';
      case 'te':
        return 'te-IN';
      case 'ta':
        return 'ta-IN';
      default:
        return 'en-US';
    }
  }

  Future<Map<String, dynamic>> _translateText(String text, String targetLang) async {
    if (text.isEmpty) return {'translatedText': "", 'detectedLanguage': null};
    try {
      final response = await http.get(
        Uri.parse(
            "$_translateGoogle?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = (data[0] as List).map<String>((p) => p[0].toString()).join();
        return {'translatedText': translatedText, 'detectedLanguage': data[2]?.toString()};
      }
    } catch (e) {
      print("Translation failed: $e");
    }
    return {'translatedText': text, 'detectedLanguage': null};
  }

  Future<void> _getOrCreateConversation() async {
    try {
      final response = await supabase
          .from('conversations')
          .select('id')
          .eq('crop_id', widget.cropId)
          .eq('farmer_id', widget.farmerId)
          .eq('retailer_id', widget.retailerId)
          .maybeSingle();

      if (response != null && response['id'] != null) {
        _conversationId = response['id'].toString();
      } else {
        final newConv = await supabase.from('conversations').insert({
          'crop_id': widget.cropId,
          'farmer_id': widget.farmerId,
          'retailer_id': widget.retailerId,
          'last_message': "Conversation started",
          'last_message_at': DateTime.now().toIso8601String(),
        }).select().single();

        _conversationId = newConv['id'].toString();
      }
    } catch (e) {
      _showError("Conversation Error", "Failed to create conversation: $e");
    }
  }

  Future<void> _fetchMessages() async {
    if (_conversationId == null) return;
    setState(() => _loading = true);
    try {
      final response = await supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', _conversationId!)
          .order('created_at', ascending: false);

      final formattedMessages = await Future.wait(response.map((m) async {
        String txt = m['content'] ?? "";
        if (_selectedLanguage != null && _selectedLanguage != 'en') {
          final result = await _translateText(txt, _selectedLanguage!);
          txt = result['translatedText'];
        }
        return types.TextMessage(
          id: m['id'].toString(),
          text: txt,
          author: types.User(
            id: m['sender_id'].toString(),
            firstName: m['sender_id'] == widget.farmerId
                ? widget.farmerName ?? "Farmer"
                : widget.retailerName ?? "Retailer",
          ),
          createdAt: DateTime.parse(m['created_at']).millisecondsSinceEpoch,
        );
      }));

      setState(() {
        _messages = formattedMessages;
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print("Fetch messages failed: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _setupRealtimeSubscription() async {
    if (_conversationId == null) return;
    await _fetchMessages();
    try {
      _supabaseChannel?.unsubscribe();
      _supabaseChannel = supabase.channel('messages_conv_$_conversationId');

      _supabaseChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: _conversationId!,
        ),
        callback: (payload) async {
          final newMessage = payload.newRecord;
          if (newMessage['sender_id'].toString() == widget.currentUserId) return;

          String text = newMessage['content'] ?? "";
          if (_selectedLanguage != null && _selectedLanguage != 'en') {
            final result = await _translateText(text, _selectedLanguage!);
            text = result['translatedText'];
          }

          final message = types.TextMessage(
            id: newMessage['id'].toString(),
            text: text,
            author: types.User(
              id: newMessage['sender_id'].toString(),
              firstName: newMessage['sender_id'] == widget.farmerId
                  ? widget.farmerName ?? "Farmer"
                  : widget.retailerName ?? "Retailer",
            ),
            createdAt: DateTime.parse(newMessage['created_at']).millisecondsSinceEpoch,
          );

          setState(() => _messages.insert(0, message));
          if (!_mute) _speakMessage(text);
          _scrollToBottom();
        },
      ).subscribe();
    } catch (e) {
      print("Realtime subscription failed: $e");
    }
  }

  Future<void> _speakMessage(String text) async {
    if (text.isEmpty || _mute) return;
    try {
      await flutterTts.stop();
      await flutterTts.setLanguage(_getLanguageCode(_selectedLanguage));
      await flutterTts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    if (_conversationId == null || _currentUserId == null || message.text.isEmpty) return;

    String txt = message.text;
    try {
      final result = await _translateText(txt, "en");
      txt = result['translatedText'];
    } catch (e) {
      print("Outgoing translation failed: $e");
    }

    try {
      await supabase.from('messages').insert({
        'conversation_id': _conversationId,
        'sender_id': _currentUserId!,
        'content': txt,
      });

      await supabase.from('conversations').update({
        'last_message': txt.length > 50 ? txt.substring(0, 50) : txt,
        'last_message_at': DateTime.now().toIso8601String(),
        'last_sender': _currentUserId,
      }).eq('id', _conversationId!);

      _textController.clear();
      await _fetchMessages();
    } catch (e) {
      _offlineQueue.add({
        'conversation_id': _conversationId,
        'sender_id': _currentUserId!,
        'content': txt,
      });
      if (_offlineQueue.length > _offlineQueueMax) _offlineQueue.removeAt(0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("offlineQueueMessages", json.encode(_offlineQueue));
      _showError("Offline", "Message queued locally and will be sent when connection restores.");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (!_voiceReady) return;
    if (_isRecording) {
      await speech.stop();
      setState(() => _isRecording = false);
    } else {
      await speech.listen(onResult: (result) {
        setState(() => _textController.text = result.recognizedWords);
      });
      setState(() => _isRecording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_defaultBg),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final prevMessage = index < _messages.length - 1
                                ? _messages[index + 1]
                                : null;
                            return _buildMessageBubble(
                              message,
                              showDateSeparator: _needsDateSeparator(message, prevMessage),
                            );
                          },
                        ),
                ),
                _buildInputToolbar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Widgets ===

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF128C7E), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2)
      ]),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.cropName ?? 'Negotiation',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(widget.retailerName ?? "Retailer",
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_mute ? Icons.volume_mute : Icons.volume_up,
                color: Colors.white),
            onPressed: () => setState(() => _mute = !_mute),
          ),
        ],
      ),
    );
  }

  Widget _buildInputToolbar() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        // CHANGE: Reduced vertical padding from 3 to 1.5 to decrease height
        // To decrease height further, reduce vertical padding below (currently 1.5)
        // To increase height, increase vertical padding value
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        // CHANGE: Reduced margin from 8 to 4 to decrease height
        // To decrease height further, reduce margin below (currently 4)
        // To increase height, increase margin value
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(_isRecording ? Icons.mic : Icons.mic_none,
                  color: _isRecording ? Colors.red : const Color(0xFF128C7E)),
              onPressed: _toggleRecording,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                // CHANGE: Added contentPadding with reduced vertical padding
                // To decrease height further, reduce vertical padding below (currently 8)
                // To increase height, increase vertical padding value
                decoration: InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                ),
                onSubmitted: (txt) =>
                    _handleSendPressed(types.PartialText(text: txt)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF128C7E)),
              onPressed: () {
                final txt = _textController.text.trim();
                if (txt.isNotEmpty) {
                  _handleSendPressed(types.PartialText(text: txt));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // === Message bubbles & helpers ===

  Widget _buildMessageBubble(types.Message message,
      {required bool showDateSeparator}) {
    if (message is! types.TextMessage) return const SizedBox.shrink();
    final isUser = message.author.id == widget.currentUserId;
    final timeText = _formatTime(message.createdAt);

    return Column(
      children: [
        if (showDateSeparator) _buildDateSeparator(_formatDate(message.createdAt)),
        GestureDetector(
          onTap: () => _speakMessage(message.text),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF128C7E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 1)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(message.text,
                          style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(timeText,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isUser
                                      ? Colors.white70
                                      : Colors.grey.shade600)),
                          if (isUser) const SizedBox(width: 4),
                          if (isUser)
                            const Icon(Icons.done_all,
                                size: 16, color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSeparator(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
          child: Text(text,
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  String _formatTime(int? ms) =>
      ms == null ? '' : DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ms));
  String _formatDate(int? ms) =>
      ms == null ? '' : DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));

  bool _needsDateSeparator(types.Message msg, types.Message? prev) {
    if (prev == null) return true;
    final c = DateTime.fromMillisecondsSinceEpoch(msg.createdAt!);
    final p = DateTime.fromMillisecondsSinceEpoch(prev.createdAt!);
    return c.day != p.day || c.month != p.month || c.year != p.year;
  }
}