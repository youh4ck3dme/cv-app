import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/cv_data.dart';
import '../services/ai_service.dart';
// Note: Only AiGateway and ConsentGuard are exported from ai_service.dart.
// The underlying _AiService is file-private to ensure compiler-enforced zero-leak architectural boundaries.

class CVState {
  final List<CVData> history;
  final CVData? currentCV;
  final bool isLoading;
  final String? errorMessage;
  final String currentStatus;

  CVState({
    required this.history,
    this.currentCV,
    this.isLoading = false,
    this.errorMessage,
    this.currentStatus = '',
  });

  CVState copyWith({
    List<CVData>? history,
    CVData? currentCV,
    bool? isLoading,
    String? errorMessage,
    String? currentStatus,
  }) {
    return CVState(
      history: history ?? this.history,
      currentCV: currentCV ?? this.currentCV,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }
}

class CVNotifier extends StateNotifier<CVState> {
  CVNotifier() : super(CVState(history: [])) {
    loadHistory();
  }

  static const String _historyKey = 'cv_history_data';
  static const _storage = FlutterSecureStorage();

  /// Loads CV history from secure storage
  Future<void> loadHistory() async {
    try {
      final historyRaw = await _storage.read(key: _historyKey);
      if (historyRaw != null) {
        final List<dynamic> decodedList = jsonDecode(historyRaw);
        final loaded = decodedList
            .map((item) => CVData.fromJson(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(history: loaded);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error loading history: $e');
    }
  }

  /// Saves a CV to history using secure storage
  Future<void> saveToHistory(CVData cv) async {
    try {
      // Prevent duplicates (based on name & title)
      final existingIndex = state.history.indexWhere(
        (item) =>
            item.personalInfo.fullName == cv.personalInfo.fullName &&
            item.personalInfo.title == cv.personalInfo.title,
      );

      final List<CVData> updatedHistory = List.from(state.history);
      if (existingIndex != -1) {
        updatedHistory[existingIndex] = cv; // Update existing
      } else {
        updatedHistory.insert(0, cv); // Insert at beginning
      }

      final encoded = jsonEncode(updatedHistory);
      await _storage.write(key: _historyKey, value: encoded);

      state = state.copyWith(history: updatedHistory);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error saving CV: $e');
    }
  }

  /// Deletes a CV from history
  Future<void> deleteCV(int index) async {
    try {
      final List<CVData> updatedHistory = List.from(state.history);
      updatedHistory.removeAt(index);
      final encoded = jsonEncode(updatedHistory);
      await _storage.write(key: _historyKey, value: encoded);
      state = state.copyWith(history: updatedHistory);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error deleting CV: $e');
    }
  }

  /// Sets the currently active CV (for viewing or editing)
  void setCurrentCV(CVData cv) {
    state = state.copyWith(currentCV: cv);
  }

  /// Clears the currently active CV state
  void clearCurrentCV() {
    state = state.copyWith(currentCV: null);
  }

  /// Generates a CV using AI
  Future<void> generateNewCV({
    String? rawText,
    String? base64Image,
    required String language,
    String? apiKey,
    required Function() onFinished,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final generatedCv = await AiGateway.generate(
        rawText: rawText,
        base64Image: base64Image,
        language: language,
        customApiKey: apiKey,
      );

      state = state.copyWith(
        currentCV: generatedCv,
        isLoading: false,
      );

      // Save to local history automatically
      await saveToHistory(generatedCv);
      onFinished();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Generation failed: $e',
      );
    }
  }
}

// Riverpod Provider
final cvProvider = StateNotifierProvider<CVNotifier, CVState>((ref) {
  return CVNotifier();
});
