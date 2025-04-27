import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:math_expressions/math_expressions.dart';

class FunctionPlot extends StatelessWidget {
  final String equation;
  final double xMin;
  final double xMax;
  final List<double>? roots;

  const FunctionPlot({
    Key? key,
    required this.equation,
    this.xMin = -10,
    this.xMax = 10,
    this.roots,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<FlSpot> points = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      // Process the equation
      String processedEquation = equation.replaceAll('√', 'sqrt');
      final parser = Parser();
      final exp = parser.parse(processedEquation);
      final context = ContextModel();

      // Generate points for the function
      final step = (xMax - xMin) / 150; // More points for smoother plot
      for (double x = xMin; x <= xMax; x += step) {
        context.bindVariable(Variable('x'), Number(x));
        double? y = exp.evaluate(EvaluationType.REAL, context) as double?;

        if (y != null && y.isFinite && y.abs() < 1000) {
          points.add(FlSpot(x, y));
        }
      }
    } catch (e) {
      print('Error plotting function: $e');
      return Center(
        child: Text('Could not plot equation: $e',
            style: TextStyle(color: Colors.red)),
      );
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 1,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 2,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 2,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                  width: 1),
            ),
            minX: xMin,
            maxX: xMax,
            minY: -10,
            maxY: 10,
            lineBarsData: [
              LineChartBarData(
                spots: points,
                isCurved: true,
                color: Colors.indigo,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: false,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.indigo.withOpacity(0.2),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: isDark
                    ? Colors.grey[800]!.withOpacity(0.8)
                    : Colors.blueGrey.withOpacity(0.8),
              ),
              handleBuiltInTouches: true,
            ),
            // Add markers for roots if available
            extraLinesData: roots != null
                ? ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: Colors.red.withOpacity(0.8),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      ),
                    ],
                    verticalLines: roots!
                        .map((root) => VerticalLine(
                              x: root,
                              color: Colors.green,
                              strokeWidth: 2,
                              label: VerticalLineLabel(
                                show: true,
                                alignment: Alignment.topCenter,
                                padding: const EdgeInsets.only(bottom: 8),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                labelResolver: (line) => 'Root',
                              ),
                            ))
                        .toList(),
                  )
                : ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: Colors.red.withOpacity(0.8),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
