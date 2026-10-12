import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'chatbot_config.dart';

const chatbotUrl =
    '$chatbotBaseUrl/embed'
    '?id=640fd94e-0b78-4522-83ae-e9860c5ff947'
    '&mode=mobile'
    '&client_id=ChatBot_App'
    '&session_id=9ee79dce-d94a-4d08-b04a-68246796f012'
    '&color=088c45'
    '&language=en'
    '&auto_open=true'
    '&v=mobile-callbacks-1';

class ChatbotPopup extends StatefulWidget {
  const ChatbotPopup({super.key});

  @override
  State<ChatbotPopup> createState() => _ChatbotPopupState();
}

class _ChatbotPopupState extends State<ChatbotPopup> {
  static final _widgetBridgeScript =
      r'''
(() => {
  if (window.location.origin !== __CHATBOT_ORIGIN_JSON__ ||
      window.location.pathname !== '/embed' ||
      window.__flutterChatbotBridgeInstalled) return;
  window.__flutterChatbotBridgeInstalled = true;
  const botId = new URLSearchParams(window.location.search).get('id');
  const pending = [];
  const flush = () => {
    if (!window.flutter_inappwebview?.callHandler) return;
    while (pending.length) {
      const message = pending.shift();
      window.flutter_inappwebview.callHandler(
        'chatbotWidgetControl', message.type, message.data || {}
      );
    }
  };
  window.addEventListener('flutterInAppWebViewPlatformReady', flush);
  window.addEventListener('message', (event) => {
    if (event.source !== window || event.origin !== window.location.origin) return;
    const message = event.data;
    if (!message || message.source !== botId) return;
    if (message.type !== 'CHAT_CLOSE' && message.type !== 'TOGGLE_FULLSCREEN') return;
    pending.push(message);
    flush();
  });
})();
'''
          .replaceAll('__CHATBOT_ORIGIN_JSON__', jsonEncode(chatbotOrigin));

  InAppWebViewController? _controller;
  double _progress = 0;
  bool _hasError = false;
  bool _isFullscreen = false;
  bool _isClosing = false;

  void _closePopup() {
    if (!mounted || _isClosing) return;
    _isClosing = true;
    Navigator.of(context).pop();
  }

  void _registerWidgetBridge(InAppWebViewController controller) {
    _controller = controller;
    controller.addJavaScriptHandler(
      handlerName: 'chatbotWidgetControl',
      callback: (arguments) async {
        final url = await controller.getUrl();
        if (!mounted ||
            _isClosing ||
            arguments.isEmpty ||
            url?.origin != chatbotOrigin ||
            url?.path != '/embed') {
          return;
        }
        switch (arguments.first) {
          case 'CHAT_CLOSE':
            _closePopup();
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
  }

  void _showError() {
    if (!mounted) return;
    setState(() => _hasError = true);
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
                initialUserScripts: UnmodifiableListView([
                  UserScript(
                    source: _widgetBridgeScript,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  ),
                ]),
                initialUrlRequest: URLRequest(url: WebUri(chatbotUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                ),
                onWebViewCreated: _registerWidgetBridge,
                onLoadStart: (controller, url) {
                  if (!mounted) return;
                  setState(() {
                    _progress = 0;
                    _hasError = false;
                  });
                },
                onProgressChanged: (controller, progress) {
                  if (!mounted) return;
                  setState(() => _progress = progress / 100);
                },
                onLoadStop: (controller, url) async {
                  if (!mounted) return;
                  await controller.evaluateJavascript(
                    source: _widgetBridgeScript,
                  );
                  if (!mounted) return;
                  setState(() => _progress = 1);
                },
                onReceivedError: (controller, request, error) {
                  if (request.isForMainFrame == true) _showError();
                },
                onReceivedHttpError: (controller, request, response) {
                  if (request.isForMainFrame == true) _showError();
                },
              ),
              if (_progress < 1 && !_hasError)
                Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(value: _progress),
                ),
              if (_hasError)
                ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Không thể tải chatbot. Vui lòng thử lại.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _progress = 0;
                              });
                              _controller?.reload();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
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
