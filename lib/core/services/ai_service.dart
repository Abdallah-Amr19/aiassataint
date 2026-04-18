import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class AiService {
  final String? cohereApiKey;
  final String? elevenLabsApiKey;

  AiService({this.cohereApiKey, this.elevenLabsApiKey});

  Future<String?> transcribeAudio(String filePath) async {
    if (elevenLabsApiKey == null || elevenLabsApiKey!.isEmpty) {
      throw Exception('ElevenLabs API key required for voice transcription');
    }

    final uri = Uri.parse(
      '${ApiConstants.elevenLabsBaseUrl}${ApiConstants.elevenLabsEndpoint}',
    );

    final request = http.MultipartRequest('POST', uri);
    request.headers['xi_api_key'] = elevenLabsApiKey!;
    request.fields['model_id'] = ApiConstants.elevenLabsModel;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['text'];
    } else {
      throw Exception('Transcription failed: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> generateTasks(String userInput) async {
    if (userInput.trim().isEmpty) {
      throw Exception('Input cannot be empty');
    }

    if (cohereApiKey == null || cohereApiKey!.isEmpty) {
      throw Exception('Cohere API key not configured.');
    }

    return await _generateTasksWithCohere(userInput);
  }

  Future<List<Map<String, dynamic>>> _generateTasksWithCohere(
    String userInput,
  ) async {
    final userPrompt = ApiConstants.cohereUserPromptTemplate.replaceAll(
      '{USER_INPUT}',
      userInput,
    );

    final fullPrompt =
        '''
${ApiConstants.cohereSystemPrompt}

$userPrompt
''';

    final uri = Uri.parse('${ApiConstants.cohereBaseUrl}/chat');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cohereApiKey',
      },
      body: json.encode({
        'model': ApiConstants.cohereModel,
        'message': fullPrompt,
        'temperature': 0.3,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['text'] ?? data['message'] ?? '';

      return _parseJsonResponse(content);
    } else {
      final error = json.decode(response.body);
      throw Exception(
        'AI Error: ${error['message'] ?? error['error']?['message'] ?? 'Unknown error'}',
      );
    }
  }

  List<Map<String, dynamic>> _parseJsonResponse(String content) {
    String jsonStr = content.trim();

    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7);
    } else if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.substring(3);
    }

    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 3);
    }

    jsonStr = jsonStr.trim();

    final dynamic parsed = json.decode(jsonStr);

    if (parsed is List) {
      return parsed
          .map(
            (item) => {
              'task': item['task'] ?? item['title'] ?? '',
              'priority': item['priority'] ?? 'medium',
              'deadline': item['deadline'],
            },
          )
          .toList();
    }

    throw Exception('Invalid response format');
  }
}
