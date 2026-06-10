import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// Remove unused import
// import '../models/app_state.dart';

// Renamed to avoid any potential conflicts
class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  
  // Get ESP32 IP address (configure this based on your network)
  // You can make this dynamic by scanning for the device
  String _getWebSocketUrl() {
    // Replace with your ESP32's IP address
    // You can find this from the LCD display of the ESP32
    return 'ws://192.168.1.100:81'; // Update this IP
  }
  
  bool get isConnected => _isConnected;
  
  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_getWebSocketUrl()));
      
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
          _attemptReconnect();
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
        },
      );
      
      _isConnected = true;
      notifyListeners();
      
      // Request current state
      sendMessage('getState');
      sendMessage('getData');
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _isConnected = false;
      notifyListeners();
    }
  }
  
  void _attemptReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }
  
  void _handleMessage(String message) {
    debugPrint('WebSocket received: $message');
    
    if (message.startsWith('state:')) {
      String state = message.substring(6);
      // Update bulb state (you can add logic here)
      if (state == 'on') {
        // Update bulb state in app state
        // You can notify listeners or update a local variable
        debugPrint('Bulb turned ON via WebSocket');
      } else if (state == 'off') {
        debugPrint('Bulb turned OFF via WebSocket');
      }
    } else if (message.startsWith('data:')) {
      String jsonStr = message.substring(5);
      try {
        // Fix: Use underscore to indicate intentionally unused variable
        Map<String, dynamic> _ = jsonDecode(jsonStr);
        // Update sensor data (you can add logic here)
        // Example: parse the data and update state
        debugPrint('Sensor data received via WebSocket');
      } catch (e) {
        debugPrint('Error parsing data: $e');
      }
    }
  }
  
  void sendMessage(String message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message);
    }
  }
  
  void controlBulb(bool turnOn) {
    sendMessage(turnOn ? 'led:on' : 'led:off');
  }
  
  void requestSensorData() {
    sendMessage('getData');
  }
  
  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
