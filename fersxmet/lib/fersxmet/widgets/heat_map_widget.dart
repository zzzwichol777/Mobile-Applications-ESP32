import 'package:flutter/material.dart';
import 'dart:math' as math;

class HeatMapWidget extends StatelessWidget {
  final List<List<double>> data;

  const HeatMapWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sin datos')),
      );
    }

    // Encontrar valores min y max para normalizar
    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;

    for (var row in data) {
      for (var temp in row) {
        if (temp < minTemp) minTemp = temp;
        if (temp > maxTemp) maxTemp = temp;
      }
    }

    final rows = data.length;
    final cols = data[0].length;
    final cellSize = (MediaQuery.of(context).size.width - 80) / cols;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              children: List.generate(rows, (rowIndex) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(cols, (colIndex) {
                    final temp = data[rowIndex][colIndex];
                    final normalizedTemp = (temp - minTemp) / (maxTemp - minTemp);
                    final color = _getHeatColor(normalizedTemp);

                    return Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          temp.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: cellSize > 30 ? 10 : 8,
                            fontWeight: FontWeight.bold,
                            color: normalizedTemp > 0.5 ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildLegend(minTemp, maxTemp),
      ],
    );
  }

  Color _getHeatColor(double normalized) {
    // Gradiente de azul (frío) a rojo (caliente)
    if (normalized < 0.25) {
      // Azul a Cyan
      return Color.lerp(
        const Color(0xFF0000FF),
        const Color(0xFF00FFFF),
        normalized * 4,
      )!;
    } else if (normalized < 0.5) {
      // Cyan a Verde
      return Color.lerp(
        const Color(0xFF00FFFF),
        const Color(0xFF00FF00),
        (normalized - 0.25) * 4,
      )!;
    } else if (normalized < 0.75) {
      // Verde a Amarillo
      return Color.lerp(
        const Color(0xFF00FF00),
        const Color(0xFFFFFF00),
        (normalized - 0.5) * 4,
      )!;
    } else {
      // Amarillo a Rojo
      return Color.lerp(
        const Color(0xFFFFFF00),
        const Color(0xFFFF0000),
        (normalized - 0.75) * 4,
      )!;
    }
  }

  Widget _buildLegend(double minTemp, double maxTemp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(const Color(0xFF0000FF), 'Frío'),
        const SizedBox(width: 5),
        _buildLegendItem(const Color(0xFF00FFFF), ''),
        const SizedBox(width: 5),
        _buildLegendItem(const Color(0xFF00FF00), 'Medio'),
        const SizedBox(width: 5),
        _buildLegendItem(const Color(0xFFFFFF00), ''),
        const SizedBox(width: 5),
        _buildLegendItem(const Color(0xFFFF0000), 'Caliente'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ],
    );
  }
}
