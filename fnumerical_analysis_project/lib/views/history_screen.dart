import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('calculation_history') ?? [];
      
      if (historyJson.isNotEmpty) {
        // Parse the history data
        final parsedHistory = historyJson.map((item) {
          try {
            // Convert string to map
            final rawData = item.replaceAll('{', '').replaceAll('}', '');
            final pairs = rawData.split(',');
            
            Map<String, dynamic> parsedItem = {};
            for (var pair in pairs) {
              final keyValue = pair.trim().split(':');
              if (keyValue.length == 2) {
                final key = keyValue[0].trim().replaceAll('\'', '').replaceAll('"', '');
                var value = keyValue[1].trim().replaceAll('\'', '').replaceAll('"', '');
                parsedItem[key] = value;
              }
            }
            
            return parsedItem;
          } catch (e) {
            print('Error parsing history item: $e');
            return {'method': 'Unknown', 'equation': 'Error parsing data', 'timestamp': DateTime.now().toIso8601String()};
          }
        }).toList();
        
        setState(() {
          historyItems = parsedHistory;
        });
      }
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('calculation_history');
      setState(() {
        historyItems = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('History cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error clearing history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing history'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rerunCalculation(Map<String, dynamic> historyItem) {
    final method = historyItem['method'] as String;
    final equation = historyItem['equation'] as String;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          initialMethod: method,
          initialEquation: equation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calculation History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (historyItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              tooltip: 'Clear History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear History?'),
                    content: Text('This will delete all your calculation history. This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearHistory();
                        },
                        child: Text(
                          'CLEAR',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : historyItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 72,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No calculation history yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your previous calculations will appear here',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: historyItems.length,
                  itemBuilder: (context, index) {
                    final item = historyItems[index];
                    final method = item['method'] ?? 'Unknown Method';
                    final equation = item['equation'] ?? 'Unknown Equation';
                    final timestamp = item['timestamp'] ?? DateTime.now().toIso8601String();
                    final result = item['result'] ?? 'No result';
                    
                    DateTime dateTime;
                    try {
                      dateTime = DateTime.parse(timestamp);
                    } catch (e) {
                      dateTime = DateTime.now();
                    }
                    
                    final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _rerunCalculation(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      method,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: _getColorForMethod(method, isDark),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Divider(height: 24),
                              if (_isMatrixMethod(method))
                                Text(
                                  'Matrix Operation',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else
                                Text(
                                  'Function: $equation',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.functions,
                                      size: 20,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Result: $result',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: Icon(Icons.replay),
                                  label: Text('Rerun calculation'),
                                  onPressed: () => _rerunCalculation(item),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark ? Colors.blue[300] : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  
  bool _isMatrixMethod(String method) {
    return  method.contains('Gauss') || 
            method.contains('LU Decomposition') || 
            method.contains('Cramer') || 
            method.contains('Jordan');
  }
  
  Color _getColorForMethod(String method, bool isDark) {
    if (method.contains('Bisection') || method.contains('False Position')) {
      return isDark ? Colors.orange[300]! : Colors.orange[700]!;
    } else if (method.contains('Newton') || method.contains('Secant')) {
      return isDark ? Colors.green[300]! : Colors.green[700]!;
    } else if (method.contains('Fixed Point')) {
      return isDark ? Colors.purple[300]! : Colors.purple[700]!;
    } else if (_isMatrixMethod(method)) {
      return isDark ? Colors.blue[300]! : Colors.blue[700]!;
    } else {
      return isDark ? Colors.indigo[300]! : Colors.indigo[700]!;
    }
  }
}