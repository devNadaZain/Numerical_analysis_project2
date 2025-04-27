from flask import Flask, request, jsonify
from sympy import Symbol, sympify, diff, sqrt, Abs
import math

app = Flask(__name__)

def numerical_derivative(g, x_val, h=1e-4):
    """Compute the numerical derivative of g at x_val."""
    try:
        x = Symbol('x')
        g_plus = g.subs(x, x_val + h)
        g_minus = g.subs(x, x_val - h)
        derivative = (g_plus - g_minus) / (2 * h)
        return float(derivative)
    except Exception as e:
        raise ValueError(f"Failed to compute numerical derivative: {str(e)}")

def simple_fixed_point_method(f_equation, initial_guess, max_iterations, tolerance, decimal_places):
    try:
        print(f"Processing equation: {f_equation}")
        x = Symbol('x')
        # Parse the equation f(x)
        f = sympify(f_equation, evaluate=False)
        print(f"Parsed equation: {f}")
        
        # List to store iteration data
        iterations = []
        current_x = float(initial_guess)
        error = 100.0

        # Derive g(x) candidates
        g_candidates = []

        # Method 1: g(x) = f(x) + x
        g1 = f + x
        g_candidates.append({
            'g': g1,
            'method': 'Simple addition: g(x) = f(x) + x'
        })

        # Method 2: Isolate linear term
        try:
            # Expand f(x) to separate terms
            f_expanded = f.expand()
            print(f"Expanded equation: {f_expanded}")
            # Collect coefficients
            coeff_x = f_expanded.coeff(x, 1)
            other_terms = f_expanded - coeff_x * x
            if coeff_x != 0:
                g_linear = -other_terms / coeff_x
                g_candidates.append({
                    'g': g_linear,
                    'method': f'Isolating linear term: x = -({other_terms})/{coeff_x}'
                })
            else:
                print("No linear term to isolate (coeff_x = 0)")
        except Exception as e:
            print(f"Failed to derive g(x) via linear term: {e}")

        # Method 3: Isolate quadratic term
        try:
            coeff_x2 = f_expanded.coeff(x**2)
            linear_and_const = f_expanded - coeff_x2 * x**2
            if coeff_x2 != 0:
                # Positive root: x^2 = (linear + constant) / (-coeff_x2)
                if coeff_x2 < 0:
                    g_quad_pos = sqrt(linear_and_const / (-coeff_x2))
                    g_quad_neg = -sqrt(linear_and_const / (-coeff_x2))
                else:
                    g_quad_pos = sqrt(-linear_and_const / coeff_x2)
                    g_quad_neg = -sqrt(-linear_and_const / coeff_x2)
                g_candidates.append({
                    'g': g_quad_pos,
                    'method': f'Isolating quadratic term (positive root): x = sqrt({linear_and_const}/{-coeff_x2})'
                })
                g_candidates.append({
                    'g': g_quad_neg,
                    'method': f'Isolating quadratic term (negative root): x = -sqrt({linear_and_const}/{-coeff_x2})'
                })
            else:
                print("No quadratic term to isolate (coeff_x2 = 0)")
        except Exception as e:
            print(f"Failed to derive g(x) via quadratic term: {e}")

        # Check convergence for each candidate
        selected_g = None
        selected_method = ''
        for candidate in g_candidates:
            g = candidate['g']
            try:
                g_prime = numerical_derivative(g, initial_guess)
                g_prime_abs = float(Abs(g_prime))
                candidate['g_prime_value'] = g_prime_abs
                candidate['converges'] = g_prime_abs < 1
                print(f"Candidate g(x): {g}, Method: {candidate['method']}, |g'(x0)|: {g_prime_abs}, Converges: {candidate['converges']}")
                if candidate['converges'] and selected_g is None:
                    selected_g = g
                    selected_method = candidate['method']
            except Exception as e:
                print(f"Error checking convergence for g(x)={g}: {e}")

        if selected_g is None:
            return [{
                'i': 0,
                'Error': f'No converging g(x) found at initial guess x={initial_guess}',
                'Candidates': '; '.join([f"{c['method']}: g(x)={c['g']}, |g'(x0)|={c.get('g_prime_value', 'N/A')}" for c in g_candidates])
            }]

        print(f"Selected g(x): {selected_g} ({selected_method})")

        # Test initial evaluation
        try:
            test_value = float(selected_g.subs(x, initial_guess))
            if not math.isfinite(test_value):
                return [{
                    'i': 0,
                    'Error': 'Initial evaluation of g(x) resulted in non-finite value'
                }]
            print(f"Initial evaluation of g(x) at x={initial_guess}: {test_value}")
        except Exception as e:
            return [{
                'i': 0,
                'Error': f'Initial evaluation of g(x) failed: {str(e)}'
            }]

        # Fixed-point iteration
        divergence_threshold = 1e15
        for i in range(max_iterations):
            try:
                next_x = float(selected_g.subs(x, current_x))
                if not math.isfinite(next_x):
                    iterations.append({
                        'i': i,
                        'Error': f'Non-finite value encountered: {next_x}'
                    })
                    break
                print(f"Iteration {i}: currentX={current_x}, nextX={next_x}")
            except Exception as e:
                iterations.append({
                    'i': i,
                    'Error': f'Evaluation error: {str(e)}'
                })
                break

            # Compute relative error
            if i > 0:
                abs_diff = abs(next_x - current_x)
                if abs(next_x) > 1e-15:
                    error = (abs_diff / abs(next_x)) * 100.0
                else:
                    error = 0.0 if abs_diff < 1e-15 else float('inf')
            print(f"Error: {error}%")

            iterations.append({
                'i': i,
                'Xi': round(current_x, decimal_places),
                'G(Xi)': round(next_x, decimal_places),
                'E': '---' if i == 0 else f"{round(error, decimal_places)}%"
            })

            # Check for convergence
            if i > 0 and error < tolerance:
                iterations.append({
                    'i': i + 1,
                    'Result': f'Converged: Error ({round(error, decimal_places)}%) <= {tolerance}%',
                    'Root': round(next_x, decimal_places)
                })
                break

            # Check for divergence
            if abs(next_x) > divergence_threshold:
                iterations.append({
                    'i': i + 1,
                    'Error': f'Method is diverging (value {next_x:.2e} at iteration {i})'
                })
                break

            current_x = next_x

        if len(iterations) >= max_iterations:
            iterations.append({
                'i': len(iterations),
                'Result': f'Stopped: Reached maximum iterations ({max_iterations}). Last estimate: {round(current_x, decimal_places)}',
                'Root': round(current_x, decimal_places)
            })

        return iterations

    except Exception as e:
        return [{
            'i': 0,
            'Error': f'Calculation error: {str(e)}'
        }]

@app.route('/fixed_point', methods=['POST'])
def fixed_point():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400

        f_equation = data.get('fEquation')
        if not f_equation:
            return jsonify({'error': 'Equation (fEquation) is required'}), 400

        initial_guess = float(data.get('initialGuess'))
        max_iterations = int(data.get('maxIterations'))
        tolerance = float(data.get('tolerance'))  # Tolerance is in percentage (e.g., 0.2 means 0.2%)
        decimal_places = int(data.get('decimalPlaces'))

        print(f"Received: fEquation={f_equation}, initialGuess={initial_guess}, maxIterations={max_iterations}, tolerance={tolerance}%, decimalPlaces={decimal_places}")

        result = simple_fixed_point_method(f_equation, initial_guess, max_iterations, tolerance, decimal_places)
        return jsonify({'iterations': result})

    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)