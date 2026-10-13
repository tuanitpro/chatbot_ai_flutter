import 'package:flutter/material.dart';

import 'chatbot_config.dart';
import 'chatbot_popup.dart';
import 'chatbot_popup_v2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF088C45)),
      ),
      home: const MyHomePage(title: 'Chatbot AI'),
    );
  }
}

enum _ChatbotVersion { v1, v2 }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _ChatbotVersion _version = _ChatbotVersion.v2;

  Widget _versionOption({
    required _ChatbotVersion version,
    required String title,
    required String description,
  }) {
    final selected = _version == version;
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: selected ? const Color(0xFFE7F4EC) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? const Color(0xFF088C45) : const Color(0xFFDCE8DF),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _version = version),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: const Color(0xFF088C45),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF163C2B),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(color: Color(0xFF56665E)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8F5),
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 128),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ANTT / CHATBOT AI · FLUTTER SAMPLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF088C45),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Xin chào, tôi có thể giúp gì cho bạn?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF163C2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chọn phiên bản tích hợp, rồi nhấn avatar để mở chatbot.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF56665E)),
                  ),
                  const SizedBox(height: 28),
                  _versionOption(
                    version: _ChatbotVersion.v1,
                    title: 'V1 · Direct link',
                    description: 'Chat public qua /embed · ChatbotPopup',
                  ),
                  const SizedBox(height: 12),
                  _versionOption(
                    version: _ChatbotVersion.v2,
                    title: 'V2 · Widget + bridge',
                    description:
                        'Token, ngôn ngữ và mã nhân viên · ChatbotPopupV2',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'V2 đang dùng token giả để minh họa bridge. '
                    'Thay bằng service đăng nhập của app để chat có xác thực.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Color(0xFF658171),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PopScope(
            canPop: false,
            child: _version == _ChatbotVersion.v1
                ? const ChatbotPopup()
                : const ChatbotPopupV2(),
          ),
        ),
        tooltip: 'Mở chatbot ${_version == _ChatbotVersion.v1 ? 'V1' : 'V2'}',
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF088C45),
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        child: Image.network(
          '$chatbotBaseUrl/avatar.gif',
          width: 96,
          height: 96,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.chat_bubble_outline),
        ),
      ),
    );
  }
}
