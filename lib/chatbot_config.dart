// Change this origin to switch the chatbot server for both popup versions.
// Include the scheme and omit a trailing slash.
const chatbotBaseUrl = 'https://chat.antt.tech';

final chatbotOrigin = Uri.parse(chatbotBaseUrl).origin;
final chatbotHost = Uri.parse(chatbotBaseUrl).host;
