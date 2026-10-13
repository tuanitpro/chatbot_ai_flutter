import 'package:chatbot_ai_flutter/chatbot_popup.dart';
import 'package:chatbot_ai_flutter/chatbot_popup_v2.dart';
import 'package:chatbot_ai_flutter/chatbot_widget_host.dart';
import 'package:chatbot_ai_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestWebViewPlatform extends InAppWebViewPlatform {
  InAppWebViewInitialData? initialData;
  URLRequest? initialUrlRequest;
  bool disposed = false;
  final controller = _TestController();

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    initialData = params.initialData;
    initialUrlRequest = params.initialUrlRequest;
    params.onWebViewCreated?.call(params.controllerFromPlatform!(controller));
    return _TestWebView(params, () => disposed = true);
  }
}

class _TestController extends PlatformInAppWebViewController {
  _TestController()
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 0),
      );

  final handlers = <String, JavaScriptHandlerCallback>{};
  WebUri url = WebUri(chatbotWidgetHostUrl);

  @override
  Future<WebUri?> getUrl() async => url;

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {
    handlers[handlerName] = callback;
  }
}

class _TestWebView extends PlatformInAppWebViewWidget {
  _TestWebView(super.params, this.onDispose) : super.implementation();

  final VoidCallback onDispose;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      throw UnimplementedError();

  @override
  void dispose() => onDispose();
}

void main() {
  testWidgets('Version selection opens the corresponding chatbot popup', (
    tester,
  ) async {
    final previousPlatform = InAppWebViewPlatform.instance;
    final platform = _TestWebViewPlatform();
    InAppWebViewPlatform.instance = platform;
    addTearDown(() {
      if (previousPlatform != null) {
        InAppWebViewPlatform.instance = previousPlatform;
      }
    });

    await tester.pumpWidget(const MyApp());
    expect(find.byTooltip('Mở chatbot V2'), findsOneWidget);

    await tester.tap(find.text('V1 · Direct link'));
    await tester.pump();
    expect(find.byTooltip('Mở chatbot V1'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(ChatbotPopup), findsOneWidget);
    expect(find.byType(ChatbotPopupV2), findsNothing);
    expect(platform.initialUrlRequest?.url.toString(), chatbotUrl);
    expect(platform.initialData, isNull);

    platform.controller.url = WebUri(chatbotUrl);
    await platform.controller.handlers['chatbotWidgetControl']!([
      'CHAT_CLOSE',
      {},
    ]);
    await tester.pumpAndSettle();
    expect(find.byType(ChatbotPopup), findsNothing);
    expect(find.byTooltip('Mở chatbot V1'), findsOneWidget);

    await tester.tap(find.text('V2 · Widget + bridge'));
    await tester.pump();
    platform.controller.url = WebUri(chatbotWidgetHostUrl);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await platform.controller.handlers['chatbotV2Status']!(['initialized']);
    await tester.pumpAndSettle();
    expect(find.byType(ChatbotPopupV2), findsOneWidget);
    expect(platform.initialData?.baseUrl.toString(), chatbotWidgetHostUrl);
    expect(platform.initialUrlRequest, isNull);

    await platform.controller.handlers['chatbotV2Control']!(['CHAT_CLOSE', {}]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Web controls expand, restore, and close the Flutter popup', (
    tester,
  ) async {
    final previousPlatform = InAppWebViewPlatform.instance;
    final platform = _TestWebViewPlatform();
    InAppWebViewPlatform.instance = platform;
    addTearDown(() {
      if (previousPlatform != null) {
        InAppWebViewPlatform.instance = previousPlatform;
      }
    });
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await platform.controller.handlers['chatbotV2Status']!(['initialized']);
    await tester.pumpAndSettle();

    final control = platform.controller.handlers['chatbotV2Control']!;
    await control([
      'TOGGLE_FULLSCREEN',
      {'isFullscreen': true},
    ]);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Dialog>(find.byType(Dialog)).insetPadding,
      EdgeInsets.zero,
    );

    await control([
      'TOGGLE_FULLSCREEN',
      {'isFullscreen': false},
    ]);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Dialog>(find.byType(Dialog)).insetPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    );

    platform.controller.url = WebUri('https://example.com/embed');
    await control(['CHAT_CLOSE', {}]);
    await tester.pumpAndSettle();
    expect(find.byType(ChatbotPopupV2), findsOneWidget);

    platform.controller.url = WebUri(chatbotWidgetHostUrl);
    await control(['CHAT_CLOSE', {}]);
    await tester.pumpAndSettle();
    expect(find.byType(ChatbotPopupV2), findsNothing);
    expect(platform.disposed, isTrue);
  });

  testWidgets('V2 loads the script host and provides fake auth context', (
    tester,
  ) async {
    final previousPlatform = InAppWebViewPlatform.instance;
    final platform = _TestWebViewPlatform();
    InAppWebViewPlatform.instance = platform;
    addTearDown(() {
      if (previousPlatform != null) {
        InAppWebViewPlatform.instance = previousPlatform;
      }
    });

    await tester.pumpWidget(const MyApp());
    expect(find.byType(ChatbotPopupV2), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(InAppWebView), findsOneWidget);
    expect(platform.initialData?.baseUrl.toString(), chatbotWidgetHostUrl);
    expect(platform.initialData?.data, contains('widget.js'));
    expect(
      platform.initialData?.data,
      isNot(contains('fake-chatbot-access-token')),
    );
    final handlers = platform.controller.handlers;
    expect(await handlers['getToken']!([]), 'fake-chatbot-token-0');
    expect(await handlers['getLanguage']!([]), 'en');
    expect(await handlers['getEmployeeCode']!([]), 'TLG-100215');
    expect(
      await handlers['onTokenRefresh']!([]),
      'fake-chatbot-access-token-1',
    );
    expect(await handlers['getToken']!([]), 'fake-chatbot-token-1');
    await handlers['chatbotV2Status']!(['initialized']);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The dialog should also fit when the keyboard reduces available height.
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.byIcon(Icons.close), findsNothing);
    await platform.controller.handlers['chatbotV2Control']!(['CHAT_CLOSE', {}]);
    await tester.pumpAndSettle();
    expect(find.byType(ChatbotPopupV2), findsNothing);
    expect(platform.disposed, isTrue);
  });
}
