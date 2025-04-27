import 'package:math_expressions/math_expressions.dart';
import 'numerical_method.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RootController {
  String _method = 'Bisection';

  void setMethod(String method) {
    _method = method;
  }

  // Updated to be asynchronous
  Future<List<IterationData>> calculateSolutionWithIterations({
    required String equation,
    required double initialXLower,
    double? initialXUpper,
    int maxIterations = 100,
    double tolerance = 0.0001,
    List<List<double>>? matrix,
    int decimalPlaces = 6,
  }) async {
    try {
      switch (_method) {
        case 'Bisection':
          if (initialXUpper == null) {
            return [
              IterationData(0, {'Error': 'Upper bound required'})
            ];
          }
          return await _bisectionMethod(equation, initialXLower, initialXUpper,
              maxIterations, tolerance, decimalPlaces);
        case 'False Position':
          if (initialXUpper == null) {
            return [
              IterationData(0, {'Error': 'Upper bound required'})
            ];
          }
          return await _falsePositionMethod(equation, initialXUpper,
              initialXLower, maxIterations, tolerance, decimalPlaces);
        case 'Simple Fixed Point':
          return await _simpleFixedPointMethod(
              equation, initialXLower, maxIterations, tolerance, decimalPlaces);
        case 'Newton-Raphson':
          if (equation.isEmpty) {
            return [
              IterationData(0, {'Error': 'Equation required'})
            ];
          }
          return await _newtonMethod(
              equation, initialXLower, maxIterations, tolerance, decimalPlaces);
        case 'Secant':
          if (initialXUpper == null) {
            return [
              IterationData(0, {'Error': 'Second initial guess required'})
            ];
          }
          return await _secantMethod(equation, initialXLower, initialXUpper,
              maxIterations, tolerance, decimalPlaces);
        case 'Gauss Elimination':
          if (matrix == null) {
            return [
              IterationData(0, {'Error': 'Matrix required'})
            ];
          }
          return await _gaussEliminationMethod(
              matrix, maxIterations, tolerance, decimalPlaces);
        case 'Gauss Elimination With P.P':
          if (matrix == null) {
            return [
              IterationData(0, {'Error': 'Matrix required'})
            ];
          }
          return await _gaussEliminationWithP_PMethod(
              matrix, maxIterations, tolerance, decimalPlaces);
        case 'LU Decomposition':
          if (matrix == null) {
            return [
              IterationData(0, {'Error': 'Matrix required'})
            ];
          }
          return await _luDecompositionMethod(
              matrix, maxIterations, tolerance, decimalPlaces);
        case 'LU Decomposition With P.P':
          if (matrix == null) {
            return [
              IterationData(0, {'Error': 'Matrix required'})
            ];
          }
          return await _luDecompositionWithP_PMethod(
              matrix, maxIterations, tolerance, decimalPlaces);
        case "Cramer's Rule":
          if (matrix == null) {
            return [
              IterationData(0, {'Error': 'Matrix required'})
            ];
          }
          return await _cramersRuleMethod(
              matrix, maxIterations, tolerance, decimalPlaces);
        case 'Gauss Jordan Elimination':
          if (matrix == null) {
            return [
              IterationData(0, {'Error': 'Matrix required'})
            ];
          }
          return await _gaussJordanMethod(
              matrix, maxIterations, tolerance, decimalPlaces);
        case 'Gauss Jordan Elimination With P.P':
          if (matrix == null) {
            return [
              IterationData(0, {'Error': 'Matrix required'})
            ];
          }
          return await _gaussJordanWithP_PMethod(
              matrix, maxIterations, tolerance, decimalPlaces);
        default:
          return [
            IterationData(0, {'Error': 'Unknown method: $_method'})
          ];
      }
    } catch (e) {
      return [
        IterationData(0, {'Error': 'Unexpected error: $e'})
      ];
    }
  }

  // Method to round values
  double _round(double value, int places) {
    if (places <= 0) return value.roundToDouble();
    double mod = pow(10.0, places).toDouble();
    return ((value * mod).roundToDouble() / mod);
  }

  // Format matrix as string
  String _formatMatrix(List<List<double>> matrix, int decimalPlaces) {
    String result = '';
    for (var row in matrix) {
      String rowStr = '[ ';
      for (var value in row) {
        rowStr +=
            '${_round(value, decimalPlaces).toStringAsFixed(decimalPlaces)} ';
      }
      rowStr += ']';
      result += '$rowStr\n';
    }
    return result;
  }

  // Format vector as string
  String _formatVector(List<double> vector, int decimalPlaces) {
    String result = '[ ';
    for (var value in vector) {
      result +=
          '${_round(value, decimalPlaces).toStringAsFixed(decimalPlaces)} ';
    }
    result += ']';
    return result;
  }

  Future<List<IterationData>> _bisectionMethod(String equation, double xl,
      double xu, int maxIterations, double eps, int decimalPlaces) async {
    List<IterationData> iterations = [];
    double iter = 0;
    double xr = 0;
    double xrOld = 0;
    double error = 100;

    String processedEquation = equation.replaceAll('√', 'sqrt');
    if (processedEquation.isEmpty || !processedEquation.contains('x')) {
      return [
        IterationData(0, {'Error': 'Invalid equation'})
      ];
    }

    final parser = Parser();
    late Expression exp;
    try {
      exp = parser.parse(processedEquation);
    } catch (e) {
      return [
        IterationData(0, {'Error': 'Failed to parse equation: $e'})
      ];
    }

    final context = ContextModel();
    double f(double x) {
      context.bindVariable(Variable('x'), Number(x));
      var result = exp.evaluate(EvaluationType.REAL, context) as double?;
      return (result != null && result.isFinite) ? result : double.nan;
    }

    if (f(xl) * f(xu) >= 0) {
      return [
        IterationData(0, {'Error': 'Bounds do not bracket a root'})
      ];
    }

    do {
      xrOld = xr;
      xr = (xl + xu) / 2;
      error = xrOld == 0 ? 100 : ((xr - xrOld).abs() / xr.abs()) * 100;

      double fxl = f(xl);
      double fxu = f(xu);
      double fxr = f(xr);
      if (fxl.isNaN || fxu.isNaN || fxr.isNaN) {
        return [
          IterationData(0, {'Error': 'Function evaluation failed'})
        ];
      }

      iterations.add(IterationData(iter.toInt(), {
        'iteration': iter,
        'xl': _round(xl, decimalPlaces),
        'f(xl)': _round(fxl, decimalPlaces),
        'xu': _round(xu, decimalPlaces),
        'f(xu)': _round(fxu, decimalPlaces),
        'xr': _round(xr, decimalPlaces),
        'f(xr)': _round(fxr, decimalPlaces),
        'Error %': _round(error, decimalPlaces),
      }));

      if (f(xl) * f(xr) > 0) {
        xl = xr;
      } else {
        xu = xr;
      }
      iter++;
    } while (error > eps && iter < maxIterations);

    return iterations;
  }

  Future<List<IterationData>> _falsePositionMethod(String equation, double xl,
      double xu, int maxIterations, double eps, int decimalPlaces) async {
    List<IterationData> iterations = [];
    double iter = 0;
    double xr = 0;
    double xrOld = 0;
    double error = 100;

    String processedEquation = equation.replaceAll('√', 'sqrt');
    if (processedEquation.isEmpty || !processedEquation.contains('x')) {
      return [
        IterationData(0, {'Error': 'Invalid equation'})
      ];
    }

    final parser = Parser();
    late Expression exp;
    try {
      exp = parser.parse(processedEquation);
    } catch (e) {
      return [
        IterationData(0, {'Error': 'Failed to parse equation: $e'})
      ];
    }

    final context = ContextModel();
    double f(double x) {
      context.bindVariable(Variable('x'), Number(x));
      var result = exp.evaluate(EvaluationType.REAL, context) as double?;
      return (result != null && result.isFinite) ? result : double.nan;
    }

    if (f(xl) * f(xu) >= 0) {
      return [
        IterationData(0, {'Error': 'Bounds do not bracket a root'})
      ];
    }

    do {
      xrOld = xr;
      double fxl = f(xl);
      double fxu = f(xu);
      if (fxl.isNaN || fxu.isNaN) {
        return [
          IterationData(0, {'Error': 'Function evaluation failed'})
        ];
      }
      double denominator = fxl - fxu;
      if (denominator == 0) {
        return [
          IterationData(0, {'Error': 'Denominator is zero'})
        ];
      }
      xr = xu - (fxu * (xl - xu)) / denominator;
      error = xrOld == 0 ? 100 : ((xr - xrOld).abs() / xr.abs()) * 100;

      double fxr = f(xr);
      if (fxr.isNaN) {
        return [
          IterationData(0, {'Error': 'Function evaluation failed'})
        ];
      }

      iterations.add(IterationData(iter.toInt(), {
        'iteration': iter,
        'xl': _round(xl, decimalPlaces),
        'f(xl)': _round(fxl, decimalPlaces),
        'xu': _round(xu, decimalPlaces),
        'f(xu)': _round(fxu, decimalPlaces),
        'xr': _round(xr, decimalPlaces),
        'f(xr)': _round(fxr, decimalPlaces),
        'Error %': _round(error, decimalPlaces),
      }));

      if (f(xl) * f(xr) > 0) {
        xl = xr;
      } else {
        xu = xr;
      }
      iter++;
    } while (error > eps && iter < maxIterations);

    return iterations;
  }

  Future<List<IterationData>> _simpleFixedPointMethod(
      String
          gEquation, // User provides f(x), but signature remains as requested
      double initialGuess,
      int maxIterations,
      double tolerance,
      int decimalPlaces) async {
    List<IterationData> iterations = [];

    // Treat gEquation as f(x) internally
    String fEquation = gEquation;

    // Input validation
    if (fEquation.isEmpty) {
      return [
        IterationData(
            0, {'Error': 'Equation cannot be empty', 'ProcessedEquation': ''})
      ];
    }
    if (!initialGuess.isFinite) {
      return [
        IterationData(0, {
          'Error': 'Invalid initial guess: must be a finite number',
          'ProcessedEquation': ''
        })
      ];
    }
    if (maxIterations <= 0) {
      return [
        IterationData(0, {
          'Error': 'Max iterations must be positive',
          'ProcessedEquation': ''
        })
      ];
    }
    if (tolerance <= 0) {
      return [
        IterationData(
            0, {'Error': 'Tolerance must be positive', 'ProcessedEquation': ''})
      ];
    }
    if (decimalPlaces < 0) {
      return [
        IterationData(0, {
          'Error': 'Decimal places must be non-negative',
          'ProcessedEquation': ''
        })
      ];
    }

    // Log parameters
    print('Parameters: fEquation="$fEquation", initialGuess=$initialGuess, '
        'maxIterations=$maxIterations, tolerance=$tolerance, decimalPlaces=$decimalPlaces');

    // Call the Python API
    try {
      final url = Uri.parse('http://192.168.1.10:5000/fixed_point');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fEquation': fEquation, // Fixed to match server's expected key
          'initialGuess': initialGuess,
          'maxIterations': maxIterations,
          'tolerance': tolerance, // Send as percentage, e.g., 0.2 for 0.2%
          'decimalPlaces': decimalPlaces,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['error'] != null) {
          return [
            IterationData(0, {
              'Error': data['error'],
              'ProcessedEquation': fEquation,
            })
          ];
        }

        final List<dynamic> result = data['iterations'];
        for (var item in result) {
          if (item.containsKey('Error')) {
            return [
              IterationData(item['i'], {
                'Error': item['Error'],
                'ProcessedEquation': fEquation,
              })
            ];
          }
          iterations
              .add(IterationData(item['i'], Map<String, dynamic>.from(item)));
        }
        return iterations;
      } else {
        return [
          IterationData(0, {
            'Error':
                'API request failed with status ${response.statusCode}: ${response.body}',
            'ProcessedEquation': fEquation,
          })
        ];
      }
    } catch (e) {
      return [
        IterationData(0, {
          'Error': 'Network error: ${e.toString()}',
          'ProcessedEquation': fEquation,
        })
      ];
    }
  }

  Future<List<IterationData>> _newtonMethod(
      String equation,
      double initialGuess,
      int maxIterations,
      double tolerance,
      int decimalPlaces) async {
    List<IterationData> iterations = [];
    double currentX = initialGuess;
    double error = 100.0;
    String derivativeString = '';
    String processedEquation = '';

    // Validate parameters
    if (equation.isEmpty) {
      return [
        IterationData(0, {
          'Error': 'Equation cannot be empty',
          'Derivative': derivativeString,
          'ProcessedEquation': ''
        })
      ];
    }
    if (!initialGuess.isFinite) {
      return [
        IterationData(0, {
          'Error': 'Invalid initial guess: must be a finite number',
          'Derivative': derivativeString,
          'ProcessedEquation': ''
        })
      ];
    }
    if (maxIterations <= 0) {
      return [
        IterationData(0, {
          'Error': 'Max iterations must be positive',
          'Derivative': derivativeString,
          'ProcessedEquation': ''
        })
      ];
    }
    if (tolerance <= 0) {
      return [
        IterationData(0, {
          'Error': 'Tolerance must be positive',
          'Derivative': derivativeString,
          'ProcessedEquation': ''
        })
      ];
    }
    if (decimalPlaces < 0) {
      return [
        IterationData(0, {
          'Error': 'Decimal places must be non-negative',
          'Derivative': derivativeString,
          'ProcessedEquation': ''
        })
      ];
    }

    // Log parameters
    print('Parameters: equation=$equation, initialGuess=$initialGuess, '
        'maxIterations=$maxIterations, tolerance=$tolerance, decimalPlaces=$decimalPlaces');

    // Validation function for equation
    String? validateEquation(String equation) {
      if (equation.isEmpty) return 'Equation cannot be empty';
      // Allow numbers, x, operators, functions, decimals
      if (!RegExp(r'^[0-9x\+\-\*\/\^\(\)\s√lnsin,cos,tan,e,.]+$')
          .hasMatch(equation)) {
        return 'Invalid characters in equation';
      }
      // Check balanced parentheses
      int balance = 0;
      for (var char in equation.split('')) {
        if (char == '(') balance++;
        if (char == ')') balance--;
        if (balance < 0) return 'Unbalanced parentheses';
      }
      if (balance != 0) return 'Unbalanced parentheses';
      // Check for invalid patterns (e.g., double operators, trailing operators)
      if (RegExp(r'[\+\-\*\/]{2,}').hasMatch(equation)) {
        return 'Invalid double operators';
      }
      if (RegExp(r'[\+\-\*\/]$').hasMatch(equation.trim())) {
        return 'Equation ends with an operator';
      }
      // Check supported functions
      final supportedFunctions = [
        'sqrt',
        'log',
        'ln',
        'sin',
        'cos',
        'tan',
        'e'
      ];
      final functionPattern =
          RegExp(r'\b(sqrt|log|ln|sin|cos|tan|e)\b(?=\(|$|[^a-zA-Z])');
      final matches = functionPattern.allMatches(equation);
      final foundFunctions = matches.map((m) => m.group(1)!).toSet();
      for (var func in foundFunctions) {
        if (!supportedFunctions.contains(func)) {
          return 'Unsupported function: $func';
        }
      }
      final invalidFunctionPattern = RegExp(r'\b[a-zA-Z]+(?=\()');
      for (var match in invalidFunctionPattern.allMatches(equation)) {
        final func = match.group(0)!;
        if (!supportedFunctions.contains(func) && func != 'x') {
          return 'Unsupported function: $func';
        }
      }
      return null;
    }

    // Validate equation
    String? validationError = validateEquation(equation);
    if (validationError != null) {
      return [
        IterationData(0, {
          'Error': validationError,
          'Derivative': derivativeString,
          'ProcessedEquation': ''
        })
      ];
    }

    try {
      // Pre-process the equation
      processedEquation = equation.replaceAll(' ', '');
      print('After removing spaces: $processedEquation');

      // Handle implicit multiplication (e.g., 2x -> 2*x, -0.9x -> -0.9*x)
      processedEquation = processedEquation.replaceAllMapped(
          RegExp(r'(\-?\d*\.?\d+)([x(])'),
          (match) => '${match.group(1)}*${match.group(2)}');
      print('After implicit multiplication: $processedEquation');

      // Handle parentheses multiplication
      processedEquation = processedEquation
          .replaceAll(')(', ')*(')
          .replaceAll(')x', ')*x')
          .replaceAll('x(', 'x*(');
      print('After parentheses multiplication: $processedEquation');

      // Replace mathematical symbols
      processedEquation = processedEquation
          .replaceAll('√', 'sqrt')
          .replaceAll('ln', 'log')
          .replaceAll('e', '2.718281828459045');
      print('After symbol replacement: $processedEquation');

      // Convert power operator (simple exponents only)
      processedEquation = processedEquation.replaceAllMapped(
          RegExp(r'([a-zA-Z0-9]+)\^(\d+)'),
          (match) =>
              {
                '2':
                    '(${match.group(1)})*(${match.group(1)})' // Handle x^2 as x*x
              }[match.group(2)] ??
              'pow(${match.group(1)},${match.group(2)})');
      print('After power operator conversion: $processedEquation');

      // Add parentheses around decimal coefficients
      processedEquation = processedEquation.replaceAllMapped(
          RegExp(r'(\-?\d+\.\d+)(?=\*)'), (match) => '(${match.group(1)})');
      print('After decimal parentheses: $processedEquation');

      // Debug: Log final processed equation
      print('Final processed equation: $processedEquation');

      // Fallback parse test
      final parser = Parser();
      try {
        parser.parse('x*x'); // Minimal expression
        print('Fallback parse test (x*x) successful');
      } catch (e) {
        print('Fallback parse test (x*x) error: $e');
      }

      // Parse the equation
      final x = Variable('x');
      final context = ContextModel();

      // Test parse
      try {
        parser.parse(processedEquation);
        print('Test parse successful');
      } catch (e) {
        print('Parser test error: $e');
      }

      Expression fExp = parser.parse(processedEquation);
      Expression fDashExp = fExp.derive('x');
      derivativeString = fDashExp.toString();

      // Evaluation functions
      double evaluateAt(double xValue) {
        context.bindVariable(x, Number(xValue));
        return fExp.evaluate(EvaluationType.REAL, context);
      }

      double evaluateDerivativeAt(double xValue) {
        context.bindVariable(x, Number(xValue));
        return fDashExp.evaluate(EvaluationType.REAL, context);
      }

      // Newton-Raphson iteration
      for (int i = 0; i < maxIterations; i++) {
        double fx = evaluateAt(currentX);
        double dfx = evaluateDerivativeAt(currentX);

        // Check for zero derivative
        if (dfx.abs() < 1e-10) {
          return [
            IterationData(0, {
              'Error':
                  'Zero derivative at x = ${currentX.toStringAsFixed(decimalPlaces)}',
              'Derivative': derivativeString,
              'ProcessedEquation': processedEquation
            })
          ];
        }

        double nextX = currentX - fx / dfx;

        // Calculate error
        error = i == 0 ? 100.0 : ((nextX - currentX).abs() / nextX.abs()) * 100;

        iterations.add(IterationData(
          i,
          {
            'i': i,
            'Xi': _round(currentX, decimalPlaces),
            'F(Xi)': _round(fx, decimalPlaces),
            'F\'(Xi)': _round(dfx, decimalPlaces),
            'E': _round(error, decimalPlaces),
            'Derivative': i == 0 ? derivativeString : '',
          },
        ));

        // Check convergence
        if (error < tolerance) {
          break;
        }

        // Check for divergence
        if (nextX.abs() > 1e6) {
          iterations.add(IterationData(
            i + 1,
            {
              'Error': 'Method is diverging',
              'Derivative': derivativeString,
              'ProcessedEquation': processedEquation
            },
          ));
          break;
        }

        currentX = nextX;
      }

      return iterations;
    } catch (e) {
      return [
        IterationData(0, {
          'Error': 'Calculation error: ${e.toString()}',
          'Derivative': derivativeString,
          'ProcessedEquation': processedEquation
        })
      ];
    }
  }

  Future<List<IterationData>> _secantMethod(String equation, double x0,
      double x1, int maxIterations, double eps, int decimalPlaces) async {
    List<IterationData> iterations = [];
    double iter = 0;
    double error = 0;
    double xiMinus1 = x0;
    double xi = x1;

    String processedEquation = equation.replaceAll('√', 'sqrt');
    if (processedEquation.isEmpty || !processedEquation.contains('x')) {
      return [
        IterationData(0, {'Error': 'Invalid equation'})
      ];
    }

    final parser = Parser();
    late Expression exp;
    try {
      exp = parser.parse(processedEquation);
    } catch (e) {
      return [
        IterationData(0, {'Error': 'Failed to parse equation: $e'})
      ];
    }

    final context = ContextModel();
    double f(double x) {
      context.bindVariable(Variable('x'), Number(x));
      var result = exp.evaluate(EvaluationType.REAL, context) as double?;
      return (result != null && result.isFinite) ? result : double.nan;
    }

    double fxiMinus1 = f(xiMinus1);
    double fxi = f(xi);
    if (fxiMinus1.isNaN || fxi.isNaN) {
      return [
        IterationData(0, {'Error': 'Initial evaluation failed'})
      ];
    }

    iterations.add(IterationData(iter.toInt(), {
      'i': iter,
      'Xi': _round(xiMinus1, decimalPlaces),
      'F(Xi)': _round(fxiMinus1, decimalPlaces),
      'E': _round(error, decimalPlaces),
    }));

    iter++;
    iterations.add(IterationData(iter.toInt(), {
      'i': iter,
      'Xi': _round(xi, decimalPlaces),
      'F(Xi)': _round(fxi, decimalPlaces),
      'E': _round(error, decimalPlaces),
    }));

    while (iter < maxIterations) {
      if ((fxi - fxiMinus1).abs() < 1e-10) {
        return [
          IterationData(0, {'Error': 'Division by zero'})
        ];
      }

      double xiPlus1 = xi - fxi * (xi - xiMinus1) / (fxi - fxiMinus1);
      error = xiPlus1 != 0 ? ((xiPlus1 - xi).abs() / xiPlus1.abs()) * 100 : 100;

      if (error <= eps) {
        break;
      }

      iter++;
      xiMinus1 = xi;
      xi = xiPlus1;
      fxiMinus1 = fxi;
      fxi = f(xi);

      if (fxi.isNaN) {
        return [
          IterationData(0, {'Error': 'Evaluation failed at iteration $iter'})
        ];
      }

      iterations.add(IterationData(iter.toInt(), {
        'i': iter,
        'Xi': _round(xi, decimalPlaces),
        'F(Xi)': _round(fxi, decimalPlaces),
        'E': _round(error, decimalPlaces),
      }));
    }

    return iterations;
  }

  // Gauss Elimination Method with steps displayed as matrices
  Future<List<IterationData>> _gaussEliminationMethod(List<List<double>> matrix,
      int maxIterations, double eps, int decimalPlaces) async {
    int n = matrix.length;
    List<String> steps = [];

    // Clone the matrix to avoid modifying the original
    List<List<double>> augmentedMatrix =
        List.generate(n, (i) => List.generate(n + 1, (j) => matrix[i][j]));

    // Initial matrix
    steps.add(
        "Initial Augmented Matrix:\n${_formatMatrix(augmentedMatrix, decimalPlaces)}");

    // Forward elimination
    for (int k = 0; k < n - 1; k++) {
      // Check for zero pivot
      if (augmentedMatrix[k][k].abs() < 1e-10) {
        return [
          IterationData(0, {'Error': 'Zero pivot encountered'})
        ];
      }

      // Eliminate entries below pivot
      for (int i = k + 1; i < n; i++) {
        double factor = augmentedMatrix[i][k] / augmentedMatrix[k][k];
        for (int j = k; j <= n; j++) {
          augmentedMatrix[i][j] -= factor * augmentedMatrix[k][j];
        }
      }

      steps.add(
          "After Elimination (Step ${k + 1}):\n${_formatMatrix(augmentedMatrix, decimalPlaces)}");
    }

    // Back substitution
    List<double> solution = List.filled(n, 0);
    for (int i = n - 1; i >= 0; i--) {
      double sum = 0;
      for (int j = i + 1; j < n; j++) {
        sum += augmentedMatrix[i][j] * solution[j];
      }

      if (augmentedMatrix[i][i].abs() < 1e-10) {
        return [
          IterationData(
              0, {'Error': 'Division by zero during back substitution'})
        ];
      }

      solution[i] = (augmentedMatrix[i][n] - sum) / augmentedMatrix[i][i];
    }

    steps.add("Solution Vector X:\n${_formatVector(solution, decimalPlaces)}");

    return [
      IterationData(0, {'steps': steps})
    ];
  }

  // Gauss Elimination With Partial Pivoting Method with steps displayed as matrices
  Future<List<IterationData>> _gaussEliminationWithP_PMethod(
      List<List<double>> matrix,
      int maxIterations,
      double eps,
      int decimalPlaces) async {
    int n = matrix.length;
    List<String> steps = [];

    // Clone the matrix to avoid modifying the original
    List<List<double>> augmentedMatrix =
        List.generate(n, (i) => List.generate(n + 1, (j) => matrix[i][j]));

    // Initial matrix
    steps.add(
        "Initial Augmented Matrix:\n${_formatMatrix(augmentedMatrix, decimalPlaces)}");

    // Forward elimination
    for (int k = 0; k < n - 1; k++) {
      // Partial pivoting
      int pivotRow = k;
      double pivotValue = augmentedMatrix[k][k].abs();

      for (int i = k + 1; i < n; i++) {
        if (augmentedMatrix[i][k].abs() > pivotValue) {
          pivotRow = i;
          pivotValue = augmentedMatrix[i][k].abs();
        }
      }

      // Check if need to swap rows
      if (pivotRow != k) {
        for (int j = 0; j <= n; j++) {
          double temp = augmentedMatrix[k][j];
          augmentedMatrix[k][j] = augmentedMatrix[pivotRow][j];
          augmentedMatrix[pivotRow][j] = temp;
        }
        steps.add(
            "After Row Swap (R${k + 1} ↔ R${pivotRow + 1}):\n${_formatMatrix(augmentedMatrix, decimalPlaces)}");
      }

      // Check for zero pivot
      if (augmentedMatrix[k][k].abs() < 1e-10) {
        return [
          IterationData(0, {'Error': 'Zero pivot encountered'})
        ];
      }

      // Eliminate entries below pivot
      for (int i = k + 1; i < n; i++) {
        double factor = augmentedMatrix[i][k] / augmentedMatrix[k][k];
        for (int j = k; j <= n; j++) {
          augmentedMatrix[i][j] -= factor * augmentedMatrix[k][j];
        }
      }

      steps.add(
          "After Elimination (Step ${k + 1}):\n${_formatMatrix(augmentedMatrix, decimalPlaces)}");
    }

    // Back substitution
    List<double> solution = List.filled(n, 0);
    for (int i = n - 1; i >= 0; i--) {
      double sum = 0;
      for (int j = i + 1; j < n; j++) {
        sum += augmentedMatrix[i][j] * solution[j];
      }

      if (augmentedMatrix[i][i].abs() < 1e-10) {
        return [
          IterationData(
              0, {'Error': 'Division by zero during back substitution'})
        ];
      }

      solution[i] = (augmentedMatrix[i][n] - sum) / augmentedMatrix[i][i];
    }

    steps.add("Solution Vector X:\n${_formatVector(solution, decimalPlaces)}");

    return [
      IterationData(0, {'steps': steps})
    ];
  }

  // LU Decomposition Method with matrix steps
  Future<List<IterationData>> _luDecompositionMethod(List<List<double>> matrix,
      int maxIterations, double eps, int decimalPlaces) async {
    int n = matrix.length;
    List<String> steps = [];

    // Extract coefficient matrix A and constant vector b
    List<List<double>> A =
        List.generate(n, (i) => List.generate(n, (j) => matrix[i][j]));
    List<double> b = List.generate(n, (i) => matrix[i][n]);

    // Initialize L and U matrices
    List<List<double>> L =
        List.generate(n, (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0));
    List<List<double>> U =
        List.generate(n, (i) => List.generate(n, (j) => 0.0));

    steps.add("Coefficient Matrix A:\n${_formatMatrix(A, decimalPlaces)}");
    steps.add("Constant Vector b:\n${_formatVector(b, decimalPlaces)}");

    // LU Decomposition
    for (int i = 0; i < n; i++) {
      // Upper Triangular (U)
      for (int k = i; k < n; k++) {
        double sum = 0;
        for (int j = 0; j < i; j++) {
          sum += L[i][j] * U[j][k];
        }
        U[i][k] = A[i][k] - sum;
      }

      // Lower Triangular (L)
      for (int k = i + 1; k < n; k++) {
        double sum = 0;
        for (int j = 0; j < i; j++) {
          sum += L[k][j] * U[j][i];
        }

        if (U[i][i].abs() < 1e-10) {
          return [
            IterationData(0, {'Error': 'Division by zero in LU decomposition'})
          ];
        }

        L[k][i] = (A[k][i] - sum) / U[i][i];
      }
    }

    steps.add("Lower Triangular Matrix L:\n${_formatMatrix(L, decimalPlaces)}");
    steps.add("Upper Triangular Matrix U:\n${_formatMatrix(U, decimalPlaces)}");

    // Forward substitution Ly = b
    List<double> y = List.filled(n, 0);
    for (int i = 0; i < n; i++) {
      double sum = 0;
      for (int j = 0; j < i; j++) {
        sum += L[i][j] * y[j];
      }
      y[i] = b[i] - sum;
    }

    steps.add(
        "Intermediate Vector y (from Ly = b):\n${_formatVector(y, decimalPlaces)}");

    // Back substitution Ux = y
    List<double> x = List.filled(n, 0);
    for (int i = n - 1; i >= 0; i--) {
      double sum = 0;
      for (int j = i + 1; j < n; j++) {
        sum += U[i][j] * x[j];
      }

      if (U[i][i].abs() < 1e-10) {
        return [
          IterationData(
              0, {'Error': 'Division by zero during back substitution'})
        ];
      }

      x[i] = (y[i] - sum) / U[i][i];
    }

    steps.add("Solution Vector x:\n${_formatVector(x, decimalPlaces)}");

    return [
      IterationData(0, {'steps': steps})
    ];
  }

  // LU Decomposition Method with partial pivoting
  Future<List<IterationData>> _luDecompositionWithP_PMethod(
      List<List<double>> matrix,
      int maxIterations,
      double eps,
      int decimalPlaces) async {
    int n = matrix.length;
    List<String> steps = [];

    // Extract coefficient matrix A and constant vector b
    List<List<double>> A =
        List.generate(n, (i) => List.generate(n, (j) => matrix[i][j]));
    List<double> bOriginal = List.generate(n, (i) => matrix[i][n]);
    // Keep a separate copy of b that will be permuted
    List<double> b = List.from(bOriginal);

    // Initialize L, U, and permutation matrix P
    List<List<double>> L =
        List.generate(n, (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0));
    List<List<double>> U =
        List.generate(n, (i) => List.generate(n, (j) => 0.0));
    List<List<double>> P =
        List.generate(n, (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0));

    steps.add(
        "Initial Coefficient Matrix A:\n${_formatMatrix(A, decimalPlaces)}");
    steps.add("Initial Constant Vector b:\n${_formatVector(b, decimalPlaces)}");
    steps.add(
        "Initial Permutation Matrix P:\n${_formatMatrix(P, decimalPlaces)}");

    // LU Decomposition with partial pivoting
    for (int i = 0; i < n; i++) {
      // Find pivot
      double maxPivot = A[i][i].abs();
      int pivotRow = i;
      for (int k = i + 1; k < n; k++) {
        if (A[k][i].abs() > maxPivot) {
          maxPivot = A[k][i].abs();
          pivotRow = k;
        }
      }

      // Check for zero pivot
      if (maxPivot < eps) {
        return [
          IterationData(0, {'Error': 'Zero pivot encountered'})
        ];
      }

      // Swap rows if necessary
      if (pivotRow != i) {
        // Swap rows in A
        var tempA = A[i];
        A[i] = A[pivotRow];
        A[pivotRow] = tempA;

        // Swap rows in b
        double tempB = b[i];
        b[i] = b[pivotRow];
        b[pivotRow] = tempB;

        // Swap rows in P
        var tempP = P[i];
        P[i] = P[pivotRow];
        P[pivotRow] = tempP;

        // Swap rows in L (only columns 0 to i-1)
        for (int j = 0; j < i; j++) {
          double tempL = L[i][j];
          L[i][j] = L[pivotRow][j];
          L[pivotRow][j] = tempL;
        }

        steps.add("After Row Swap (R${i + 1} ↔ R${pivotRow + 1}):\n"
            "Matrix A:\n${_formatMatrix(A, decimalPlaces)}\n"
            "Vector b:\n${_formatVector(b, decimalPlaces)}\n"
            "Permutation Matrix P:\n${_formatMatrix(P, decimalPlaces)}");
      }

      // Compute U and L for column i
      U[i][i] = A[i][i];
      for (int k = i + 1; k < n; k++) {
        L[k][i] = A[k][i] / U[i][i];
        U[i][k] = A[i][k];
      }

      // Update remaining submatrix
      for (int k = i + 1; k < n; k++) {
        for (int j = i + 1; j < n; j++) {
          A[k][j] -= L[k][i] * U[i][j];
        }
        A[k][i] = 0.0; // Zero out below pivot
      }

      steps.add(
          "Matrix A after elimination step ${i + 1}:\n${_formatMatrix(A, decimalPlaces)}");
    }

    steps.add("Lower Triangular Matrix L:\n${_formatMatrix(L, decimalPlaces)}");
    steps.add("Upper Triangular Matrix U:\n${_formatMatrix(U, decimalPlaces)}");
    steps
        .add("Final Permutation Matrix P:\n${_formatMatrix(P, decimalPlaces)}");

    // Forward substitution: Ly = Pb
    List<double> pb = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        pb[i] += P[i][j] * b[j];
      }
    }

    steps.add("Permuted Vector Pb:\n${_formatVector(pb, decimalPlaces)}");

    List<double> y = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      double sum = 0.0;
      for (int j = 0; j < i; j++) {
        sum += L[i][j] * y[j];
      }
      y[i] = pb[i] - sum;
      // No division by L[i][i] since L[i][i] = 1
    }

    steps.add(
        "Intermediate Vector y (from Ly = Pb):\n${_formatVector(y, decimalPlaces)}");

    // Back substitution: Ux = y
    List<double> x = List.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      double sum = 0.0;
      for (int j = i + 1; j < n; j++) {
        sum += U[i][j] * x[j];
      }
      if (U[i][i].abs() < eps) {
        return [
          IterationData(
              0, {'Error': 'Division by zero during back substitution'})
        ];
      }
      x[i] = (y[i] - sum) / U[i][i];
    }

    steps.add("Solution Vector x:\n${_formatVector(x, decimalPlaces)}");

    return [
      IterationData(0, {'steps': steps})
    ];
  }

  // Calculate determinant for Cramer's Rule
  double _determinant(List<List<double>> matrix) {
    int n = matrix.length;

    if (n == 1) {
      return matrix[0][0];
    }

    if (n == 2) {
      return matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0];
    }

    double det = 0;
    for (int i = 0; i < n; i++) {
      List<List<double>> subMatrix =
          List.generate(n - 1, (row) => List.generate(n - 1, (col) => 0.0));

      for (int j = 1; j < n; j++) {
        for (int k = 0; k < n; k++) {
          if (k < i) {
            subMatrix[j - 1][k] = matrix[j][k];
          } else if (k > i) {
            subMatrix[j - 1][k - 1] = matrix[j][k];
          }
        }
      }

      det += (i % 2 == 0 ? 1 : -1) * matrix[0][i] * _determinant(subMatrix);
    }

    return det;
  }

  // Cramer's Rule with matrix steps
  Future<List<IterationData>> _cramersRuleMethod(List<List<double>> matrix,
      int maxIterations, double eps, int decimalPlaces) async {
    int n = matrix.length;
    List<String> steps = [];

    // Extract coefficient matrix A and constant vector b
    List<List<double>> A =
        List.generate(n, (i) => List.generate(n, (j) => matrix[i][j]));
    List<double> b = List.generate(n, (i) => matrix[i][n]);

    steps.add("Coefficient Matrix A:\n${_formatMatrix(A, decimalPlaces)}");
    steps.add("Constant Vector b:\n${_formatVector(b, decimalPlaces)}");

    // Calculate determinant of A
    double detA = _determinant(A);
    if (detA.abs() < 1e-10) {
      return [
        IterationData(0, {'Error': 'Determinant of coefficient matrix is zero'})
      ];
    }

    steps.add(
        "Determinant of A: ${_round(detA, decimalPlaces).toStringAsFixed(decimalPlaces)}");

    // Calculate solution using Cramer's rule
    List<double> solution = List.filled(n, 0);
    for (int i = 0; i < n; i++) {
      // Create Ai matrix by replacing ith column with b
      List<List<double>> Ai =
          List.generate(n, (row) => List.generate(n, (col) => A[row][col]));

      for (int j = 0; j < n; j++) {
        Ai[j][i] = b[j];
      }

      steps.add(
          "Matrix A${i + 1} (A with column ${i + 1} replaced by b):\n${_formatMatrix(Ai, decimalPlaces)}");

      // Calculate determinant of Ai
      double detAi = _determinant(Ai);
      steps.add(
          "Determinant of A${i + 1}: ${_round(detAi, decimalPlaces).toStringAsFixed(decimalPlaces)}");

      // Calculate xi = det(Ai) / det(A)
      solution[i] = detAi / detA;
    }

    steps.add("Solution Vector x:\n${_formatVector(solution, decimalPlaces)}");

    return [
      IterationData(0, {'steps': steps})
    ];
  }

  // Gauss-Jordan Elimination Method with matrix steps
  Future<List<IterationData>> _gaussJordanMethod(List<List<double>> matrix,
      int maxIterations, double eps, int decimalPlaces) async {
    int n = matrix.length;
    List<String> steps = [];

    // Create a working copy of the augmented matrix [A | b]
    List<List<double>> augmented =
        List.generate(n, (i) => List.generate(n + 1, (j) => matrix[i][j]));

    steps.add(
        "Initial Augmented Matrix [A | b]:\n${_formatMatrix(augmented, decimalPlaces)}");

    // Gauss-Jordan Elimination without partial pivoting
    for (int i = 0; i < n; i++) {
      // Check for zero pivot
      double pivot = augmented[i][i];
      if (pivot.abs() < eps) {
        return [
          IterationData(0, {'Error': 'Zero pivot encountered at row ${i + 1}'})
        ];
      }

      // Normalize the pivot row (make pivot = 1)
      for (int j = 0; j <= n; j++) {
        augmented[i][j] /= pivot;
      }
      steps.add("After Normalizing Row ${i + 1} (Pivot = 1):\n"
          "Augmented Matrix:\n${_formatMatrix(augmented, decimalPlaces)}");

      // Eliminate column i above and below the pivot
      for (int k = 0; k < n; k++) {
        if (k != i) {
          double factor = augmented[k][i];
          for (int j = 0; j <= n; j++) {
            augmented[k][j] -= factor * augmented[i][j];
          }
        }
      }
      steps.add("After Eliminating Column ${i + 1}:\n"
          "Augmented Matrix:\n${_formatMatrix(augmented, decimalPlaces)}");
    }

    // Extract solution vector x from the last column
    List<double> x = List.generate(n, (i) => augmented[i][n]);
    steps.add("Solution Vector x:\n${_formatVector(x, decimalPlaces)}");

    return [
      IterationData(0, {'steps': steps})
    ];
  }

  // Gauss-Jordan Elimination Method with partial pivoting
  Future<List<IterationData>> _gaussJordanWithP_PMethod(
      List<List<double>> matrix,
      int maxIterations,
      double eps,
      int decimalPlaces) async {
    int n = matrix.length;
    List<String> steps = [];

    // Create a working copy of the augmented matrix [A | b]
    List<List<double>> augmented =
        List.generate(n, (i) => List.generate(n + 1, (j) => matrix[i][j]));

    steps.add(
        "Initial Augmented Matrix [A | b]:\n${_formatMatrix(augmented, decimalPlaces)}");

    // Gauss-Jordan Elimination with partial pivoting
    for (int i = 0; i < n; i++) {
      // Find pivot
      double maxPivot = augmented[i][i].abs();
      int pivotRow = i;
      for (int k = i + 1; k < n; k++) {
        if (augmented[k][i].abs() > maxPivot) {
          maxPivot = augmented[k][i].abs();
          pivotRow = k;
        }
      }

      // Check for zero pivot
      if (maxPivot < eps) {
        return [
          IterationData(0, {'Error': 'Zero pivot encountered'})
        ];
      }

      // Swap rows if necessary
      if (pivotRow != i) {
        var temp = augmented[i];
        augmented[i] = augmented[pivotRow];
        augmented[pivotRow] = temp;
        steps.add("After Row Swap (R${i + 1} ↔ R${pivotRow + 1}):\n"
            "Augmented Matrix:\n${_formatMatrix(augmented, decimalPlaces)}");
      }

      // Normalize the pivot row (make pivot = 1)
      double pivot = augmented[i][i];
      for (int j = 0; j <= n; j++) {
        augmented[i][j] /= pivot;
      }
      steps.add("After Normalizing Row ${i + 1} (Pivot = 1):\n"
          "Augmented Matrix:\n${_formatMatrix(augmented, decimalPlaces)}");

      // Eliminate column i above and below the pivot
      for (int k = 0; k < n; k++) {
        if (k != i) {
          double factor = augmented[k][i];
          for (int j = 0; j <= n; j++) {
            augmented[k][j] -= factor * augmented[i][j];
          }
        }
      }
      steps.add("After Eliminating Column ${i + 1}:\n"
          "Augmented Matrix:\n${_formatMatrix(augmented, decimalPlaces)}");
    }

    // Extract solution vector x from the last column
    List<double> x = List.generate(n, (i) => augmented[i][n]);
    steps.add("Solution Vector x:\n${_formatVector(x, decimalPlaces)}");

    return [
      IterationData(0, {'steps': steps})
    ];
  }

  // Format iteration data for copying to clipboard
  String formatIterationDataForClipboard(
      List<IterationData> data, String method, int decimalPlaces) {
    if (data.isEmpty) return "No results available";

    // Check for error
    if (data.length == 1 && data[0].values.containsKey('Error')) {
      return "Error: ${data[0].values['Error']}";
    }

    StringBuffer result = StringBuffer();
    result.writeln("Method: $method");
    result.writeln("Date: ${DateTime.now().toString().split('.')[0]}");
    result.writeln("-" * 50);

    switch (method) {
      case 'Bisection':
      case 'False Position':
        result.writeln(
            "iter\txl\t\tf(xl)\t\txu\t\tf(xu)\t\txr\t\tf(xr)\t\tError %");
        for (var item in data) {
          result.writeln("${item.values['iteration']}\t"
              "${_round(item.values['xl'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['f(xl)'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['xu'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['f(xu)'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['xr'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['f(xr)'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['Error %'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}");
        }
        break;
      case 'Simple Fixed Point':
        result.writeln("i\tXi\t\tG(Xi)\t\tError");
        for (var item in data) {
          result.writeln("${item.values['i']}\t"
              "${_round(item.values['Xi'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['G(Xi)'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${item.values['E'] ?? '---'}");
        }
        break;
      case 'Newton-Raphson':
        result.writeln("i\tXi\t\tF(Xi)\t\tF'(Xi)\t\tError");
        if (data.isNotEmpty && data[0].values.containsKey('Derivative')) {
          result.writeln("Derivative: ${data[0].values['Derivative']}");
        }
        for (var item in data) {
          result.writeln("${item.values['i']}\t"
              "${_round(item.values['Xi'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['F(Xi)'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['F\'(Xi)'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${item.values['E'] == 0.0 ? '---' : '${_round(item.values['E'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}%'}");
        }
        break;
      case 'Secant':
        result.writeln("i\tXi\t\tF(Xi)\t\tError");
        for (var item in data) {
          result.writeln("${item.values['i']}\t"
              "${_round(item.values['Xi'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${_round(item.values['F(Xi)'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}\t"
              "${item.values['E'] == 0.0 ? '---' : '${_round(item.values['E'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}%'}");
        }
        break;
      case 'Gauss Elimination':
      case 'Gauss Elimination With P.P':
      case 'LU Decomposition':
      case 'LU Decomposition With P.P':
      case "Cramer's Rule":
      case 'Gauss Jordan Elimination':
      case 'Gauss Jordan Elimination With P.P':
        // For matrix methods, just include the steps
        if (data[0].values.containsKey('steps')) {
          List<String> steps = data[0].values['steps'];
          for (int i = 0; i < steps.length; i++) {
            result.writeln("Step ${i + 1}:");
            result.writeln(steps[i]);
            result.writeln("-" * 50);
          }
        }
        break;
      default:
        result.writeln("No formatted output available for this method");
    }

    // Look for the final root value in the last iteration
    if (method == 'Bisection' || method == 'False Position') {
      var lastItem = data.last.values;
      if (lastItem.containsKey('xr')) {
        result.writeln(
            "\nFinal Root: ${_round(lastItem['xr'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}");
      }
    } else if (method == 'Newton-Raphson' ||
        method == 'Simple Fixed Point' ||
        method == 'Secant') {
      var lastItem = data.last.values;
      if (lastItem.containsKey('Xi')) {
        result.writeln(
            "\nFinal Root: ${_round(lastItem['Xi'] ?? 0, decimalPlaces).toStringAsFixed(decimalPlaces)}");
      }
    }

    return result.toString();
  }
}
