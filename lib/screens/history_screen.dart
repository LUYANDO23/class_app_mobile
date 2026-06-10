import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../services/firebase_service.dart';
import '../widgets/brutalist_theme.dart';  // Add this import for BrutalistButton

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SensorData> _historyData = [];
  bool _isLoading = true;
  String? _error;
  int _selectedChartIndex = 0; // 0: temp, 1: humidity
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Fix: Use the correct class name FirebaseService
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final appState = Provider.of<AppState>(context, listen: false);
      
      // First get from app state
      if (appState.history.isNotEmpty) {
        _historyData = List.from(appState.history);
      }
      
      // Then try to fetch more from Firebase
      final rawHistory = await firebaseService.getHistoricalData();
      if (rawHistory.isNotEmpty) {
        final List<SensorData> newData = [];
        for (var item in rawHistory) {
          newData.add(SensorData(
            temperature: (item['temperature'] ?? 0).toDouble(),
            humidity: (item['humidity'] ?? 0).toDouble(),
            datetime: item['datetime'] ?? '',
            timestamp: item['timestamp'] ?? 0,
          ));
        }
        
        // Combine and deduplicate
        final allData = {...newData, ..._historyData};
        _historyData = allData.toList();
        _historyData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTORY'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? _buildErrorView()
              : _historyData.isEmpty
                  ? _buildEmptyView()
                  : _buildHistoryContent(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text(
            'Error loading history',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          // Fix: BrutalistButton is now imported
          BrutalistButton(
            text: 'RETRY',
            onPressed: _loadHistory,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'No history data available',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Wait for sensor readings to appear',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          // Fix: BrutalistButton is now imported
          BrutalistButton(
            text: 'REFRESH',
            onPressed: _loadHistory,
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryContent() {
    return Column(
      children: [
        // Chart Toggle
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChartIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedChartIndex == 0 ? Colors.white : Colors.white24,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'TEMPERATURE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedChartIndex == 0 ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChartIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedChartIndex == 1 ? Colors.white : Colors.white24,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'HUMIDITY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedChartIndex == 1 ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Chart
        SizedBox(
          height: 280,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _selectedChartIndex == 0
                ? _buildTemperatureChart()
                : _buildHumidityChart(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // History List
        Expanded(
          child: _buildHistoryList(),
        ),
      ],
    );
  }
  
  Widget _buildTemperatureChart() {
    if (_historyData.length < 2) {
      return const Center(child: Text('Need more data points for chart'));
    }
    
    final List<FlSpot> spots = [];
    final reversed = List.from(_historyData.reversed);
    
    for (int i = 0; i < reversed.length && i < 50; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].temperature));
    }
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}Â°C',
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 == 0 && value.toInt() < reversed.length) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    reversed[value.toInt()].timestamp * 1000,
                  );
                  return Text(
                    DateFormat('HH:mm').format(date),
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              // Fix: Replace deprecated withOpacity with withValues
              color: Colors.blueAccent.withValues(alpha: 0.1),
            ),
            dotData: const FlDotData(show: true),
          ),
        ],
        minY: 0,
        maxY: 50,
      ),
    );
  }
  
  Widget _buildHumidityChart() {
    if (_historyData.length < 2) {
      return const Center(child: Text('Need more data points for chart'));
    }
    
    final List<FlSpot> spots = [];
    final reversed = List.from(_historyData.reversed);
    
    for (int i = 0; i < reversed.length && i < 50; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].humidity));
    }
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 == 0 && value.toInt() < reversed.length) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    reversed[value.toInt()].timestamp * 1000,
                  );
                  return Text(
                    DateFormat('HH:mm').format(date),
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.greenAccent,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              // Fix: Replace deprecated withOpacity with withValues
              color: Colors.greenAccent.withValues(alpha: 0.1),
            ),
            dotData: const FlDotData(show: true),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }
  
  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _historyData.length,
      itemBuilder: (context, index) {
        final data = _historyData[index];
        final date = DateTime.fromMillisecondsSinceEpoch(data.timestamp * 1000);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm:ss a').format(date),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TEMP', style: TextStyle(fontSize: 10, color: Colors.white54)),
                    Text(
                      '${data.temperature.toStringAsFixed(1)}Â°C',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTemperatureColor(data.temperature),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HUMIDITY', style: TextStyle(fontSize: 10, color: Colors.white54)),
                    Text(
                      '${data.humidity.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getHumidityColor(data.humidity),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
}
