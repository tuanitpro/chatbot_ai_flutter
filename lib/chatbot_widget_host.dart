import 'dart:convert';

import 'chatbot_config.dart';

const chatbotWidgetHostUrl = '$chatbotBaseUrl/flutter-chatbot-v2';

const chatbotWidgetScriptUrl =
    '$chatbotBaseUrl/widget.js'
    '?id=640fd94e-0b78-4522-83ae-e9860c5ff947'
    '&mode=mobile&client_id=ChatBot_App'
    '&session_id=b7b444de-e936-4af9-bb6d-619214e88433'
    '&color=088c45&language=en'
    '&auto_init=false&v=mobile-callbacks-1';

// This HTML is loaded locally with an HTTPS base URL; no host page is fetched.
// Tokens are supplied by native handlers, never placed in HTML or iframe URLs.
final chatbotWidgetHostHtml = _chatbotWidgetHostTemplate.replaceAll(
  '__CHATBOT_SCRIPT_URL_JSON__',
  jsonEncode(chatbotWidgetScriptUrl),
);

const _chatbotWidgetHostTemplate = r'''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <style>
    html, body { width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden; }
  </style>
</head>
<body>
<script>
(() => {
  window.ChatWidgetAutoInit = false;
  const nativeReady = new Promise(resolve => {
    if (window.flutter_inappwebview?.callHandler) resolve();
    else window.addEventListener('flutterInAppWebViewPlatformReady', resolve, {once: true});
  });
  const callNative = async (name, ...args) => {
    await nativeReady;
    return window.flutter_inappwebview.callHandler(name, ...args);
  };
  const widgetScriptUrl = __CHATBOT_SCRIPT_URL_JSON__;
  const script = document.createElement('script');
  script.src = widgetScriptUrl;
  script.async = true;
  script.onerror = () => callNative('chatbotV2Status', 'error');
  script.onload = async () => {
    try {
      await nativeReady;
      if (!window.ChatWidget) throw new Error('Widget script unavailable for host origin');
      const widget = await window.ChatWidget.init({
        getToken: () => callNative('getToken'),
        onTokenRefresh: () => callNative('onTokenRefresh'),
        getLanguage: () => callNative('getLanguage'),
        getEmployeeCode: () => callNative('getEmployeeCode'),
        // widget.js validates iframe messages before invoking these callbacks.
        onClose: () => callNative('chatbotV2Control', 'CHAT_CLOSE'),
        onFullscreenChange: data => callNative('chatbotV2Control', 'TOGGLE_FULLSCREEN', data),
      });
      if (!widget) throw new Error('Widget initialization failed');
      await callNative('chatbotV2Status', 'initialized');
    } catch (_) {
      await callNative('chatbotV2Status', 'error');
    }
  };
  document.head.appendChild(script);
})();
</script>
</body>
</html>
''';
