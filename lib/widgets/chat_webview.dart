import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/message.dart';

class ChatWebView extends StatefulWidget {
  final List<Message> messages;

  const ChatWebView({super.key, required this.messages});

  @override
  State<ChatWebView> createState() => _ChatWebViewState();
}

class _ChatWebViewState extends State<ChatWebView> {
  WebViewController? _controller;
  bool _isReady = false;
  List<Message> _renderedMessages = [];

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final htmlContent =
        await rootBundle.loadString('assets/web/chat.html');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _isReady = true);
            _renderExistingMessages();
          },
        ),
      )
      ..loadHtmlString(htmlContent);

    setState(() {});
  }

  void _renderExistingMessages() {
    for (final msg in _renderedMessages) {
      _appendMessage(msg);
    }
  }

  @override
  void didUpdateWidget(ChatWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isReady && _controller != null) {
      // Render new messages that haven't been rendered yet
      for (final msg in widget.messages) {
        if (!_renderedMessages.contains(msg)) {
          _appendMessage(msg);
          _renderedMessages.add(msg);
        }
      }
    } else {
      _renderedMessages = List.from(widget.messages);
    }
  }

  void _appendMessage(Message msg) {
    if (_controller == null) return;
    final escapedContent = msg.content
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
    _controller!.runJavaScript("addMessage('$escapedContent', '${msg.role}')");
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: _controller!);
  }
}
