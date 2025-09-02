import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import 'package:vibration/vibration.dart';

import '../models/morse_code.dart';
import '../services/morse_audio_service.dart';

class PracticeProvider extends ChangeNotifier {
  // Game state
  String _currentCharacter = '';
  String _currentMorse = '';
  String _userInput = '';
  bool _isCorrect = false;
  bool _showResult = false;
  bool _hintRevealed = false;
  bool _showCorrectAnswer = false;
  bool _showHint = false;
  Timer? _checkTimer;
  Timer? _hintTimer;
  final MorseAudioService _audioService = MorseAudioService();
  final Random _random = Random();
  List<MorseCode> _currentCodes = [];
  int _currentIndex = 0;
  Map<int, int> _completionCount = {};
  Map<int, bool> _hadIncorrectOnCompletion = {};
  bool _isFavorite = false;
  int _correctCount = 0; // Track correct attempts for current character
  String _difficulty = '简单';
  bool _hasIncorrectAttempt = false; // Track if user made incorrect attempt

  // Getters
  String get currentCharacter => _currentCharacter;
  String get currentMorse => _currentMorse;
  String get userInput => _userInput;
  bool get isCorrect => _isCorrect;
  bool get showResult => _showResult;
  bool get hintRevealed => _hintRevealed;
  bool get isFavorite => _isFavorite;
  int get correctCount => _correctCount;
  String get difficulty => _difficulty;
  bool get showCorrectAnswer => _showCorrectAnswer;
  bool get hasIncorrectAttempt => _hasIncorrectAttempt;
  int get requiredAttempts => _hasIncorrectAttempt ? 2 : 1;
  bool get showHint => _showHint;
  double get progress => _hasIncorrectAttempt ? (_correctCount / 2.0) : 0.0;
  List<MorseCode>? get currentCodes => _currentCodes;
  int get currentIndex => _currentIndex;
  Map<int, int> get completionCount => _completionCount;
  Map<int, bool> get hadIncorrectOnCompletion => _hadIncorrectOnCompletion;

  // Initialize practice session
  void initializePractice(String difficulty) {
    _difficulty = difficulty;
    _loadCodes();
  }

  // Load codes based on difficulty
  void _loadCodes() {
    switch (_difficulty) {
      case '简单':
        _currentCodes = MorseCodeData.englishAlphabet;
        break;
      case '中等':
        _currentCodes = [
          ...MorseCodeData.englishAlphabet,
          ...MorseCodeData.numbers
        ];
        break;
      case '困难':
        // Exclude Chinese characters; include only English letters, numbers, and common symbols
        _currentCodes = [
          ...MorseCodeData.englishAlphabet,
          ...MorseCodeData.numbers,
          ...MorseCodeData.punctuation,
        ];
        break;
    }
    // Reset session completion tracking when loading new code set
    _completionCount = {};
    _hadIncorrectOnCompletion = {};
    _currentIndex = -1;
    generateNewCharacter();
  }

  // Generate new character for practice
  void generateNewCharacter() {
    if (_currentCodes.isEmpty) return;

    // Pick a random index and remember it so we can mark practiced later
    _currentIndex = _random.nextInt(_currentCodes.length);
    final randomCode = _currentCodes[_currentIndex];
    _currentCharacter = randomCode.character;
    _currentMorse = randomCode.morse;
    _userInput = '';
    _showResult = false;
    _isCorrect = false;
    _hintRevealed = false;
    _isFavorite = false;
    _correctCount = 0; // Reset correct count for new character
    _showCorrectAnswer = false;
    _hasIncorrectAttempt = false; // Reset incorrect attempt flag
    _showHint = false;
    notifyListeners();
  }

  // Add dot to user input
  void addDot() {
    Vibration.vibrate(duration: 50);
    _userInput += '.';
    notifyListeners();
    _startAutoCheck();
  }

  // Add dash to user input
  void addDash() {
    Vibration.vibrate(duration: 100);
    _userInput += '-';
    notifyListeners();
    _startAutoCheck();
  }

  // Start auto-check timer
  void _startAutoCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer(const Duration(milliseconds: 800), () {
      checkAnswer();
    });
  }

  // Check if the answer is correct
  void checkAnswer() {
    if (_userInput.trim().isEmpty) return;

    final isCorrect = _userInput.trim() == _currentMorse;
    _isCorrect = isCorrect;
    _showResult = true;

    if (isCorrect) {
      _correctCount++;
      final requiredCount = _hasIncorrectAttempt ? 2 : 1;

      if (_correctCount >= requiredCount) {
        // Character completed, move to next
        // Mark this character as practiced in this session
        if (_currentIndex >= 0) {
          _completionCount[_currentIndex] = (_completionCount[_currentIndex] ?? 0) + 1;
          // Record whether this completion had an incorrect attempt beforehand
          _hadIncorrectOnCompletion[_currentIndex] = _hasIncorrectAttempt;
        }
        notifyListeners();

        Timer(const Duration(milliseconds: 1500), () {
          generateNewCharacter();
        });
      } else {
        // Need more correct attempts, reset for next attempt
        Timer(const Duration(milliseconds: 1500), () {
          _userInput = '';
          _showResult = false;
          _isCorrect = false;
          notifyListeners();
        });
      }
    } else {
      // Wrong answer, mark that user made incorrect attempt (if not already marked)
      if (!_hasIncorrectAttempt) {
        _hasIncorrectAttempt = true;
        _correctCount = 0; // Only reset counter on first incorrect attempt
      }
      // After 1 second, show correct answer
      Timer(const Duration(milliseconds: 1000), () {
        _showCorrectAnswer = true;
        notifyListeners();
      });
      // Auto-hide error note after 2 seconds total (1 second red + 1 second correct answer)
      Timer(const Duration(milliseconds: 2000), () {
        _showResult = false;
        _showCorrectAnswer = false;
        _userInput = '';
        notifyListeners();
      });
    }
    notifyListeners();
  }

  // Clear user input
  void clearInput() {
    _userInput = '';
    notifyListeners();
  }

  // Toggle favorite status
  void toggleFavorite() {
    _isFavorite = !_isFavorite;
    notifyListeners();
  }

  // Skip to next character
  void passCharacter() {
    generateNewCharacter();
  }

  // Play morse code audio
  void playMorseCode() {
    _audioService.playMorseCode(_currentMorse);
  }

  // Show hint for 1 second
  void flashHint() {
    _hintTimer?.cancel();
    _showHint = true;
    notifyListeners();

    _hintTimer = Timer(const Duration(milliseconds: 1000), () {
      _showHint = false;
      notifyListeners();
    });
  }

  // Change difficulty
  void changeDifficulty(String newDifficulty) {
    if (_difficulty != newDifficulty) {
      _difficulty = newDifficulty;
      _loadCodes();
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }
}
