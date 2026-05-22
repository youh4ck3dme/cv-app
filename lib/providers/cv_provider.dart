import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cv_data.dart';
import '../services/ai_service.dart';

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

  /// Loads CV history from SharedPreferences
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyRaw = prefs.getStringList(_historyKey);
      if (historyRaw != null) {
        final loaded = historyRaw.map((item) {
          final Map<String, dynamic> decoded = jsonDecode(item);
          return CVData.fromJson(decoded);
        }).toList();
        state = state.copyWith(history: loaded);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error loading history: $e');
    }
  }

  /// Saves a CV to history and SharedPreferences
  Future<void> saveToHistory(CVData cv) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Prevent duplicates (based on name & title)
      final existingIndex = state.history.indexWhere(
        (item) => item.personalInfo.fullName == cv.personalInfo.fullName &&
                  item.personalInfo.title == cv.personalInfo.title
      );

      final List<CVData> updatedHistory = List.from(state.history);
      if (existingIndex != -1) {
        updatedHistory[existingIndex] = cv; // Update existing
      } else {
        updatedHistory.insert(0, cv); // Insert at beginning
      }

      final historyRaw = updatedHistory.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_historyKey, historyRaw);
      
      state = state.copyWith(history: updatedHistory);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error saving CV: $e');
    }
  }

  /// Deletes a CV from history
  Future<void> deleteCV(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<CVData> updatedHistory = List.from(state.history);
      updatedHistory.removeAt(index);

      final historyRaw = updatedHistory.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_historyKey, historyRaw);

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
      final generatedCv = await AiService.parseResume(
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
