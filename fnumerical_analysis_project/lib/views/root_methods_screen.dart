import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'home_screen.dart';

class RootMethodsScreen extends StatelessWidget {
  const RootMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Root Finding Methods',
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
                  color: isDark ? Colors.white : Colors.indigo[800],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildMethodCard(
                    context,
                    title: 'Bisection Method',
                    description:
                        'Finds a root by repeatedly bisecting an interval and selecting the subinterval where the function changes sign.',
                    icon: Icons.call_split,
                    color: Colors.indigo,
                    onTap: () => _navigateToMethod(context, 'Bisection'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'False Position Method',
                    description:
                        'Uses linear interpolation between function values to find better approximations to roots.',
                    icon: Icons.line_axis,
                    color: Colors.blue,
                    onTap: () => _navigateToMethod(context, 'False Position'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'Simple Fixed Point Method',
                    description:
                        'Finds a fixed point of a function through iteration, using x = g(x) form.',
                    icon: Icons.repeat,
                    color: Colors.teal,
                    onTap: () =>
                        _navigateToMethod(context, 'Simple Fixed Point'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'Newton-Raphson Method',
                    description:
                        'Uses derivatives to find successively better approximations to the roots.',
                    icon: Icons.show_chart,
                    color: Colors.green,
                    onTap: () => _navigateToMethod(context, 'Newton-Raphson'),
                  ),
                  _buildMethodCard(
                    context,
                    title: 'Secant Method',
                    description:
                        'Approximates the derivative using secant lines through two points to find roots.',
                    icon: Icons.timeline,
                    color: Colors.amber, // Fixed nullable color
                    onTap: () => _navigateToMethod(context, 'Secant'),
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
