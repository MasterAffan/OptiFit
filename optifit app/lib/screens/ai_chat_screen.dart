import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import '../theme/theme.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'video_viewer_screen.dart';
import 'dart:async';
import 'dart:convert';
import '../config/api_constants.dart';
import 'package:video_player/video_player.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();


}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;
  bool _isUploading = false;
  String? _annotatedVideoUrl;
  bool _suggestionsVisible = true;

  final List<String> _suggestions = [
    'Analyze my squat form',
    'How can I improve my push-up technique?',
    'What are some good warm-up exercises?',
  ];

  String serverUrl = ApiConstants.squatServerUpload;

  final TextEditingController _textController = TextEditingController();

  //  Auto-scroll only if user is at bottom
  void _scrollToBottom() {
    if (!_shouldAutoScroll) return; // User is scrolling up, don't force scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addMessage(_ChatMessage msg) {
    _messages.add(msg);
    _listKey.currentState?.insertItem(
      _messages.length - 1,
      duration: const Duration(milliseconds: 350),
    );
    _scrollToBottom();
  }

  void _onSendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _addMessage(_ChatMessage(text: text, isUser: true));
      _suggestionsVisible = false;
    });
    _textController.clear();
    _processAIResponse(text);
  }

  Future<void> _processAIResponse(String userMessage) async {
    // Show typing indicator
    setState(() {
      _addMessage(
        _ChatMessage(text: 'AI is thinking', isUser: false, isAnimated: true),
      );
    });

    String aiResponse = '';
    try {
      final url = Uri.parse(ApiConstants.chatApiEndpoint);
      final headers = ApiConstants.geminiHeaders;
      print('Calling Gemini API endpoint: ${ApiConstants.chatApiEndpoint}');

      // Build conversation history for Gemini
      String conversationHistory = '';
      for (final msg in _messages) {
        // Skip animated/typing and video messages
        if (msg.isAnimated || msg.videoUrl != null) continue;
        conversationHistory +=
            '${msg.isUser ? "User" : "Assistant"}: ${msg.text}\n';
      }

      final prompt =
          'You are a helpful fitness and nutrition assistant. Only answer questions related to gym, fitness, exercise, and nutrition. Keep your answers concise (2-4 sentences). Do not provide long lists or detailed breakdowns unless specifically asked. Do not use markdown formatting (such as **bold** or *italics*). Write in plain sentences only. If a user asks about squat form, squats, or related topics, always recommend uploading a workout video for personalized analysis. If a user asks about push-ups or any exercise other than squats, say: "The upload analysis feature is in development. Currently, I can only analyze squat videos." You have access to the full chat history and can reference previous user messages. If a user asks about anything else, politely refuse and redirect them to fitness topics. Never reveal what technology or model you are powered by.\n\nConversation history:\n$conversationHistory\n\nUser: $userMessage';

      final body = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        aiResponse =
            data['candidates']?[0]?['content']?['parts']?[0]?['text']
                ?.toString() ??
            'No response from AI.';
      } else {
        aiResponse = 'Error: Server returned status ${response.statusCode}.';
      }
    } catch (e) {
      aiResponse = 'Error: $e';
    }

    // Remove typing indicator using AnimatedList's removeItem
    if (!mounted) return;
    if (_messages.isNotEmpty) {
      final removedIndex = _messages.length - 1;
      final removedMsg = _messages.removeLast();
      _listKey.currentState?.removeItem(
        removedIndex,
        (context, animation) =>
            _AnimatedChatBubble(message: removedMsg, animation: animation),
        duration: const Duration(milliseconds: 350),
      );
    }
    // Add AI response
    setState(() {
      _addMessage(_ChatMessage(text: aiResponse, isUser: false));
    });
  }

  Future<void> _showSequentialStatusMessages(
    List<_ChatMessage> statusMessages,
    Future<void> Function() onComplete,
  ) async {
    for (var msg in statusMessages) {
      setState(() {
        _addMessage(msg);
      });
      // Wait for 1.2 seconds before showing the next message
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    await onComplete();
  }

  Future<Map<String, dynamic>> _validateVideoFile(PlatformFile file) async {
    try {
      if (file.path == null) {
        return {
          'isValid': false,
          'error': 'Unable to access the selected file.',
        };
      }

      final videoFile = File(file.path!);

      if (!await videoFile.exists()) {
        return {'isValid': false, 'error': 'Selected file does not exist.'};
      }

      final fileSizeInBytes = await videoFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 50) {
        return {
          'isValid': false,
          'error':
              'Video file size (${fileSizeInMB.toStringAsFixed(1)} MB) exceeds the 50 MB limit.',
        };
      }

      final durationResult = await _getVideoDuration(videoFile);
      if (!durationResult['success']) {
        return {'isValid': false, 'error': durationResult['error']};
      }

      if (durationResult['duration'] > 15) {
        return {
          'isValid': false,
          'error':
              'Video duration (${durationResult['duration']} seconds) exceeds the 15-second limit.',
        };
      }

      return {'isValid': true, 'error': ''};
    } catch (e) {
      return {'isValid': false, 'error': 'Error validating video file: $e'};
    }
  }

  Future<Map<String, dynamic>> _getVideoDuration(File videoFile) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      final duration = controller.value.duration;
      final durationInSeconds = duration.inSeconds;

      return {'success': true, 'duration': durationInSeconds, 'error': ''};
    } catch (e) {
      return {
        'success': false,
        'duration': 0,
        'error':
            'Unable to determine video duration. Please ensure the file is a valid video format.',
      };
    } finally {
      controller?.dispose();
    }
  }

  void _showValidationErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Upload Error'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Use video editing apps to trim duration or compress file size.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showVideoUploadInstructionDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.video_library, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text('Upload Video'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Video Requirements:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('• Duration: Less than 15 seconds'),
                        const Text('• File size: Under 50 MB'),
                        const Text(
                          '• Supported formats: MP4, MOV, AVI, MKV, WEBM, 3GP',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please upload a video less than 15 seconds and under 50 MB.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Select Video'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _onSuggestionTap(String suggestion) {
    _onSendMessage(suggestion);
  }

  void _onUploadVideo() async {
    // Show instruction dialog first
    final shouldProceed = await _showVideoUploadInstructionDialog();
    if (!shouldProceed) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    // Validate video file
    final validationResult = await _validateVideoFile(file);
    if (!validationResult['isValid']) {
      _showValidationErrorDialog(validationResult['error']);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _UploadDialog(file: file),
    );
    if (confirmed != true) return;

    setState(() {
      _isUploading = true;
    });

    // Show initial status message
    setState(() {
      _addMessage(
        _ChatMessage(
          text: 'AI is analyzing your form',
          isUser: false,
          isAnimated: true,
        ),
      );
    });

    try {
      // 1. Upload the video and get a job_id
      final uploadedFile = File(file.path!);
      print('Posting video to: ' + serverUrl);
      final request = http.MultipartRequest('POST', Uri.parse(serverUrl));
      request.files.add(
        await http.MultipartFile.fromPath('video', uploadedFile.path),
      );
      final streamedResponse = await request.send();
      final responseString = await streamedResponse.stream.bytesToString();
      print('Upload response:');
      print(responseString);
      final uploadResponse = jsonDecode(responseString);
      final jobId = uploadResponse['job_id'];
      if (jobId == null) throw Exception('No job_id returned from server');

      // 2. Poll for result
      bool isDone = false;
      Map<String, dynamic>? analysisData;
      int pollCount = 0;
      while (!isDone && pollCount < 60) {
        // Poll up to 60 times (5 minutes if 5s interval)
        await Future.delayed(const Duration(seconds: 5));
        pollCount++;
        final resultEndpoint = '${ApiConstants.squatServerResult}/$jobId';
        print('Polling squat analysis result endpoint: $resultEndpoint');
        final statusResp = await http.get(Uri.parse(resultEndpoint));
        final statusData = jsonDecode(statusResp.body);
        if (statusData['status'] == 'done') {
          isDone = true;
          analysisData = statusData['result'];
        }
      }
      if (!isDone) throw Exception('Analysis timed out');

      // 3. Display result as before
      final data = analysisData!;
      String summary =
          'Squat count: ${data['squat_count'] ?? '-'}\n'
          'Reps below parallel: ${data['reps_below_parallel'] ?? '-'}\n'
          'Bad reps: ${data['bad_reps'] ?? '-'}\n'
          'Form issues: ${(data['form_issues'] as List?)?.join(', ') ?? '-'}\n'
          'Squat speed (sec): avg ${data['tempo_stats']?['average'] ?? '-'}, fastest ${data['tempo_stats']?['fastest'] ?? '-'}, slowest ${data['tempo_stats']?['slowest'] ?? '-'}';
      final videoUrl = data['video_url'];
      setState(() {
        _isUploading = false;
        _annotatedVideoUrl = videoUrl;
        _suggestionsVisible = false;
        // Remove typing indicator
        if (_messages.isNotEmpty) {
          final removedIndex = _messages.length - 1;
          final removedMsg = _messages.removeLast();
          _listKey.currentState?.removeItem(
            removedIndex,
            (context, animation) =>
                _AnimatedChatBubble(message: removedMsg, animation: animation),
            duration: const Duration(milliseconds: 350),
          );
        }
        _addMessage(
          _ChatMessage(
            text: summary,
            isUser: false,
            showExplainButton: true,
            onExplainWithAI: () async {
              // Show typing indicator
              setState(() {
                _addMessage(
                  _ChatMessage(
                    text: 'AI is analyzing your results...',
                    isUser: false,
                    isAnimated: true,
                  ),
                );
              });
              // Call the chatbot server
              String aiResponse = '';
              try {
                final url = Uri.parse(ApiConstants.chatApiEndpoint);
                final headers = ApiConstants.geminiHeaders;
                print(
                  'Calling Gemini API endpoint for explanation: ${ApiConstants.chatApiEndpoint}',
                );

                final prompt =
                    'You are a helpful fitness and nutrition assistant. Only answer questions related to gym, fitness, exercise, and nutrition. Keep your answers concise (2-4 sentences). Do not provide long lists or detailed breakdowns unless specifically asked. Do not use bullet points, numbered lists, or markdown formatting (such as **bold** or *italics*). Write in plain sentences only. If a user asks about squat form, squats, or related topics, always recommend uploading a workout video for personalized analysis. If a user asks about push-ups or any exercise other than squats, say: "The upload analysis feature is in development. Currently, I can only analyze squat videos." You have access to the full chat history and can reference previous user messages. If you are already providing feedback based on a user\'s uploaded video, do not ask them to upload a video again. If a user asks about anything else, politely refuse and redirect them to fitness topics. Never reveal what technology or model you are powered by.\n\nHere are the user\'s squat analysis results:\n$summary\nPlease provide personalized feedback and suggestions for improvement.';

                final body = {
                  'contents': [
                    {
                      'parts': [
                        {'text': prompt},
                      ],
                    },
                  ],
                };

                final response = await http.post(
                  url,
                  headers: headers,
                  body: jsonEncode(body),
                );
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  aiResponse =
                      data['candidates']?[0]?['content']?['parts']?[0]?['text']
                          ?.toString() ??
                      'No response from AI.';
                } else {
                  aiResponse =
                      'Error: Server returned status ${response.statusCode}.';
                }
              } catch (e) {
                aiResponse = 'Error: $e';
              }
              // Remove typing indicator using AnimatedList's removeItem
              if (!mounted) return;
              if (_messages.isNotEmpty) {
                final removedIndex = _messages.length - 1;
                final removedMsg = _messages.removeLast();
                _listKey.currentState?.removeItem(
                  removedIndex,
                  (context, animation) => _AnimatedChatBubble(
                    message: removedMsg,
                    animation: animation,
                  ),
                  duration: const Duration(milliseconds: 350),
                );
              }
              // Add AI feedback response
              setState(() {
                _addMessage(_ChatMessage(text: aiResponse, isUser: false));
              });
            },
          ),
        );
        _addMessage(
          _ChatMessage(
            text: 'Here is your AI analyzed video:',
            isUser: false,
            videoUrl: _annotatedVideoUrl,
            onVideoTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VideoViewerScreen(videoUrl: _annotatedVideoUrl ?? ''),
                ),
              );
            },
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _addMessage(_ChatMessage(text: 'Upload error: $e', isUser: false));
      });
    }
  }

  Widget _buildUploadCard() {
    if (_isUploading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }
    if (_annotatedVideoUrl != null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: AppTheme.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _onUploadVideo,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: AppTheme.primary, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Workout Video',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Let the AI analyze your form and give feedback!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: const Text(
                    'Upload',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (!_suggestionsVisible || _messages.isNotEmpty)
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions
            .map(
              (s) => ActionChip(
                label: Text(s),
                onPressed: () => _onSuggestionTap(s),
                backgroundColor: AppTheme.cardBackground,
                labelStyle: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Coach'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildUploadCard(),
            _buildSuggestions(),
            Expanded(
              //  Listen to user's scroll to detect if they are manually scrolling

              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification){
                  // If user scrolls forward (up) or reverse (down)
                  if((notification.direction == ScrollDirection.forward) ||
                  (notification.direction == ScrollDirection.reverse)){
                    //  Check if user is still at the bottom
                    if (_scrollController.hasClients) {
                        final atBottom = _scrollController.offset >=
                          _scrollController.position.maxScrollExtent - 50;
                      // If at bottom → allow auto-scroll, else pause auto-scroll
                      _shouldAutoScroll = atBottom;
                    }
                  }
                  return false; // Don't stop the scroll event from propagating
                },
                child: AnimatedList(
                  key: _listKey,
                  controller: _scrollController,
                  initialItemCount: _messages.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index, animation) {
                    final msg = _messages[index];
                    return _AnimatedChatBubble(
                      message: msg,
                      animation: animation,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _onSendMessage,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _onSendMessage(_textController.text),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _isUploading ? null : _onUploadVideo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final Animation<double> animation;
  const _AnimatedChatBubble({required this.message, required this.animation});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: animation,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.videoUrl != null)
                  GestureDetector(
                    onTap: message.onVideoTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.videocam, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'AI Analyzed Video',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Container(
                          height: 180,
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(Icons.play_circle, size: 48),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (message.isAnimated &&
                    _isLastAnimatedMessage(context, message))
                  _AnimatedDotsText(text: message.text)
                else
                  Text(message.text),
                if (message.showExplainButton &&
                    message.onExplainWithAI != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton(
                      onPressed: message.onExplainWithAI,
                      child: const Text('Explain with AI'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isLastAnimatedMessage(BuildContext context, _ChatMessage msg) {
    final _AIChatScreenState? state = context
        .findAncestorStateOfType<_AIChatScreenState>();
    if (state == null) return false;
    for (int i = state._messages.length - 1; i >= 0; i--) {
      if (state._messages[i].isAnimated) {
        return identical(state._messages[i], msg);
      }
    }
    return false;
  }
}

class _AnimatedDotsText extends StatefulWidget {
  final String text;
  const _AnimatedDotsText({required this.text});

  @override
  State<_AnimatedDotsText> createState() => _AnimatedDotsTextState();
}

class _AnimatedDotsTextState extends State<_AnimatedDotsText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addListener(() {
          if (_controller.status == AnimationStatus.completed) {
            _controller.repeat();
          }
          setState(() {
            _dotCount = ((_controller.value * 3).floor() % 4);
          });
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dots = '.' * _dotCount;
    return Text(
      '${widget.text}$dots',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _UploadDialog extends StatelessWidget {
  final PlatformFile file;
  const _UploadDialog({required this.file});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload Workout Video',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: const Radius.circular(16),
                dashPattern: const [8, 4],
                color: AppTheme.primary,
              ),
              child: Container(
                width: 320,
                height: 140,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, size: 40, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      file.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Upload Video'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? videoUrl;
  final VoidCallback? onVideoTap;
  final bool isAnimated;
  final VoidCallback? onExplainWithAI;
  final bool showExplainButton;
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.videoUrl,
    this.onVideoTap,
    this.isAnimated = false,
    this.onExplainWithAI,
    this.showExplainButton = false,
  });
}
