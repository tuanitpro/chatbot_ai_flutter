import 'package:flutter/material.dart';

import 'chatbot_config.dart';
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: const Center(
        child: Text('Nhấn nút chat để trò chuyện với trợ lý.'),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              const PopScope(canPop: false, child: ChatbotPopupV2()),
        ),
        tooltip: 'Mở chatbot',
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
