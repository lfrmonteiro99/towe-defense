import 'package:flutter/foundation.dart';

class HudNotifier extends ChangeNotifier {
  int _gold = 150;
  int _lives = 20;
  int _wave = 0;
  bool _waveInProgress = false;

  int get gold => _gold;
  int get lives => _lives;
  int get wave => _wave;
  bool get waveInProgress => _waveInProgress;

  void setGold(int v) {
    _gold = v;
    notifyListeners();
  }

  void addGold(int v) {
    _gold += v;
    notifyListeners();
  }

  bool spendGold(int cost) {
    if (_gold < cost) return false;
    _gold -= cost;
    notifyListeners();
    return true;
  }

  void loseLife() {
    if (_lives > 0) _lives--;
    notifyListeners();
  }

  void setWave(int v) {
    _wave = v;
    notifyListeners();
  }

  void setWaveInProgress(bool v) {
    _waveInProgress = v;
    notifyListeners();
  }

  void reset() {
    _gold = 150;
    _lives = 20;
    _wave = 0;
    _waveInProgress = false;
    notifyListeners();
  }
}
