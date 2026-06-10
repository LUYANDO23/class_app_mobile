import 'package:flutter/material.dart';

class SensorData {
  final double temperature;
  final double humidity;
  final String datetime;
  final int timestamp;
  
  SensorData({
    required this.temperature,
    required this.humidity,
    required this.datetime,
    required this.timestamp,
  });
  
  factory SensorData.fromMap(Map<String, dynamic> map, String key) {
    return SensorData(
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      datetime: map['datetime'] ?? '',
      timestamp: map['timestamp'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'datetime': datetime,
      'timestamp': timestamp,
    };
  }
}

class AppState extends ChangeNotifier {
  bool _bulbState = false;
  SensorData? _currentData;
  final List<SensorData> _history = [];
  bool _isLoading = true;
  String? _error;
  
  bool get bulbState => _bulbState;
  SensorData? get currentData => _currentData;
  List<SensorData> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void setBulbState(bool state) {
    _bulbState = state;
    notifyListeners();
  }
  
  void updateCurrentData(SensorData data) {
    _currentData = data;
    _addToHistory(data);
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
  
  void _addToHistory(SensorData data) {
    _history.insert(0, data);
    if (_history.length > 100) {
      _history.removeLast();
    }
  }
  
  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}