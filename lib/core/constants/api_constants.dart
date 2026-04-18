class ApiConstants {
  // Cohere API
  static const String cohereBaseUrl = 'https://api.cohere.com/v1';
  static const String cohereModel = 'command-r-08-2024';
  static const String defaultCohereApiKey =
      '6pwQuwvlj9Mo4HPs1KMjWray2GhB825OzgS1o1mn';

  static const String cohereSystemPrompt =
      '''You are a smart task extractor. Extract tasks with exact deadlines.

Current timezone: Africa/Cairo (UTC+2)

RULES:
- "at 3 PM" = today at 15:00 local time
- "الساعة 8 صباحا" = today at 08:00 local time
- "meeting 9 evening" = today at 21:00 local time
- "بكرة" = tomorrow same time
- Format deadline as: YYYY-MM-DDTHH:MM:00

Return ONLY JSON array.''';

  static const String cohereUserPromptTemplate =
      '''Extract tasks with deadlines from:

TEXT: {USER_INPUT}

Generate JSON with deadline in format: "2026-04-18T21:00:00"
Current time is 2026-04-18 19:00 Cairo time

JSON ONLY:
[{"task": "task name", "priority": "high", "deadline": "2026-04-18T21:00:00"}]''';

  // ElevenLabs API (for voice transcription)
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  static const String elevenLabsEndpoint = '/speech-to-text';
  static const String elevenLabsModel = 'scribe_v1';
  static const String defaultElevenLabsApiKey =
      'sk-af47dae7bb38d4db38a8892b165357417eec9185d14cd23b';
}

class StorageKeys {
  static const String tasksBox = 'tasks_box';
  static const String settingsBox = 'settings_box';
  static const String cohereApiKey = 'cohere_api_key';
  static const String elevenLabsApiKey =
      'sk_af47dae7bb38d4db38a8892b165357417eec9185d14cd23b';
}

class AppConstants {
  static const String appName = 'AI Planner';
  static const int maxInputLength = 5000;
  static const Duration notificationInterval = Duration(hours: 1);
}
