import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'home_screen.dart';

class LinearAlgebraScreen extends StatelessWidget {
  const LinearAlgebraScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Linear Equation Solvers',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
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
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'Select a method:',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.purple[800],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildMethodCard(
                    context,
                    title: 'Gauss Elimination',
                    description:
                        'Solves linear systems by row operations to form an upper triangular matrix, then back-substitution.',
                    icon: Icons.format_align_left,
                    color: Colors.purple,
                    onTap: () =>
                        _navigateToMethod(context, 'Gauss Elimination'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'Gauss Elimination With P.P',
                    description:
                        'Solves linear equations by reducing the augmented matrix to upper triangular form and then using back substitution.',
                    icon: Icons.format_align_left,
                    color: Colors.teal,
                    onTap: () => _navigateToMethod(
                        context, 'Gauss Elimination With P.P'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'LU Decomposition',
                    description:
                        'Decomposes coefficient matrix into lower and upper triangular matrices for efficient solving of multiple systems.',
                    icon: Icons.view_agenda,
                    color: Colors.deepPurple,
                    onTap: () => _navigateToMethod(context, 'LU Decomposition'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'LU Decomposition With P.P',
                    description:
                        'Decomposes matrix into 𝐿, 𝑈, and P for stable, efficient linear system solving.',
                    icon: Icons.view_agenda,
                    color: const Color.fromARGB(255, 123, 118, 135),
                    onTap: () =>
                        _navigateToMethod(context, 'LU Decomposition With P.P'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'Cramer\'s Rule',
                    description:
                        'Uses determinants to find the solution to a system of linear equations.',
                    icon: Icons.calculate,
                    color: Colors.blueGrey, // Fixed nullable color
                    onTap: () => _navigateToMethod(context, 'Cramer\'s Rule'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'Gauss Jordan Elimination',
                    description:
                        'Uses diagonal pivots to solve the matrix directly. Simple but unstable if pivots are small.',
                    icon: Icons.grid_view_sharp,
                    color: Colors.orange,
                    onTap: () =>
                        _navigateToMethod(context, 'Gauss Jordan Elimination'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'Gauss Jordan Elimination With P.P',
                    description:
                        'Uses partial pivoting to enhance numerical stability in Gauss-Jordan elimination.',
                    icon: Icons.grid_view_sharp,
                    color: Colors.red,
                    onTap: () => _navigateToMethod(
                        context, 'Gauss Jordan Elimination With P.P'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? Colors.grey[800]! : Colors.white,
                isDark ? Colors.grey[900]! : Colors.grey[50]!,
              ],
              stops: [0.0, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? color.withOpacity(0.2)
                        : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 36,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: color,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToMethod(BuildContext context, String method) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreen(initialMethod: method),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
      ),
    );
  }
}
