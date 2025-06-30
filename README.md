# Numerical Analysis App 📐

A **Flutter-based mobile app** with a **Python Flask backend**, designed to solve numerical analysis problems with ease. Featuring intuitive method navigation, function plotting, and calculation history, **Root Finder** is the ultimate tool for students and professionals diving into numerical methods. 🌟

---

## 🌟 Features

### 🧬 Root-Finding Methods
- **Bisection**: Splits intervals to pinpoint roots.
- **False Position**: Interpolates linearly for efficient root finding.
- **Simple Fixed Point**: Iterates x = g(x) to converge on solutions.
- **Newton-Raphson**: Uses derivatives for rapid convergence.
- **Secant**: Approximates derivatives with secant lines.

### 🔢 Linear System Solvers
- **Gauss Elimination**: Transforms matrices for back-substitution.
- **Gauss Elimination with Partial Pivoting**: Enhances stability with row swaps.
- **LU Decomposition**: Factorizes matrices into lower and upper forms.
- **LU Decomposition with Partial Pivoting**: Improves numerical stability.
- **Gauss-Jordan Elimination**: Reduces matrices to row-echelon form.
- **Gauss-Jordan Elimination with Partial Pivoting**: Adds pivoting for reliability.
- **Cramer’s Rule**: Solves systems using determinants.

### 📱 Modern Mobile UI
- **Categorized Navigation**: Seamlessly choose between root-finding and linear algebra methods.
- **Responsive Design**: Powered by `google_fonts`, `flutter_math_fork` for clear equation rendering.
- **Dark/Light Mode**: Toggle themes with `provider`.
- **Smooth Transitions**: Enhanced by `animations`.

### ⚙️ Advanced Capabilities
- **Function Plotting**: Visualize equations and roots with `fl_chart`.
- **Calculation History**: Save and rerun calculations using `shared_preferences`.
- **Step-by-Step Solutions**: Detailed iteration tables and matrix transformations.
- **Clipboard Export**: Copy results via `http` integration.
- **Error Handling**: Validates inputs for equations, matrices, and edge cases.
- **Custom Precision**: Adjust tolerance and decimal places.

---

## 🆕 Version History

### Version 1.1.0
- 🖼️ Added function plotting with `fl_chart` for root-finding visualization.
- 📜 Implemented calculation history with rerun functionality.
- 🧭 Introduced categorized method selection for intuitive navigation.
- 🎨 Enhanced UI with animations and theme toggling.
- 🛠️ Fixed matrix input overflow on smaller screens.
- 🔄 Optimized Flask backend for Simple Fixed Point method.

### Version 1.0.0
- 🎉 Initial release with core numerical methods.
- 📱 Flutter frontend with equation/matrix inputs.
- 🖥️ Flask backend for Simple Fixed Point calculations.
- ✅ Basic error handling and step-by-step solution display.

---

## 🛠️ Installation

### Prerequisites
- Flutter: `3.24.3` or higher  
- Dart: `2.12.0` to `<4.0.0`  
- Python: `3.8` or higher  
- pip: Python package installer  

### Setup

#### Clone the Repository
```bash
git clone https://github.com/your-username/root-finder.git
cd root-finder
