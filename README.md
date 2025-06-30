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
```

### 🔧 Set Up Flutter Frontend

```bash
cd fnumerical_analysis_project
flutter pub get
flutter run
```

---

## 🎯 Generate App Icons

Ensure `assets/icon.png` is in place, then run:

```bash
flutter pub run flutter_launcher_icons
```

---

## 🔙 Set Up Flask Backend

```bash
cd fnumerical_analysis_project/lib/server
python -m venv venv
```
## On Windows:
```bash
venv\Scripts\activate
```
## On macOS/Linux:
```bash
source venv/bin/activate

pip install -r requirements.txt
python app.py
```

---

## 🌐 Configure API Endpoint

Update the following file:

```
lib/controllers/root_controller.dart
```

Replace the base URL with your backend URL:

```dart
final String baseUrl = 'http://192.168.1.10:5000';
```

---

## 📦 Dependencies

### Flutter (`pubspec.yaml`)

```yaml
google_fonts: ^6.1.0
math_expressions: ^2.6.0
flutter_math_fork: ^0.7.2
fl_chart: ^0.65.0
provider: ^6.1.1
shared_preferences: ^2.2.2
animations: ^2.0.8
http: ^1.2.2
```

### Python (`requirements.txt` in `fnumerical_analysis_project/lib/server/`)

```txt
flask==2.0.1
sympy==1.10.1
numpy==1.22.4
```

---

## 🚀 Usage

### 1. Launch the App
```bash
flutter run
```

### 2. Select a Category  
Choose **Root Finding Methods** or **Linear Algebraic Equations**.

### 3. Pick a Method  
Select from methods like **Bisection** or **Gauss Elimination**.

### 4. Enter Parameters  
- **Root-finding**:  
  Input equation (e.g., `x^3 - 0.165*x^2 + 0.0003993`), bounds, and tolerance.  
- **Linear systems**:  
  Input matrix coefficients and size.

### 5. Solve & Explore  
Click **"Find Root"** or **"Solve Matrix"** to view results, steps, and plots.  
Check the **History** screen to review or rerun calculations.

---

## 📂 Project Structure

```text
root-finder/
├── fnumerical_analysis_project/
│   ├── lib/
│   │   ├── controllers/
│   │   │   ├── numerical_method.dart         # Defines IterationData for method results
│   │   │   ├── root_controller.dart          # Core logic for numerical computations
│   │   ├── views/
│   │   │   ├── method_category_screen.dart   # Entry screen for category selection
│   │   │   ├── root_methods_screen.dart      # Lists root-finding methods with descriptions
│   │   │   ├── linear_algebra_screen.dart    # Lists linear algebra methods with descriptions
│   │   │   ├── home_screen.dart              # Main UI for inputs and results
│   │   │   ├── function_plot.dart            # Visualizes equations with fl_chart
│   │   │   ├── history_screen.dart           # Manages calculation history
│   │   ├── server/
│   │   │   ├── app.py                        # Flask backend for Simple Fixed Point
│   ├── assets/
│   │   ├── icon.png                          # App icon for flutter_launcher_icons
│   ├── pubspec.yaml                          # Flutter dependencies and config
│   ├── requirements.txt                      # Python backend dependencies
├── screenshots/                              # Screenshots for documentation
├── README.md                                 # Project documentation
├── LICENSE                                   # MIT License file
```

---

## 🧮 Methods Implementation

### Root-Finding Methods

Solve `f(x) = 0` with the following techniques:

| Method           | Description                             | Convergence Order     |
|------------------|-----------------------------------------|------------------------|
| **Bisection**     | Halves intervals based on sign changes  | Linear (1.0)           |
| **False Position**| Interpolates via secant lines           | Linear (faster)        |
| **Fixed Point**   | Iterates `x = g(x)` for convergence     | Linear or higher       |
| **Newton-Raphson**| Uses derivatives for rapid convergence  | Quadratic (2.0)        |
| **Secant**        | Uses two points to approximate derivative| Superlinear (~1.62)    |

### Linear System Solvers

Solve `Ax = b` with:

- **Direct Methods**: Provide exact solutions within floating-point limits.
- **Pivoting Options**: Improve numerical stability in Gauss and LU methods.
- **Step-by-Step Visualization**: Track every matrix transformation.

---

## 📸 Screenshots

```markdown
![Alt Text](screenshots/your-image.png)
```

---

## 💡 Technical Highlights

- **Frontend**:
  - Built with Flutter
  - Uses `google_fonts`, `flutter_math_fork`, `provider`, `animations`
- **Plotting**: `function_plot.dart` uses `fl_chart` to visualize functions and roots
- **History**: Stored using `shared_preferences` in `history_screen.dart`
- **Backend**: `app.py` handles Simple Fixed Point iteration via Flask and SymPy

### ✅ Challenges Resolved
- Fixed `math_expressions` & `petitparser` conflicts
- Solved Flask 400 errors by validating `fEquation` formats
- Optimized plotting for non-finite values
- Resolved matrix input UI issues on small screens

---

## 🤝 Contributing

Feel free to fork the repo, create a new branch, and submit a **pull request**.  
Together we can make numerical analysis more accessible! 🌍

---

## 📜 License

This project is licensed under the **MIT License**.  
See the [LICENSE](LICENSE) file for full details.

---

## 🙌 Acknowledgments

- Developed by **Nada Zain💙**
- Built with **Flutter**, **Flask**, `fl_chart`, `sympy`, and `numpy`
- Inspired by real-world **numerical analysis** challenges in education
