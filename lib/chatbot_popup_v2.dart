import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'chatbot_config.dart';
import 'chatbot_widget_host.dart';

/// Script/iframe integration using deliberately invalid test credentials.
class ChatbotPopupV2 extends StatefulWidget {
  const ChatbotPopupV2({super.key});

  @override
  State<ChatbotPopupV2> createState() => _ChatbotPopupV2State();
}

class _ChatbotPopupV2State extends State<ChatbotPopupV2> {
  bool _isFullscreen = false;
  bool _isClosing = false;
  bool _isLoading = true;
  bool _hasError = false;
  int _reloadVersion = 0;
  int _refreshCount = 0;

  void _close() {
    if (!mounted || _isClosing) return;
    _isClosing = true;
    Navigator.of(context).pop();
  }

  Future<bool> _isHost(InAppWebViewController controller) async {
    final url = await controller.getUrl();
    return mounted &&
        !_isClosing &&
        url?.origin == chatbotOrigin &&
        url?.path == '/flutter-chatbot-v2';
  }

  void _registerBridge(InAppWebViewController controller) {
    for (final name in [
      'getToken',
      'onTokenRefresh',
      'getLanguage',
      'getEmployeeCode',
    ]) {
      controller.addJavaScriptHandler(
        handlerName: name,
        callback: (_) async {
          if (!await _isHost(controller)) return null;
          return switch (name) {
            'getToken' => 'fake-chatbot-token-${_refreshCount}',
            'onTokenRefresh' => 'fake-chatbot-access-token-${++_refreshCount}',
            'getLanguage' => 'en',
            'getEmployeeCode' => 'TLG-100215',
            _ => null,
          };
        },
      );
    }
    controller.addJavaScriptHandler(
      handlerName: 'chatbotV2Control',
      callback: (arguments) async {
        if (!await _isHost(controller) || arguments.isEmpty) return;
        switch (arguments.first) {
          case 'CHAT_CLOSE':
            _close();
          case 'TOGGLE_FULLSCREEN':
            if (arguments.length > 1 && arguments[1] is Map) {
              final fullscreen = arguments[1]['isFullscreen'];
              if (fullscreen is bool) {
                setState(() => _isFullscreen = fullscreen);
              }
            }
        }
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'chatbotV2Status',
      callback: (arguments) async {
        if (!await _isHost(controller) || arguments.isEmpty) return;
        setState(() {
          _isLoading = false;
          _hasError = arguments.first == 'error';
        });
      },
    );
  }

  void _showError() {
    if (!mounted || _isClosing) return;
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: _isFullscreen
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _isFullscreen ? double.infinity : 480,
        ),
        child: FractionallySizedBox(
          heightFactor: _isFullscreen ? 1 : 0.85,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InAppWebView(
                key: ValueKey(_reloadVersion),
                initialData: InAppWebViewInitialData(
                  data: chatbotWidgetHostHtml,
                  baseUrl: WebUri(chatbotWidgetHostUrl),
                  historyUrl: WebUri(chatbotWidgetHostUrl),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  useShouldOverrideUrlLoading: true,
                ),
                onWebViewCreated: _registerBridge,
                shouldOverrideUrlLoading: (controller, navigation) async {
                  if (navigation.isForMainFrame &&
                      navigation.request.url?.toString() !=
                          chatbotWidgetHostUrl) {
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onReceivedError: (controller, request, error) {
                  if (request.isForMainFrame == true ||
                      request.url.host == chatbotHost) {
                    _showError();
                  }
                },
                onReceivedHttpError: (controller, request, response) {
                  if (request.isForMainFrame == true ||
                      request.url.path == '/widget.js') {
                    _showError();
                  }
                },
              ),
              if (_isLoading && !_hasError)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(),
                ),
              if (_hasError)
                ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Không thể tải chatbot V2.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _hasError = false;
                              _reloadVersion++;
                            });
                          },
                          child: const Text('Thử lại'),
                        ),
                        TextButton(
                          onPressed: _close,
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
