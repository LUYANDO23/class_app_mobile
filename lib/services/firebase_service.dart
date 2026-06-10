import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// Remove this line - it's not used
// import '../models/app_state.dart';

class FirebaseService extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  FirebaseService() {
    _setupConnectionCheck();
  }
  
  void _setupConnectionCheck() {
    DatabaseReference connectedRef = FirebaseDatabase.instance.ref('.info/connected');
    connectedRef.onValue.listen((event) {
      _isConnected = event.snapshot.value == true;
      notifyListeners();
    });
  }
  
  // Listen to bulb state changes
  Stream<bool> listenToBulbState() {
    return _database.child('bulb_state').onValue.map((event) {
      return event.snapshot.value == true;
    });
  }
  
  // Listen to real-time sensor data
  Stream<Map<String, dynamic>> listenToSensors() {
    return _database.child('sensors/environment').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }
  
  // Get historical data (last 24 hours)
  Future<List<Map<String, dynamic>>> getHistoricalData() async {
    try {
      DatabaseReference historyRef = _database.child('sensors');
      DatabaseEvent event = await historyRef.once();
      
      List<Map<String, dynamic>> history = [];
      
      if (event.snapshot.value != null) {
        Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        data.forEach((key, value) {
          if (key == 'environment' && value != null) {
            if (value is Map) {
              history.add(Map<String, dynamic>.from(value));
            }
          } else if (value is Map && value.containsKey('temperature')) {
            history.add(Map<String, dynamic>.from(value));
          }
        });
        
        history.sort((a, b) {
          int aTime = a['timestamp'] ?? 0;
          int bTime = b['timestamp'] ?? 0;
          return bTime.compareTo(aTime);
        });
      }
      
      return history;
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return [];
    }
  }
  
  // Control bulb
  Future<bool> setBulbState(bool state) async {
    try {
      await _database.child('bulb_state').set(state);
      return true;
    } catch (e) {
      debugPrint('Error setting bulb state: $e');
      return false;
    }
  }
}
