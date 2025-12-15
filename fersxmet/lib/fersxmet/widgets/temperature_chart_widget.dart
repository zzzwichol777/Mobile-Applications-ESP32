import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme_manager.dart';

class TemperatureChartWidget extends StatelessWidget {
  final List<TemperatureDataPoint> ambientData;
  final List<TemperatureDataPoint> objectData;
  final String title;
  final bool showLegend;

  const TemperatureChartWidget({
    super.key,
    required this.ambientData,
    required this.objectData,
    this.title = 'Temperatura Dual',
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = ThemeManager.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLegend) _buildLegend(primaryColor),
        if (showLegend) const SizedBox(height: 16),
        Expanded(
          child: _buildChart(primaryColor),
        ),
      ],
    );
  }


  Widget _buildLegend(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('DHT22 (Ambiente)', Colors.cyan),
        const SizedBox(width: 24),
        _buildLegendItem('MLX90614 (Objeto)', Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ExpletusSans',
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(Color primaryColor) {
    if (ambientData.isEmpty && objectData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, color: primaryColor.withOpacity(0.5), size: 48),
            const SizedBox(height: 12),
            Text(
              'Sin datos disponibles',
              style: TextStyle(
                fontFamily: 'ExpletusSans',
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final allTemps = [...ambientData.map((e) => e.temperature), ...objectData.map((e) => e.temperature)];
    final rawMin = allTemps.isEmpty ? 0.0 : allTemps.reduce((a, b) => a < b ? a : b);
    final rawMax = allTemps.isEmpty ? 50.0 : allTemps.reduce((a, b) => a > b ? a : b);
    
    // Calcular rango con margen del 10%
    final range = rawMax - rawMin;
    final margin = range > 0 ? range * 0.1 : 5.0;
    final minTemp = (rawMin - margin).floorToDouble();
    final maxTemp = (rawMax + margin).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _calculateYInterval(minTemp, maxTemp),
          verticalInterval: _calculateInterval(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateInterval(),
              getTitlesWidget: _bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateYInterval(minTemp, maxTemp),
              getTitlesWidget: _leftTitleWidgets,
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        minX: 0,
        maxX: _getMaxX(),
        minY: minTemp,
        maxY: maxTemp,
        lineBarsData: [
          _buildLineData(ambientData, Colors.cyan),
          _buildLineData(objectData, Colors.orange),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isAmbient = spot.barIndex == 0;
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}°C\n${isAmbient ? "Ambiente" : "Objeto"}',
                  TextStyle(
                    color: isAmbient ? Colors.cyan : Colors.orange,
                    fontFamily: 'ExpletusSans',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }


  LineChartBarData _buildLineData(List<TemperatureDataPoint> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temperature)).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.15),
      ),
    );
  }

  double _getMaxX() {
    final maxAmbient = ambientData.isEmpty ? 0 : ambientData.length - 1;
    final maxObject = objectData.isEmpty ? 0 : objectData.length - 1;
    return (maxAmbient > maxObject ? maxAmbient : maxObject).toDouble().clamp(1, double.infinity);
  }

  double _calculateInterval() {
    final maxX = _getMaxX();
    if (maxX <= 5) return 1;
    if (maxX <= 10) return 2;
    if (maxX <= 20) return 5;
    return 10;
  }

  double _calculateYInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    return 20;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    
    // Usar la lista más larga para los timestamps
    final dataToUse = ambientData.length >= objectData.length ? ambientData : objectData;
    
    if (index < 0 || index >= dataToUse.length) {
      return const SizedBox.shrink();
    }
    
    final time = dataToUse[index].timestamp;
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontFamily: 'ExpletusSans',
          color: Colors.white.withOpacity(0.6),
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${value.toInt()}°',
        style: TextStyle(
          fontFamily: 'ExpletusSans',
          color: Colors.white.withOpacity(0.6),
          fontSize: 11,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Color _getDarkThemeColor(Color primaryColor) {
    final hslColor = HSLColor.fromColor(primaryColor);
    final darkColor = hslColor.withLightness(0.15).withSaturation(0.4);
    return darkColor.toColor();
  }
}

class TemperatureDataPoint {
  final DateTime timestamp;
  final double temperature;
  final String source;

  TemperatureDataPoint({
    required this.timestamp,
    required this.temperature,
    required this.source,
  });
}
