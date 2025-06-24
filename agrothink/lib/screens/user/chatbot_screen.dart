import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrothink/config/constants.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/models/chatbot_message_model.dart';
import 'package:agrothink/providers/chatbot_provider.dart';
import 'package:agrothink/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  ChatbotScreenState createState() => ChatbotScreenState();
}

class ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 300) {
      if (!_showScrollToBottom) {
        setState(() {
          _showScrollToBottom = true;
        });
      }
    } else {
      if (_showScrollToBottom) {
        setState(() {
          _showScrollToBottom = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: AppConstants.chatbotTitle),
      body: Consumer<ChatbotProvider>(
        builder: (context, chatbotProvider, child) {
          final isLoading = chatbotProvider.status == ChatbotStatus.loading;

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          return Column(
            children: [
              _buildChatHeader(),
              Expanded(child: _buildMessageList(chatbotProvider)),
              if (chatbotProvider.errorMessage != null &&
                  chatbotProvider.status == ChatbotStatus.error)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            chatbotProvider.errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.errorColor,
                            size: 18,
                          ),
                          onPressed: () {
                            chatbotProvider.clearError();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              _buildInputArea(chatbotProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Agriculture Assistant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ask me anything about farming',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLightColor,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textColor),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearChatDialog(context);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppTheme.textColor),
                        SizedBox(width: 8),
                        Text('Clear Chat'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatbotProvider chatbotProvider) {
    final messages = chatbotProvider.messages;

    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Start a conversation with the AI assistant.',
          style: TextStyle(color: AppTheme.textLightColor),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          chatbotProvider.status != ChatbotStatus.receiving) {
        const double scrollThreshold =
            100.0; // If user is within 100px of the bottom
        if (_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <=
            scrollThreshold) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 20, bottom: 30),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final showTimestamp =
                index == 0 ||
                message.timestamp.day != messages[index - 1].timestamp.day;

            return Column(
              children: [
                if (showTimestamp) _buildDateDivider(message.timestamp),
                _buildMessageBubble(message),
              ],
            );
          },
        ),
        if (_showScrollToBottom)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.arrow_downward, color: Colors.white),
            ),
          ),
        if (chatbotProvider.isTyping)
          Positioned(bottom: 0, left: 24, child: _buildTypingIndicator()),
      ],
    );
  }

  Widget _buildDateDivider(DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
          const SizedBox(width: 12),
          Text(
            _formatDateHeader(timestamp),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textLightColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatbotMessageModel message) {
    final bool isUserMessage = message.sender == MessageSender.user;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUserMessage) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isUserMessage
                        ? AppTheme.primaryColor
                        : AppTheme.chatBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      isUserMessage
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                  bottomRight:
                      isUserMessage
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: _FormattedText(
                text: message.message,
                isUserMessage: isUserMessage,
              ),
            ),
          ),
          if (isUserMessage) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: AppTheme.accentColor,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          _DotPulse(),
          SizedBox(width: 5),
          _DotPulse(delay: 0.2),
          SizedBox(width: 5),
          _DotPulse(delay: 0.4),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatbotProvider chatbotProvider) {
    final isSending =
        chatbotProvider.status == ChatbotStatus.sending ||
        chatbotProvider.status == ChatbotStatus.receiving;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Type your question...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppTheme.textLightColor),
                      ),
                      enabled: !isSending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty) {
                          _sendMessage(chatbotProvider);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.mic_none_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed:
                        isSending
                            ? null
                            : () {
                              // In a real app, implement voice input
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Voice input would be implemented here',
                                  ),
                                ),
                              );
                            },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isSending ? Icons.hourglass_top : Icons.send,
                color: Colors.white,
              ),
              onPressed: isSending ? null : () => _sendMessage(chatbotProvider),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ChatbotProvider chatbotProvider) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear input field
    _messageController.clear();
    // Send message
    chatbotProvider.sendMessage(text);
    // Make sure keyboard stays open
    _focusNode.requestFocus();
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
            'Are you sure you want to delete all messages in this chat?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Clear',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onPressed: () {
                Provider.of<ChatbotProvider>(
                  context,
                  listen: false,
                ).clearChat();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _DotPulse extends StatefulWidget {
  final double delay;

  const _DotPulse({this.delay = 0.0});

  @override
  _DotPulseState createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }

    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _FormattedText extends StatelessWidget {
  final String text;
  final bool isUserMessage;

  const _FormattedText({required this.text, required this.isUserMessage});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (i.isEven) {
        spans.add(TextSpan(text: parts[i]));
      } else {
        spans.add(
          TextSpan(
            text: parts[i],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isUserMessage ? Colors.white : AppTheme.textColor,
          fontSize: 15,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }
}
