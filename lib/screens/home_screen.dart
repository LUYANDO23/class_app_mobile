import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/app_state.dart';
import '../services/firebase_service.dart';
import '../widgets/brutalist_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DatabaseReference _sensorRef;
  late DatabaseReference _bulbRef;
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _sensorRef = FirebaseDatabase.instance.ref('sensors/environment');
    _bulbRef = FirebaseDatabase.instance.ref('bulb_state');
    _setupListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get AppState reference safely
    _appState = Provider.of<AppState>(context, listen: false);
  }

  void _setupListeners() {
    // Listen to real-time sensor updates
    _sensorRef.onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final sensorData = SensorData(
          temperature: (data['temperature'] ?? 0.0).toDouble(),
          humidity: (data['humidity'] ?? 0.0).toDouble(),
          datetime: data['datetime'] ?? DateTime.now().toString(),
          timestamp: data['timestamp'] ?? 0,
        );
        if (mounted) {
          _appState.updateCurrentData(sensorData);
        }
      }
    });

    // Listen to bulb state changes
    _bulbRef.onValue.listen((event) {
      if (mounted) {
        final state = event.snapshot.value == true;
        _appState.setBulbState(state);
      }
    });
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 18) return Colors.blueAccent;
    if (temp < 24) return Colors.greenAccent;
    if (temp < 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.yellowAccent;
    if (humidity < 60) return Colors.lightGreenAccent;
    return Colors.cyanAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CLASS APP'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LIVE DATA',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 4,
                        color: Colors.white54,
                      ),
                    ),
                    if (appState.currentData != null)
                      Text(
                        appState.currentData!.datetime,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Main Sensor Cards
                Row(
                  children: [
                    Expanded(
                      child: GlowingNumberDisplay(
                        value: appState.currentData?.temperature ?? 0,
                        unit: '°C',
                        glowColor: _getTemperatureColor(appState.currentData?.temperature ?? 0),
                        label: 'TEMPERATURE',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlowingNumberDisplay(
                        value: appState.currentData?.humidity ?? 0,
                        unit: '%',
                        glowColor: _getHumidityColor(appState.currentData?.humidity ?? 0),
                        label: 'HUMIDITY',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Divider
                Container(height: 1, color: Colors.white12),
                const SizedBox(height: 30),
                
                // Bulb Control Section
                const Text(
                  'BULB CONTROL',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 4,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smart Bulb',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appState.bulbState ? 'ON' : 'OFF',
                            style: TextStyle(
                              fontSize: 14,
                              color: appState.bulbState ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      BrutalistButton(
                        text: appState.bulbState ? 'TURN OFF' : 'TURN ON',
                        isActive: appState.bulbState,
                        onPressed: () async {
                          final firebaseService = Provider.of<FirebaseService>(
                            context,
                            listen: false,
                          );
                          await firebaseService.setBulbState(!appState.bulbState);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE CONNECTION',
                        style: TextStyle(fontSize: 10, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}