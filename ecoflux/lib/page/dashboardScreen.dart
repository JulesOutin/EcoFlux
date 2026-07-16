import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/property_models.dart';
import '../services/data_service.dart';

class DashboardScreen extends StatefulWidget {
  final Room room;
  final IDataService dataService;

  const DashboardScreen({
    super.key,
    required this.room,
    required this.dataService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _shortDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';

  // Pas d'axe Y adapté à la plage de données pour éviter les doublons d'étiquettes
  double _niceInterval(double range) {
    if (range <= 5)   return 1;
    if (range <= 15)  return 2;
    if (range <= 40)  return 5;
    if (range <= 100) return 10;
    return 20;
  }

  List<FlSpot> _toSpots(List<double> values) => values
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble(), e.value))
      .toList();

  Widget _buildChart(
    List<SensorData> data,
    Color color,
    String unit,
    double Function(SensorData) getValue, {
    int decimals = 1,
  }) {
    final values = data.map(getValue).toList();
    if (values.isEmpty) return const Center(child: CircularProgressIndicator());

    final spots = _toSpots(values);
    final rawMinY = values.reduce((a, b) => a < b ? a : b);
    final rawMaxY = values.reduce((a, b) => a > b ? a : b);
    final padding  = (rawMaxY - rawMinY) * 0.15;
    final interval = _niceInterval(rawMaxY - rawMinY);
    // Bornes alignées sur l'interval pour que le bord du graphique coïncide
    // toujours avec une étiquette, sinon fl_chart ajoute un doublon au bord.
    final minY = ((rawMinY - padding) / interval).floor() * interval;
    final maxY = ((rawMaxY + padding) / interval).ceil() * interval;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 24, 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
            getDrawingVerticalLine: (v) =>
                FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                interval: interval,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${value.toStringAsFixed(decimals)}$unit',
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 30,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _shortDate(data[idx].timestamp),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.08),
              ),
            ),
          ],
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.x.toInt();
                final label = (idx >= 0 && idx < data.length)
                    ? _shortDate(data[idx].timestamp)
                    : '';
                return LineTooltipItem(
                  '$label\n${s.y.toStringAsFixed(decimals)}$unit',
                  const TextStyle(fontSize: 12, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
        actions: [
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/account'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Température', icon: Icon(Icons.thermostat)),
            Tab(text: 'Humidité',    icon: Icon(Icons.water_drop)),
            Tab(text: 'Pression',    icon: Icon(Icons.compress)),
          ],
        ),
      ),
      body: StreamBuilder<List<SensorData>>(
        stream: widget.dataService.getSensorData(widget.room.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final data = snapshot.data ?? [];
          return TabBarView(
            controller: _tabController,
            children: [
              _buildChart(data, Colors.deepOrange, '°C',   (s) => s.temperature, decimals: 0),
              _buildChart(data, Colors.blue,       '%',    (s) => s.humidity,    decimals: 0),
              _buildChart(data, Colors.green,      ' hPa', (s) => s.pressure,    decimals: 0),
            ],
          );
        },
      ),
    );
  }
}
