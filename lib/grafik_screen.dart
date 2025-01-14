import 'package:flutter/material.dart';
import 'sensor_data.dart'; // Pastikan jalurnya benar// Pastikan jalurnya benar
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class GrafikScreen extends StatelessWidget {
  final List<SensorData> sensorDataList;

  const GrafikScreen({Key? key, required this.sensorDataList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafik Data Sensor'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: sensorDataList.isEmpty
            ? const Center(child: Text("Tidak ada data untuk ditampilkan"))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildLineChart(
                        "Suhu", Colors.redAccent, (data) => data.temperature),
                    const SizedBox(height: 16),
                    _buildLineChart("Gas", Colors.blueAccent,
                        (data) => data.gas.toDouble()),
                    const SizedBox(height: 16),
                    _buildLineChart("Kelembapan", Colors.orangeAccent,
                        (data) => data.humidity),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLineChart(
      String title, Color color, double Function(SensorData) valueExtractor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8)
            ],
          ),
          padding: const EdgeInsets.all(12.0),
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                leftTitles: title == "Gas"
                    ? AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                          reservedSize: 0,
                        ),
                      )
                    : AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 10,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  top: BorderSide.none,
                  right: BorderSide.none,
                  left: BorderSide(color: Colors.grey),
                  bottom: BorderSide(color: Colors.grey),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 5,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
                getDrawingVerticalLine: (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _getChartData(valueExtractor),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.5), color],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  barWidth: 4,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.3), color.withOpacity(0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              minY: 0,
              maxY: sensorDataList.isEmpty
                  ? 0
                  : _getMaxValue(title, valueExtractor),
              minX: 0,
              maxX: sensorDataList.length > 10
                  ? 9
                  : sensorDataList.length.toDouble() - 1,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  tooltipMargin: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItems: (spots) => spots.map((spot) {
                    return LineTooltipItem(
                      'X: ${spot.x.toInt()}\nY: ${spot.y.toStringAsFixed(2)}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [],
                    );
                  }).toList(),
                ),
                handleBuiltInTouches: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getMaxValue(
      String title, double Function(SensorData) valueExtractor) {
    return sensorDataList.map(valueExtractor).reduce((a, b) => a > b ? a : b) *
        1.1;
  }

  List<FlSpot> _getChartData(double Function(SensorData) valueExtractor) {
    List<FlSpot> spots = [];
    if (sensorDataList.isEmpty) return spots;

    int startIndex =
        sensorDataList.length > 10 ? sensorDataList.length - 10 : 0;
    int dataPoints = min(10, sensorDataList.length);

    for (int i = 0; i < dataPoints; i++) {
      int dataIndex = startIndex + i;
      double value = valueExtractor(sensorDataList[dataIndex]);
      if (value.isFinite) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    return spots;
  }
}
