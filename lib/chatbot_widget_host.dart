import 'dart:convert';

import 'chatbot_config.dart';

const chatbotWidgetHostUrl = '$chatbotBaseUrl/flutter-chatbot-v2';

const chatbotWidgetScriptUrl =
    '$chatbotBaseUrl/widget.js'
    '?id=640fd94e-0b78-4522-83ae-e9860c5ff947'
    '&mode=widget&client_id=ChatBot_App'
    '&session_id=b7b444de-e936-4af9-bb6d-619214e88433'
    '&color=088c45&language=en&position=bottom-right'
    '&auto_open=true&auto_init=false&v=1791812042321';

// This HTML is loaded locally with an HTTPS base URL; no host page is fetched.
// Tokens are supplied by native handlers, never placed in HTML or iframe URLs.
final chatbotWidgetHostHtml = _chatbotWidgetHostTemplate
    .replaceAll('__CHATBOT_ORIGIN_JSON__', jsonEncode(chatbotOrigin))
    .replaceAll(
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
    iframe[name="chat-widget-iframe"] {
      position: fixed !important; inset: 0 !important;
      width: 100% !important; height: 100% !important;
      max-width: none !important; max-height: none !important;
      min-width: 0 !important; min-height: 0 !important;
      margin: 0 !important; padding: 0 !important; border: 0 !important;
      border-radius: 0 !important;
    }
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
  const chatbotOrigin = __CHATBOT_ORIGIN_JSON__;
  const botId = new URL(widgetScriptUrl).searchParams.get('id');
  // Run in the parent frame: only messages from this widget's iframe are accepted.
  window.addEventListener('message', event => {
    const widget = window.__chatWidget;
    if (!widget || event.origin !== chatbotOrigin ||
        event.source !== widget.iframe.contentWindow) return;
    const message = event.data;
    if (!message || message.source !== botId) return;
    const bridge = widget._authBridge;
    if (bridge && message.channel !== bridge.channel &&
        (bridge.authSent || message.channel != null)) return;
    if (message.type === 'CHAT_CLOSE' || message.type === 'TOGGLE_FULLSCREEN') {
      callNative('chatbotV2Control', message.type, message.data || {});
    }
  });

  const removeFrameInsets = iframe => {
    // Parent and iframe share the trusted HTTPS origin established by baseUrl.
    try {
      const doc = iframe.contentDocument;
      if (!doc || doc.getElementById('flutter-chatbot-v2-insets')) return;
      const style = doc.createElement('style');
      style.id = 'flutter-chatbot-v2-insets';
      style.textContent = `
        html, body, #root, .app, .chat-app-fullscreen, .chat-app,
        .chat-widget, .widget-container { margin: 0 !important; padding: 0 !important; }
        html, body, #root, .app, .chat-app-fullscreen,
        .chat-widget, .widget-container { width: 100% !important; height: 100% !important; }
        .widget-container { max-height: none !important; position: absolute !important;
          inset: 0 !important; border-radius: 0 !important; }
      `;
      doc.head.appendChild(style);
    } catch (_) {
      // Origin policies still apply; the parent iframe itself always fills the popup.
    }
  };
  const observer = new MutationObserver(() => {
    const iframe = document.querySelector('iframe[name="chat-widget-iframe"]');
    if (!iframe || iframe.dataset.flutterInsetsHook) return;
    iframe.dataset.flutterInsetsHook = 'true';
    iframe.addEventListener('load', () => removeFrameInsets(iframe));
  });
  observer.observe(document.body, {childList: true});

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
