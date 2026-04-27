import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class NegotiationChat extends StatefulWidget {
  final String? conversationId;
  final String cropId;
  final String retailerId;
  final String cropName;
  final String retailerName;

  const NegotiationChat({
    super.key,
    this.conversationId,
    required this.cropId,
    required this.retailerId,
    this.cropName = "Crop Chat",
    this.retailerName = "Retailer",
  });

  @override
  _NegotiationChatState createState() => _NegotiationChatState();
}

class _NegotiationChatState extends State<NegotiationChat> with WidgetsBindingObserver {
  final SupabaseClient supabase = Supabase.instance.client;
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  final String _translateGoogle = "https://translate.googleapis.com/translate_a/single";

  List<types.Message> _messages = [];
  bool _loading = true;
  bool _isRecording = false;
  bool _mute = false;
  String? _conversationId;
  String? _farmerId;
  String _farmerName = "Farmer";
  String _currentLanguage = 'en'; // Default language
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _supabaseChannel;
  final Map<String, String> _translatedMessages = {}; // Cache for translated messages

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initChat();
  }

  Future<void> _initChat() async {
    if (widget.cropId.isEmpty || widget.retailerId.isEmpty) {
      _showAlert("Error", "Missing required conversation parameters");
      Navigator.pop(context);
      return;
    }
    await _loadLanguage();
    await _initUser();
    await _initSpeech();
    await _initTts();
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
    _supabaseChannel?.unsubscribe();
    flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ================== USER & CONVERSATION ==================
  Future<void> _initUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _farmerId = prefs.getString("userId");
      _farmerName = prefs.getString("userName") ?? "Farmer";
      await _getOrCreateConversation();
      await _setupRealtimeSubscription();
    } catch (e) {
      print("User init error: $e");
    }
  }

  Future<void> _getOrCreateConversation() async {
    if (_conversationId != null || _farmerId == null) return;
    try {
      final response = await supabase
          .from('conversations')
          .select('id')
          .eq('crop_id', widget.cropId)
          .eq('farmer_id', _farmerId!)
          .eq('retailer_id', widget.retailerId)
          .maybeSingle();

      if (response != null && response['id'] != null) {
        _conversationId = response['id'].toString();
        return;
      }

      final newConv = await supabase.from('conversations').insert({
        'crop_id': widget.cropId,
        'farmer_id': _farmerId!,
        'retailer_id': widget.retailerId,
        'last_message': "Conversation started",
        'last_message_at': DateTime.now().toIso8601String(),
      }).select().single();

      _conversationId = newConv['id'].toString();
    } catch (e) {
      print("Conversation creation error: $e");
    }
  }

  // ================== TRANSLATION ==================
  Future<String> _translateText(String text, String targetLanguage) async {
    if (text.isEmpty || targetLanguage == 'en') return text;
    
    // Check if we have this translation cached
    final cacheKey = '${text.hashCode}_$targetLanguage';
    if (_translatedMessages.containsKey(cacheKey)) {
      return _translatedMessages[cacheKey]!;
    }

    try {
      final response = await http.get(
        Uri.parse('$_translateGoogle?client=gtx&sl=auto&tl=$targetLanguage&dt=t&q=${Uri.encodeComponent(text)}'),
      );

      if (response.statusCode == 200) {
        // Parse the response
        final data = json.decode(response.body);
        // The response is a 2D array where the first element is an array of translations
        final translatedText = data[0][0][0];
        
        // Cache the translation
        _translatedMessages[cacheKey] = translatedText;
        
        return translatedText;
      } else {
        print('Translation failed: ${response.statusCode}');
        return text; // Return original text if translation fails
      }
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text if translation fails
    }
  }

  // ================== SPEECH & TTS ==================
  Future<void> _initSpeech() async {
    try {
      bool available = await speech.initialize(
        onStatus: (status) {
          setState(() => _isRecording = status == 'listening');
          if (status == 'done') _stopRecording();
        },
        onError: (error) {
          setState(() => _isRecording = false);
          _showAlert("Speech Error", error.errorMsg);
        },
      );
    } catch (e) {
      print("Speech init error: $e");
    }
  }

  Future<void> _stopRecording() async {
    await speech.stop();
    setState(() => _isRecording = false);
  }

  Future<void> _initTts() async {
    try {
      // Set TTS language based on current language
      String ttsLanguage = 'en-US';
      switch (_currentLanguage) {
        case 'kn':
          ttsLanguage = 'kn-IN';
          break;
        case 'hi':
          ttsLanguage = 'hi-IN';
          break;
        case 'te':
          ttsLanguage = 'te-IN';
          break;
        case 'ta':
          ttsLanguage = 'ta-IN';
          break;
        default:
          ttsLanguage = 'en-US';
      }
      
      await flutterTts.setLanguage(ttsLanguage);
      await flutterTts.setSpeechRate(0.4);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(0.8);
    } catch (e) {
      print("TTS init error: $e");
    }
  }

  Future<void> _speakMessage(String text) async {
    if (text.isEmpty || _mute) return;
    
    // Translate the text before speaking if needed
    String textToSpeak = text;
    if (_currentLanguage != 'en') {
      textToSpeak = await _translateText(text, _currentLanguage);
    }
    
    await flutterTts.stop();
    await flutterTts.speak(textToSpeak);
  }

  // ================== MESSAGES ==================
  Future<void> _fetchMessages() async {
    if (_conversationId == null) return;
    setState(() => _loading = true);
    try {
      final response = await supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', _conversationId!)
          .order('created_at', ascending: false);

      List<types.Message> formattedMessages = [];
      for (var m in response ?? []) {
        String txt = m['content'] ?? "";
        formattedMessages.add(types.TextMessage(
          id: m['id'].toString(),
          text: txt,
          author: types.User(
              id: m['sender_id'].toString(),
              firstName: m['sender_id'] == _farmerId ? _farmerName : widget.retailerName),
          createdAt: DateTime.parse(m['created_at']).millisecondsSinceEpoch,
        ));
      }

      setState(() {
        _messages = formattedMessages;
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print("Fetch messages error: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _setupRealtimeSubscription() async {
    if (_conversationId == null) return;
    await _fetchMessages();
    try {
      final channelName = 'messages_conv_$_conversationId';
      _supabaseChannel = supabase.channel(channelName);
      _supabaseChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: _conversationId!),
        callback: (_) => _fetchMessages(),
      ).subscribe();
    } catch (e) {
      print("Supabase subscription error: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    if (_conversationId == null || _farmerId == null || message.text.isEmpty) return;
    String txt = message.text;

    try {
      await supabase.from('messages').insert({
        'conversation_id': _conversationId,
        'sender_id': _farmerId!,
        'content': txt,
      });
      _textController.clear();
    } catch (e) {
      _showAlert("Error", "Message sending failed: $e");
    }
  }

  String _formatTime(int? milliseconds) {
    if (milliseconds == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return DateFormat('HH:mm').format(date);
  }

  Widget _buildMessageBubble(types.Message message) {
    if (message is! types.TextMessage) return SizedBox.shrink();
    final isUser = message.author.id == _farmerId;
    final timeText = _formatTime(message.createdAt);

    // CHANGE: Translate both sender and receiver messages to current language
    // Previously, only receiver messages were translated to English
    // Now all messages are translated to the user's selected language
    return FutureBuilder<String>(
      future: _translateText(message.text, _currentLanguage),
      builder: (context, snapshot) {
        final displayText = snapshot.data ?? message.text;
        
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => _speakMessage(message.text),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF128C7E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 50),
                    child: Text(
                      displayText,
                      style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 16),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Text(
                      timeText,
                      style: TextStyle(
                          color: isUser ? Colors.white70 : Colors.black45,
                          fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: Color(0xFF128C7E),
      child: Row(
        children: [
          IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            child: Text(widget.retailerName.isNotEmpty
                ? widget.retailerName[0]
                : 'R',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.retailerName,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(widget.cropName,
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
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
        // CHANGE: Reduced vertical padding and margin to decrease input height
        // To decrease height further, reduce vertical padding below (currently 3)
        // To increase height, increase vertical padding value
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        // CHANGE: Reduced bottom margin to decrease overall height
        // To decrease height further, reduce bottom margin below (currently 4)
        // To increase height, increase bottom margin value
        margin: EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 1,
                offset: Offset(0, -1))
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(_isRecording ? Icons.mic : Icons.mic_none,
                  color: _isRecording ? Colors.red : Color(0xFF128C7E),
                  size: 28),
              onPressed: () async {
                if (_isRecording) {
                  await _stopRecording();
                } else {
                  bool available = await speech.initialize();
                  if (available) {
                    await speech.listen(
                      onResult: (result) {
                        setState(() {
                          _textController.text = result.recognizedWords;
                          _textController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _textController.text.length));
                        });
                      },
                      listenFor: Duration(seconds: 30),
                      pauseFor: Duration(seconds: 5),
                    );
                    setState(() => _isRecording = true);
                  }
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  // CHANGE: Reduced vertical padding to decrease input height
                  // To decrease height further, reduce vertical padding below (currently 8)
                  // To increase height, increase vertical padding value
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Color(0xFF128C7E)),
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  _handleSendPressed(types.PartialText(text: text));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAlert(String title, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$title: $msg")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/chatbg.jpeg'),
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
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message);
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
}