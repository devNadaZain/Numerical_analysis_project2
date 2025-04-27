import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../controllers/root_controller.dart';
import '../controllers/numerical_method.dart';
import 'function_plot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:flutter/services.dart'; // For clipboard access

class HomeScreen extends StatefulWidget {
  final String? initialMethod;

  const HomeScreen({Key? key, this.initialMethod}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final RootController controller = RootController();
  final TextEditingController equationController = TextEditingController();
  final TextEditingController xlController = TextEditingController();
  final TextEditingController xuController = TextEditingController();
  final TextEditingController iterationsController =
      TextEditingController(text: '100');
  final TextEditingController toleranceController =
      TextEditingController(text: '0.0001');
  final TextEditingController matrixSizeController =
      TextEditingController(text: '3');
  final TextEditingController decimalPlacesController =
      TextEditingController(text: '6');
  String selectedMethod = 'Bisection';
  String selectedTerminationCriterion =
      'Both'; // 'Iterations', 'Tolerance', or 'Both'
  int decimalPlaces = 6; // Default decimal places
  List<IterationData> iterationData = [];
  List<List<TextEditingController>> matrixControllers = [];
  List<Map<String, dynamic>> calculationHistory = [];
  bool _showEquationKeyboard = false;
  bool _isCalculating = false;
  bool _showFunctionPlot = false;
  bool _showMatrixPreview = false; // For matrix preview
  double? _lastFoundRoot;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _errorMessage;

  // Adjust padding based on screen size
  EdgeInsets _responsivePadding(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width < 360) {
      return EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0);
    } else if (size.width < 600) {
      return EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    } else {
      return EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
    }
  }

  @override
  void initState() {
    super.initState();

    // Set initial method if provided
    if (widget.initialMethod != null) {
      selectedMethod = widget.initialMethod!;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: const Offset(0, 0))
            .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    // Initialize matrix controllers
    _updateMatrixSize(3);

    // Load saved history
    _loadHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    equationController.dispose();
    xlController.dispose();
    xuController.dispose();
    iterationsController.dispose();
    toleranceController.dispose();
    matrixSizeController.dispose();
    decimalPlacesController.dispose();

    // Dispose all matrix controllers
    for (var row in matrixControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  // Load calculation history
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('calculation_history');
      if (historyJson != null) {
        setState(() {
          calculationHistory = historyJson
              .map((item) => Map<String, dynamic>.from(
                  Map<String, dynamic>.from({'data': item})))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  // Save calculation to history
  Future<void> _saveToHistory(
      String method, String equation, dynamic result) async {
    try {
      final calcData = {
        'method': method,
        'equation': equation,
        'timestamp': DateTime.now().toIso8601String(),
        'result': result.toString(),
      };

      setState(() {
        calculationHistory.insert(0, calcData);
        if (calculationHistory.length > 20) {
          calculationHistory.removeLast();
        }
      });

      final prefs = await SharedPreferences.getInstance();
      final historyJson =
          calculationHistory.map((item) => item.toString()).toList();
      await prefs.setStringList('calculation_history', historyJson);
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  void _updateMatrixSize(int size) {
    if (size < 1) size = 1;
    if (size > 20) size = 20;

    // Dispose existing controllers first
    for (var row in matrixControllers) {
      for (var ctrl in row) {
        ctrl.dispose();
      }
    }

    // Save current values
    List<List<String>> currentValues = matrixControllers.isNotEmpty
        ? List.generate(
            matrixControllers.length,
            (i) => List.generate(matrixControllers[i].length,
                (j) => matrixControllers[i][j].text))
        : [];

    setState(() {
      // Create new controllers
      matrixControllers = List.generate(
          size, (i) => List.generate(size + 1, (j) => TextEditingController()));

      // Restore values
      for (int i = 0; i < currentValues.length && i < size; i++) {
        for (int j = 0; j < currentValues[i].length && j < size + 1; j++) {
          matrixControllers[i][j].text = currentValues[i][j];
        }
      }
    });
  }

  // Update decimal places
  void _updateDecimalPlaces(String value) {
    int? places = int.tryParse(value);
    if (places != null && places >= 0 && places <= 15) {
      setState(() {
        decimalPlaces = places;
      });
    }
  }

  // Generate a preview of the matrix
  String _getMatrixPreview() {
    try {
      int size = int.tryParse(matrixSizeController.text) ?? 3;
      List<List<double>> matrix = List.generate(
          size,
          (i) => List.generate(size + 1, (j) {
                if (matrixControllers[i][j].text.trim().isEmpty) {
                  return 0.0;
                }
                return double.tryParse(matrixControllers[i][j].text) ?? 0.0;
              }));

      String preview = '';
      for (int i = 0; i < size; i++) {
        String row = '|  ';
        for (int j = 0; j < size; j++) {
          row += '${matrix[i][j]}  ';
        }
        row += '|  ${matrix[i][size]}  |';
        preview += '$row\n';
      }
      return preview;
    } catch (e) {
      return 'Invalid matrix values';
    }
  }

  bool _requiresUpperBound() =>
      selectedMethod == 'Bisection' ||
      selectedMethod == 'False Position' ||
      selectedMethod == 'Secant';

  bool _requiresDerivative() => false; // for handled automatically

  bool _isMatrixMethod() =>
      selectedMethod == 'Gauss Elimination' ||
      selectedMethod == 'Gauss Elimination With P.P' ||
      selectedMethod == 'LU Decomposition' ||
      selectedMethod == 'LU Decomposition With P.P' ||
      selectedMethod == "Cramer's Rule" ||
      selectedMethod == 'Gauss Jordan Elimination' ||
      selectedMethod == 'Gauss Jordan Elimination With P.P';

  bool _isRootFindingMethod() => !_isMatrixMethod();

  String _getLowerBoundLabel() =>
      selectedMethod == 'Bisection' || selectedMethod == 'False Position'
          ? 'Lower Bound (xl)'
          : 'Initial Guess (xi)';

  List<DataColumn> _getColumns() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final columnColor = isDark ? Colors.indigo[200] : Colors.indigo;

    if (iterationData.isEmpty) return [];

    if (iterationData.length == 1 &&
        iterationData[0].values.containsKey('Error')) {
      return [
        DataColumn(
            label: Text('Error',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: columnColor))),
        DataColumn(
            label: Text('',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: columnColor))),
      ];
    }

    switch (selectedMethod) {
      case 'Bisection':
      case 'False Position':
        return [
          'iteration',
          'xl',
          'f(xl)',
          'xu',
          'f(xu)',
          'xr',
          'f(xr)',
          'Error %'
        ]
            .map((key) => DataColumn(
                label: Text(key,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: columnColor))))
            .toList();
      case 'Simple Fixed Point':
        return ['i', 'Xi', 'G(Xi)', 'E']
            .map((key) => DataColumn(
                label: Text(key,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: columnColor))))
            .toList();
      case 'Newton-Raphson':
        return ['i', 'Xi', 'F(Xi)', 'F\'(Xi)', 'E']
            .map((key) => DataColumn(
                label: Text(key,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: columnColor))))
            .toList();
      case 'Secant':
        return ['i', 'Xi', 'F(Xi)', 'E']
            .map((key) => DataColumn(
                label: Text(key,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: columnColor))))
            .toList();
      case 'Gauss Elimination':
      case 'Gauss Elimination With P.P':
      case 'LU Decomposition':
      case 'LU Decomposition With P.P':
      case "Cramer's Rule":
      case 'Gauss Jordan Elimination':
      case 'Gauss Jordan Elimination With P.P':
        return [
          DataColumn(
              label: Text('Step',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: columnColor))),
          DataColumn(
              label: Text('Matrix/Solution',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: columnColor))),
        ];
      default:
        return [];
    }
  }

  List<DataRow> _getRows() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.grey[800];

    if (iterationData.isEmpty) return [];
    if (iterationData.length == 1 &&
        iterationData[0].values.containsKey('Error')) {
      return [
        DataRow(cells: [
          DataCell(Text(iterationData[0].values['Error'],
              style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.red[300] : Colors.red[700]))),
          DataCell(Container()), // Add empty cell to match 2 columns
        ])
      ];
    }
    switch (selectedMethod) {
      case 'Bisection':
      case 'False Position':
        return iterationData
            .map((data) => DataRow(cells: [
                  DataCell(Text((data.values['iteration'] ?? 0).toString(),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['xl'] ?? 0.0).toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['f(xl)'] ?? 0.0)
                          .toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['xu'] ?? 0.0).toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['f(xu)'] ?? 0.0)
                          .toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['xr'] ?? 0.0).toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['f(xr)'] ?? 0.0)
                          .toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['Error %'] ?? 0.0)
                          .toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                ]))
            .toList();
      case 'Simple Fixed Point':
        return iterationData
            .map((data) => DataRow(cells: [
                  DataCell(Text((data.values['i'] ?? 0).toString(),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['Xi'] ?? 0.0).toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['G(Xi)'] ?? 0.0)
                          .toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text((data.values['E'] ?? '---').toString(),
                      style: TextStyle(fontSize: 16, color: textColor))),
                ]))
            .toList();
      case 'Newton-Raphson':
        return iterationData
            .map((data) => DataRow(cells: [
                  DataCell(Text((data.values['i'] ?? 0).toString(),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['Xi'] ?? 0.0).toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['F(Xi)'] ?? 0.0)
                          .toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['F\'(Xi)'] ?? 0.0)
                          .toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['E'] ?? 0.0) == 0.0
                          ? '---'
                          : '${(data.values['E'] ?? 0.0).toStringAsFixed(decimalPlaces)}%',
                      style: TextStyle(fontSize: 16, color: textColor))),
                ]))
            .toList();
      case 'Secant':
        return iterationData
            .map((data) => DataRow(cells: [
                  DataCell(Text((data.values['i'] ?? 0).toString(),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['Xi'] ?? 0.0).toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['F(Xi)'] ?? 0.0)
                          .toStringAsFixed(decimalPlaces),
                      style: TextStyle(fontSize: 16, color: textColor))),
                  DataCell(Text(
                      (data.values['E'] ?? 0.0) == 0.0
                          ? '---'
                          : '${(data.values['E'] ?? 0.0).toStringAsFixed(decimalPlaces)}%',
                      style: TextStyle(fontSize: 16, color: textColor))),
                ]))
            .toList();
      case 'Gauss Elimination':
      case 'Gauss Elimination With P.P':
      case 'LU Decomposition':
      case 'LU Decomposition With P.P':
      case "Cramer's Rule":
      case 'Gauss Jordan Elimination':
      case 'Gauss Jordan Elimination With P.P':
        // handled separately in the _buildMatrixResult method
        return [];
      default:
        return [];
    }
  }

  // Add method to display matrix results
  Widget _buildMatrixResult() {
    if (iterationData.isEmpty || !_isMatrixMethod()) return Container();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check for error first
    if (iterationData.length == 1 &&
        iterationData[0].values.containsKey('Error')) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: ${iterationData[0].values['Error']}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    // Display steps for matrix methods
    if (iterationData[0].values.containsKey('steps')) {
      List<String> steps = iterationData[0].values['steps'];

      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Solution Steps',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Add Copy Results button for matrix methods
                  ElevatedButton.icon(
                    onPressed: () => _copyResultsToClipboard(),
                    icon: Icon(Icons.copy, size: 18),
                    label: Text('Copy Results'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.purple[700] : Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...steps
                  .map(
                    (step) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          step,
                          style: GoogleFonts.firaCode(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      );
    }

    return Container();
  }

  Widget _buildEquationInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Visibility(
      visible: _isRootFindingMethod(),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: _responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Function',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Add derivative display for Newton-Raphson
              if (selectedMethod == 'Newton-Raphson' &&
                  iterationData.isNotEmpty &&
                  !iterationData[0].values.containsKey('Error'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.indigo.withOpacity(0.2)
                          : Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.indigo.withOpacity(0.5)
                            : Colors.indigo.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.functions,
                          color: isDark ? Colors.indigo[300] : Colors.indigo,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Calculated Derivative: ${iterationData[0].values['Derivative'] ?? 'Not available'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              TextFormField(
                controller: equationController,
                decoration: InputDecoration(
                  hintText: 'e.g., x^2-4*x+4',
                  labelText: 'f(x)',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.indigo[200] : Colors.indigo,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showEquationKeyboard
                          ? Icons.keyboard_hide
                          : Icons.keyboard,
                      color: isDark ? Colors.indigo[300] : Colors.indigo,
                    ),
                    onPressed: () {
                      setState(() {
                        _showEquationKeyboard = !_showEquationKeyboard;
                      });
                    },
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: isDark ? Colors.indigo[300]! : Colors.indigo,
                        width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              if (_showEquationKeyboard) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildKeyboardButton('x'),
                      _buildKeyboardButton('+'),
                      _buildKeyboardButton('-'),
                      _buildKeyboardButton('*'),
                      _buildKeyboardButton('/'),
                      _buildKeyboardButton('^'),
                      _buildKeyboardButton('('),
                      _buildKeyboardButton(')'),
                      _buildKeyboardButton('sqrt()'),
                      _buildKeyboardButton('sin()'),
                      _buildKeyboardButton('cos()'),
                      _buildKeyboardButton('tan()'),
                      _buildKeyboardButton('e'),
                      _buildKeyboardButton('π'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardButton(String text, {bool isDerivative = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton(
      onPressed: () {
        final controller = equationController;
        final currentText = controller.text;
        final cursorPosition = controller.selection.baseOffset;

        if (cursorPosition >= 0) {
          final newText = currentText.substring(0, cursorPosition) +
              text +
              currentText.substring(cursorPosition);
          controller.text = newText;
          controller.selection =
              TextSelection.collapsed(offset: cursorPosition + text.length);
        } else {
          controller.text += text;
        }
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        foregroundColor: isDark ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildBoundsInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Visibility(
      visible: !_isMatrixMethod(),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: _responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Initial Values',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: xlController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: _getLowerBoundLabel(),
                        labelStyle: TextStyle(
                          color: isDark ? Colors.indigo[200] : Colors.indigo,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  isDark ? Colors.indigo[300]! : Colors.indigo,
                              width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Visibility(
                      visible: _requiresUpperBound(),
                      child: TextFormField(
                        controller: xuController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Upper Bound (xu)',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.indigo[200] : Colors.indigo,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.indigo[300]!
                                    : Colors.indigo,
                                width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Termination Criteria Selection
              Text(
                'Termination Criteria',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Iterations',
                          groupValue: selectedTerminationCriterion,
                          activeColor:
                              isDark ? Colors.indigo[300] : Colors.indigo,
                          onChanged: (value) {
                            setState(() {
                              selectedTerminationCriterion = value!;
                            });
                          },
                        ),
                        Text(
                          'Maximum Iterations',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Tolerance',
                          groupValue: selectedTerminationCriterion,
                          activeColor:
                              isDark ? Colors.indigo[300] : Colors.indigo,
                          onChanged: (value) {
                            setState(() {
                              selectedTerminationCriterion = value!;
                            });
                          },
                        ),
                        Text(
                          'Error Tolerance',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Both',
                          groupValue: selectedTerminationCriterion,
                          activeColor:
                              isDark ? Colors.indigo[300] : Colors.indigo,
                          onChanged: (value) {
                            setState(() {
                              selectedTerminationCriterion = value!;
                            });
                          },
                        ),
                        Text(
                          'Both Criteria',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Conditional display of iteration and tolerance fields
              if (selectedTerminationCriterion == 'Iterations' ||
                  selectedTerminationCriterion == 'Both')
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: iterationsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Maximum Iterations',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.indigo[200] : Colors.indigo,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: isDark ? Colors.indigo[300]! : Colors.indigo,
                            width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      ),
                      prefixIcon: Icon(
                        Icons.repeat,
                        color: isDark ? Colors.indigo[300] : Colors.indigo,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),

              if (selectedTerminationCriterion == 'Tolerance' ||
                  selectedTerminationCriterion == 'Both')
                TextFormField(
                  controller: toleranceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Error Tolerance',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.indigo[200] : Colors.indigo,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? Colors.indigo[300]! : Colors.indigo,
                          width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color:
                              isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                    prefixIcon: Icon(
                      Icons.percent,
                      color: isDark ? Colors.indigo[300] : Colors.indigo,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),

              // Display decimal places only for root finding methods (not needed to use in solve matrix)
              if (_isRootFindingMethod()) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: decimalPlacesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Decimal Places',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.indigo[200] : Colors.indigo,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? Colors.indigo[300]! : Colors.indigo,
                          width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color:
                              isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                    prefixIcon: Icon(
                      Icons.format_list_numbered,
                      color: isDark ? Colors.indigo[300] : Colors.indigo,
                    ),
                  ),
                  onChanged: _updateDecimalPlaces,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Visibility(
      visible: _isMatrixMethod(),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: _responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Matrix Input',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: matrixSizeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Matrix Size',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.purple[200] : Colors.purple,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  isDark ? Colors.purple[300]! : Colors.purple,
                              width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                        ),
                      ),
                      onChanged: (value) {
                        int? size = int.tryParse(value);
                        if (size != null && size >= 1 && size <= 10) {
                          _updateMatrixSize(size);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: Icon(_showMatrixPreview
                        ? Icons.visibility_off
                        : Icons.visibility),
                    label: Text(
                        _showMatrixPreview ? 'Hide Preview' : 'Preview Matrix'),
                    onPressed: () {
                      setState(() {
                        _showMatrixPreview = !_showMatrixPreview;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.purple[700] : Colors.purple,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Matrix Preview
              if (_showMatrixPreview) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matrix Preview',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          _getMatrixPreview(),
                          style: GoogleFonts.firaCode(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Text(
                'Augmented Matrix A|b:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < matrixControllers.length; i++) ...[
                Row(
                  children: [
                    for (int j = 0; j < matrixControllers[i].length; j++) ...[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 4.0),
                          child: TextFormField(
                            controller: matrixControllers[i][j],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              labelText: j == matrixControllers[i].length - 1
                                  ? 'b${i + 1}'
                                  : 'a${i + 1}${j + 1}',
                              labelStyle: TextStyle(
                                color:
                                    isDark ? Colors.purple[200] : Colors.purple,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              filled: true,
                              fillColor: isDark
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.purple.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.purple[300]!
                                      : Colors.purple,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.purple.withOpacity(0.3)
                                      : Colors.purple.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (j == matrixControllers[i].length - 2) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '=',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCalculating ? null : _calculateRoot,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? (_isMatrixMethod() ? Colors.purple[700] : Colors.indigo[700])
              : (_isMatrixMethod() ? Colors.purple : Colors.indigo),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isCalculating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isMatrixMethod() ? 'Solve Matrix' : 'Find Root',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildFunctionPlot() {
    if (!_showFunctionPlot ||
        !_isRootFindingMethod() ||
        _lastFoundRoot == null) {
      return Container();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Function Plot',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 300, // Fixed height for the plot
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FunctionPlot(
                  equation: equationController.text,
                  xMin: _lastFoundRoot! - 5,
                  xMax: _lastFoundRoot! + 5,
                  roots: [_lastFoundRoot!],
                ),
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.indigo.withOpacity(0.2)
                    : Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.indigo.withOpacity(0.5)
                      : Colors.indigo.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.indigo[300] : Colors.indigo,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Root found at x = ${_lastFoundRoot!.toStringAsFixed(decimalPlaces)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (iterationData.isEmpty) return Container();
    // Handling for matrix methods
    if (_isMatrixMethod()) {
      return _buildMatrixResult();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: _responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Results',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Add Copy Results button
                ElevatedButton.icon(
                  onPressed: () => _copyResultsToClipboard(),
                  icon: Icon(Icons.copy, size: 18),
                  label: Text('Copy Results'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.indigo[700] : Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (iterationData.isNotEmpty &&
                !iterationData[0].values.containsKey('Error'))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.green.withOpacity(0.2)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.green.withOpacity(0.5)
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: isDark ? Colors.green[300] : Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Calculation completed successfully',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                  return isDark ? Colors.grey[800]! : Colors.grey[200]!;
                }),
                dataRowHeight: 56,
                headingRowHeight: 56,
                dividerThickness: 1,
                border: TableBorder.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  borderRadius: BorderRadius.circular(8),
                ),
                columns: _getColumns(),
                rows: _getRows(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateRoot() async {
    if (_isCalculating) return;

    setState(() {
      _isCalculating = true;
      _errorMessage = null;
      _showFunctionPlot = false; // Reset plot visibility
      _lastFoundRoot = null; // Reset last found root
    });

    try {
      // Validation
      if (!_isMatrixMethod() && equationController.text.trim().isEmpty) {
        throw 'Please enter an equation';
      }

      double? xl = double.tryParse(xlController.text);
      double? xu = double.tryParse(xuController.text);

      // Set max iterations and tolerance based on selected criteria
      int maxIterations = 100;
      double tolerance = 0.0001;

      if (selectedTerminationCriterion == 'Iterations' ||
          selectedTerminationCriterion == 'Both') {
        maxIterations = int.tryParse(iterationsController.text) ?? 100;
      }

      if (selectedTerminationCriterion == 'Tolerance' ||
          selectedTerminationCriterion == 'Both') {
        tolerance = double.tryParse(toleranceController.text) ?? 0.0001;
      }

      if (!_isMatrixMethod() && xl == null) {
        throw 'Please enter a valid initial value';
      }

      if (_requiresUpperBound() && xu == null) {
        throw 'Please enter a valid upper bound';
      }

      List<List<double>>? matrix;
      if (_isMatrixMethod()) {
        int matrixSize = int.tryParse(matrixSizeController.text) ?? 3;
        matrix = List.generate(
            matrixSize,
            (i) => List.generate(matrixSize + 1, (j) {
                  if (matrixControllers[i][j].text.trim().isEmpty) {
                    throw 'Please fill all matrix elements';
                  }
                  return double.parse(matrixControllers[i][j].text);
                }));
      }

      // Set the method in the controller
      controller.setMethod(selectedMethod);

      // Calculate the root for all methods using calculateSolutionWithIterations
      List<IterationData> result =
          await controller.calculateSolutionWithIterations(
        equation: equationController.text,
        initialXLower: xl ?? 0,
        initialXUpper: xu,
        maxIterations: maxIterations,
        tolerance: tolerance,
        matrix: matrix,
        decimalPlaces: decimalPlaces,
      );

      if (result.isNotEmpty && !result[0].values.containsKey('Error')) {
        // Find the last valid result for root finding methods
        if (_isRootFindingMethod()) {
          dynamic lastRoot;
          if (selectedMethod == 'Bisection' ||
              selectedMethod == 'False Position') {
            lastRoot = result.last.values['xr'];
          } else if (selectedMethod == 'Newton-Raphson' ||
              selectedMethod == 'Secant' ||
              selectedMethod == 'Simple Fixed Point') {
            lastRoot = result.last.values['Xi'];
          }

          if (lastRoot != null && lastRoot is double) {
            _lastFoundRoot = lastRoot;
            _showFunctionPlot = true;
          }
        }

        // Save to history
        _saveToHistory(
            selectedMethod, equationController.text, result.last.iteration);
      }

      setState(() {
        iterationData = result;
      });
    } catch (e, stackTrace) {
      print('Error calculating root: $e');
      print('StackTrace: $stackTrace');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  void _copyResultsToClipboard() {
    if (iterationData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No results to copy'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Use the controller's formatting method
    String formattedData = controller.formatIterationDataForClipboard(
        iterationData, selectedMethod, decimalPlaces);

    Clipboard.setData(ClipboardData(text: formattedData)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Results copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedMethod,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: $_errorMessage',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width < 600 ? 16.0 : size.width * 0.1,
                  vertical: 16.0,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 800,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildEquationInput(),
                          _buildBoundsInput(),
                          _buildMatrixInput(),
                          _buildCalculateButton(),
                          _buildFunctionPlot(),
                          _buildResultTable(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
