import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:chatterly/data/services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _showScrollButton = false;
  bool _isListening = false;
  bool _speechEnabled = false;

  late AnimationController _fabAnimationController;
  late AnimationController _sendButtonController;
  late AnimationController _micAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _sendButtonRotation;
  late Animation<double> _micPulseAnimation;

  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();

    // Initialize animation controllers
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _sendButtonRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );

    _micPulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _micAnimationController, curve: Curves.easeInOut),
    );

    // Listen to scroll changes
    _scrollController.addListener(_onScroll);

    // Listen to text changes for send button animation
    _controller.addListener(() {
      if (_controller.text.trim().isNotEmpty) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    });
  }

  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status'); // Debug log
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false; // Fix: was setting to true
            });
            _micAnimationController.stop();
            _micAnimationController.reset();
            // Hide the listening snackbar
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        },
        onError: (error) {
          print('Speech error: ${error.errorMsg}'); // Debug log
          setState(() {
            _isListening = false;
          });
          _micAnimationController.stop();
          _micAnimationController.reset();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showErrorSnackBar("Speech recognition error: ${error.errorMsg}");
        },
      );
      setState(() {
        _speechEnabled = available;
      });
      print('Speech initialized: $available'); // Debug log
    } catch (e) {
      print('Speech initialization error: $e'); // Debug log
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _sendButtonController.dispose();
    _micAnimationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _speech.stop(); // Clean up speech
    super.dispose();
  }

  void _onScroll() {
    final isAtBottom =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 100;

    if (isAtBottom && _showScrollButton) {
      setState(() => _showScrollButton = false);
      _fabAnimationController.reverse();
    } else if (!isAtBottom && !_showScrollButton && _messages.isNotEmpty) {
      setState(() => _showScrollButton = true);
      _fabAnimationController.forward();
    }
  }

  String _cleanMessage(String text) {
    final regex = RegExp(r'\[.*?\]\((.*?)\)');
    return text.replaceAllMapped(regex, (match) => match.group(1) ?? text);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add haptic feedback
    HapticFeedback.lightImpact();

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _messages.add({
        "id": messageId,
        "role": "user",
        "text": text,
        "timestamp": DateTime.now(),
      });
      _isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final reply = await AIService.getResponse(text);
      final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();

      setState(() {
        _messages.add({
          "id": aiMessageId,
          "role": "ai",
          "text": "",
          "timestamp": DateTime.now(),
        });
        _isLoading = false;
      });

      _scrollToBottom();

      // Typewriter effect
      int aiIndex = _messages.length - 1;
      for (int i = 0; i < reply.length; i++) {
        await Future.delayed(const Duration(milliseconds: 12));
        if (!mounted) return;
        setState(() {
          _messages[aiIndex]["text"] = reply.substring(0, i + 1);
        });
        if (i % 10 == 0) _scrollToBottom(); // Scroll periodically during typing
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "role": "ai",
          "text": "Sorry, I encountered an error. Please try again.",
          "timestamp": DateTime.now(),
          "isError": true,
        });
        _isLoading = false;
      });
    }
  }

  void _startListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }

    // Check microphone permission
    var status = await Permission.microphone.status;
    if (status.isDenied) status = await Permission.microphone.request();
    if (status.isPermanentlyDenied || status.isDenied) return;

    if (!_speechEnabled) return;

    setState(() => _isListening = true);
    _micAnimationController.repeat(reverse: true);
    HapticFeedback.mediumImpact();

    _showListeningSnackBar();

    try {
      await _listenWithRetry();
    } catch (e) {
      print('Speech listening error: $e');
      await _stopListening();
    }
  }

  // Retry logic
  Future<void> _listenWithRetry() async {
    bool shouldRetry = true;

    while (_isListening && shouldRetry) {
      try {
        bool? started = await _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              shouldRetry = false;
              _stopListening();
            }
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          localeId: "en_US",
          cancelOnError: false, // prevents auto error
          listenMode: stt.ListenMode.dictation,
        );

        if (started != true) {
          // If failed to start, just retry silently
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          shouldRetry = false; // started successfully
        }
      } catch (e) {
        // If timeout occurs, silently retry
        print('Silent retry due to: $e');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
    _micAnimationController.stop();
    _micAnimationController.reset();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _showListeningSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text("🎤 Listening..."),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 30), // Long duration
        action: SnackBarAction(
          label: "Stop",
          textColor: Colors.white,
          onPressed: () {
            _stopListening();
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("Copied to clipboard"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isUser = message["role"] == "user";
    final isError = message["isError"] == true;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 50),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isError
                            ? const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                              )
                            : isUser
                            ? const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade100,
                                  Colors.grey.shade200,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isUser ? Colors.purple : Colors.grey)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isUser
                          ? Text(
                              message["text"] ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.4,
                              ),
                            )
                          : SelectableLinkify(
                              text: _cleanMessage(message["text"] ?? ""),
                              style: TextStyle(
                                color: isError ? Colors.white : Colors.black87,
                                fontSize: 16,
                                height: 1.4,
                              ),
                              linkStyle: TextStyle(
                                color: isError
                                    ? Colors.white
                                    : Colors.blue.shade700,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                              onOpen: (link) async {
                                try {
                                  String url = link.url.trim();
                                  if (!url.startsWith("http://") &&
                                      !url.startsWith("https://")) {
                                    url = "https://$url";
                                  }
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Could not open link"),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                  ),

                  // Action buttons for AI messages
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionButton(
                            icon: Icons.copy_rounded,
                            label: "Copy",
                            onPressed: () =>
                                _copyMessage(message["text"] ?? ""),
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            icon: Icons.share_rounded,
                            label: "Share",
                            onPressed: () => Share.share(message["text"] ?? ""),
                          ),
                        ],
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3 + (value * 0.7)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return AnimatedBuilder(
      animation: _micAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _micPulseAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: _isListening ? Colors.red.shade500 : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isListening
                    ? Colors.red.shade300
                    : Colors.grey.shade300,
              ),
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _speechEnabled ? _startListening : null,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: _isListening
                        ? Colors.white
                        : (_speechEnabled
                              ? Colors.grey.shade600
                              : Colors.grey.shade400),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Chatterly AI",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Voice Input Status"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Speech recognition: ${_speechEnabled ? 'Available' : 'Not Available'}",
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "• Tap the microphone button to start voice input",
                      ),
                      const Text(
                        "• Speak clearly and the text will appear in the input field",
                      ),
                      const Text("• Tap again to stop listening"),
                      const SizedBox(height: 12),
                      if (!_speechEnabled) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Text(
                            "Speech recognition is not available on this device or permission was denied.",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.help_outline, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Start a conversation!",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Type or use voice input to ask anything",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index], index);
                    },
                  ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Microphone button
                  _buildMicButton(),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: "Type or speak your message...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send button with rotation animation
                  AnimatedBuilder(
                    animation: _sendButtonRotation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _sendButtonRotation.value * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _sendMessage,
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isLoading
                                      ? Icons.hourglass_empty
                                      : Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating scroll-to-bottom button
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          onPressed: _scrollToBottom,
          backgroundColor: const Color(0xFF667eea),
          child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ),
      ),
    );
  }
}
