import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DoctorWorkloadApp());
}

// ============================================
// COLOR PALETTE
// ============================================
class AppColors {
  static const primary = Color(0xFFFC8019);
  static const secondary = Color(0xFF282C3F);
  static const background = Color(0xFFF5F5F5);
  static const white = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF282C3F);
  static const textSecondary = Color(0xFF7E808C);
  static const success = Color(0xFF60B246);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFE23744);
  static const critical = Color(0xFFD32F2F);
  static const high = Color(0xFFFF6B6B);
  static const medium = Color(0xFFFFB74D);
  static const low = Color(0xFF81C784);
}

class DoctorWorkloadApp extends StatelessWidget {
  const DoctorWorkloadApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mediflow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================
// API SERVICE - UPDATED WITH PROPER ERROR HANDLING
// ============================================
class ApiService {
  // CHANGE THIS TO YOUR COMPUTER'S IP ADDRESS
  // Find it using: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String baseUrl = 'http://192.168.1.36:5000'; // <-- CHANGE THIS!

  static Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}'
        };
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Request timeout. Check your connection.'};
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}'
        };
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Request timeout. Check your connection.'};
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> put(
      String endpoint,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}'
        };
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Request timeout. Check your connection.'};
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
    }
  }
}

// ============================================
// SPLASH SCREEN
// ============================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.medical_services,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mediflow',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// LOGIN SCREEN
// ============================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'dr_smith');
  final _passwordController = TextEditingController(text: 'password');
  bool _isLoading = false;

  void _login() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter your ID');
      return;
    }

    setState(() => _isLoading = true);

    // Test connection
    final health = await ApiService.get('/api/health');

    setState(() => _isLoading = false);

    if (health['status'] == 'healthy') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            doctorId: _emailController.text,
          ),
        ),
      );
    } else {
      _showError('Cannot connect to server. Check IP address in code.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Doctor ID',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// DASHBOARD SCREEN
// ============================================
class DashboardScreen extends StatefulWidget {
  final String doctorId;

  const DashboardScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    setState(() => _isLoadingStats = true);
    final response = await ApiService.get('/api/stats');
    setState(() {
      if (response['success'] == true) {
        _stats = response['stats'];
      }
      _isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        doctorId: widget.doctorId,
        stats: _stats,
        isLoading: _isLoadingStats,
        onRefresh: _loadStats,
      ),
      const PatientQueueScreen(),
      TasksScreen(doctorId: widget.doctorId),
      ProfileScreen(doctorId: widget.doctorId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workload Optimizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: AppColors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Queue'),
            BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ============================================
// HOME SCREEN
// ============================================
class HomeScreen extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final VoidCallback onRefresh;

  const HomeScreen({
    Key? key,
    required this.doctorId,
    this.stats,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Dr. $doctorId',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Here\'s your workload overview',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _StatCard(
                    title: 'Queue',
                    value: '${stats?['patients_in_queue'] ?? 0}',
                    icon: Icons.people,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    title: 'Critical',
                    value: '${stats?['critical_patients'] ?? 0}',
                    icon: Icons.warning,
                    color: AppColors.critical,
                  ),
                  _StatCard(
                    title: 'Total Patients',
                    value: '${stats?['total_patients_today'] ?? 0}',
                    icon: Icons.medical_services,
                    color: AppColors.success,
                  ),
                  _StatCard(
                    title: 'Handovers',
                    value: '${stats?['handovers_generated'] ?? 0}',
                    icon: Icons.swap_horiz,
                    color: AppColors.secondary,
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'AI Triage',
              subtitle: 'Analyze patient symptoms',
              icon: Icons.analytics,
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TriageScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'Shift Handover',
              subtitle: 'Generate handover report',
              icon: Icons.sync_alt,
              color: AppColors.success,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ShiftHandoverScreen(doctorId: doctorId),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'Burnout Analysis',
              subtitle: 'Check your wellness',
              icon: Icons.favorite,
              color: AppColors.error,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BurnoutAnalysisScreen(doctorId: doctorId),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'Voice Documentation',
              subtitle: 'Record patient notes',
              icon: Icons.mic,
              color: AppColors.secondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VoiceDocScreen()),

              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'AI Assistant',
              subtitle: 'Ask about patients & records',
              icon: Icons.chat_bubble_outline,
              color: Color(0xFF9C27B0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "Hello! I'm your AI medical assistant. I can help you with:\n\n"
            "• Patient information and records\n"
            "• Queue status and priorities\n"
            "• Medical documentation\n"
            "• Triage assessments\n\n"
            "Ask me anything about your patients!",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _loadSuggestions() async {
    final response = await ApiService.get('/api/chatbot/suggestions');
    if (response['success'] == true) {
      setState(() {
        _suggestions = List<String>.from(response['suggestions'] ?? []);
      });
    }
  }

  void _sendMessage([String? predefinedMessage]) async {
    final message = predefinedMessage ?? _messageController.text.trim();

    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Send to API
    final response = await ApiService.post('/api/chatbot', {
      'query': message,
    });

    setState(() {
      _isLoading = false;
      if (response['success'] == true) {
        _messages.add(ChatMessage(
          text: response['response'] ?? 'No response',
          isUser: false,
          timestamp: DateTime.now(),
          contextUsed: response['context_used'],
        ));
      } else {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error: ${response['error']}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Text('AI Medical Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggestions chips (show when no messages except welcome)
          if (_messages.length <= 1 && _suggestions.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(
                        _suggestions[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _sendMessage(_suggestions[index]),
                      backgroundColor: AppColors.background,
                    ),
                  );
                },
              ),
            ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[600]!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about patients...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.white),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ============================================
// CHAT MESSAGE MODEL
// ============================================
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final int? contextUsed;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.contextUsed,
    this.isError = false,
  });
}

// ============================================
// CHAT BUBBLE WIDGET
// ============================================
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: message.isError
                    ? AppColors.error.withOpacity(0.1)
                    : const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                message.isError ? Icons.error_outline : Icons.smart_toy,
                color: message.isError
                    ? AppColors.error
                    : const Color(0xFF9C27B0),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF9C27B0)
                        : message.isError
                        ? AppColors.error.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? AppColors.white
                              : message.isError
                              ? AppColors.error
                              : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (message.contextUsed != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📚 ${message.contextUsed} sources used',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ============================================
// STAT CARD WIDGET
// ============================================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// ACTION CARD WIDGET
// ============================================
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PATIENT QUEUE SCREEN - FIXED
// ============================================
class PatientQueueScreen extends StatefulWidget {
  const PatientQueueScreen({Key? key}) : super(key: key);

  @override
  State<PatientQueueScreen> createState() => _PatientQueueScreenState();
}

class _PatientQueueScreenState extends State<PatientQueueScreen> {
  List<dynamic> _queue = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  void _loadQueue() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.get('/api/patient-queue');

    setState(() {
      _isLoading = false;
      if (response['success'] == true) {
        _queue = response['queue'] ?? [];
      } else {
        _error = response['error'] ?? 'Failed to load queue';
      }
    });
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.critical;
      case 'HIGH':
        return AppColors.high;
      case 'MEDIUM':
        return AppColors.medium;
      case 'LOW':
        return AppColors.low;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQueue,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No patients in queue',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadQueue,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadQueue(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _queue.length,
        itemBuilder: (context, index) {
          final patient = _queue[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getPriorityColor(patient['priority'])
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(patient['priority']),
                    ),
                  ),
                ),
              ),
              title: Text(
                patient['patient_name'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    patient['symptoms'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(patient['priority']),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          patient['priority'] ?? '',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Age: ${patient['age']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(patient['patient_name'] ?? 'Patient Details'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Age: ${patient['age']}'),
                          const SizedBox(height: 8),
                          Text('Symptoms: ${patient['symptoms']}'),
                          const SizedBox(height: 8),
                          Text('Priority: ${patient['priority']}'),
                          const SizedBox(height: 8),
                          Text('Status: ${patient['status']}'),
                          if (patient['triage_assessment'] != null) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Assessment:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(patient['triage_assessment']),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// TRIAGE SCREEN - FIXED
// ============================================
class TriageScreen extends StatefulWidget {
  const TriageScreen({Key? key}) : super(key: key);

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final _nameController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  void _submitTriage() async {
    if (_nameController.text.isEmpty) {
      _showError('Please enter patient name');
      return;
    }
    if (_symptomsController.text.isEmpty) {
      _showError('Please enter symptoms');
      return;
    }
    if (_ageController.text.isEmpty) {
      _showError('Please enter age');
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.post('/api/triage', {
      'patient_name': _nameController.text,
      'symptoms': _symptomsController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'vital_signs': {},
    });

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✓ Triage Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Priority: ${response['patient']['priority']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Queue Position: ${response['queue_position']}'),
              const SizedBox(height: 8),
              Text('Total in Queue: ${response['total_in_queue']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showError(response['error'] ?? 'Failed to submit triage');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Triage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Patient Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _symptomsController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Symptoms',
                hintText: 'Describe symptoms in detail...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTriage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : const Text(
                  'Submit Triage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// SHIFT HANDOVER SCREEN - FIXED
// ============================================
class ShiftHandoverScreen extends StatefulWidget {
  final String doctorId;

  const ShiftHandoverScreen({Key? key, required this.doctorId})
      : super(key: key);

  @override
  State<ShiftHandoverScreen> createState() => _ShiftHandoverScreenState();
}

class _ShiftHandoverScreenState extends State<ShiftHandoverScreen> {
  bool _isLoading = false;
  String? _handoverReport;
  Map<String, dynamic>? _handoverData;

  void _generateHandover() async {
    setState(() => _isLoading = true);

    final response = await ApiService.post('/api/shift-handover', {
      'doctor_id': widget.doctorId,
      'shift_end_time': DateTime.now().toIso8601String(),
    });

    setState(() {
      _isLoading = false;
      if (response['success'] == true) {
        _handoverData = response['handover'];
        _handoverReport = response['handover']?['report'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to generate handover'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shift Handover')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Cards
            if (_handoverData != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_handoverData!['active_patients_count'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text('Active Patients'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.critical.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_handoverData!['critical_count'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.critical,
                            ),
                          ),
                          const Text('Critical'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateHandover,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : const Text(
                  'Generate Handover Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_handoverReport != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.description, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Handover Report',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          _handoverReport!,
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// BURNOUT ANALYSIS SCREEN - FIXED
// ============================================
class BurnoutAnalysisScreen extends StatefulWidget {
  final String doctorId;

  const BurnoutAnalysisScreen({Key? key, required this.doctorId})
      : super(key: key);

  @override
  State<BurnoutAnalysisScreen> createState() => _BurnoutAnalysisScreenState();
}

class _BurnoutAnalysisScreenState extends State<BurnoutAnalysisScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    _analyzeRisk();
  }

  void _analyzeRisk() async {
    setState(() => _isLoading = true);

    final response = await ApiService.post('/api/burnout-analysis', {
      'doctor_id': widget.doctorId,
    });

    setState(() {
      _isLoading = false;
      if (response['success'] == true) {
        _analysis = response['burnout_analysis'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to analyze burnout'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  Color _getRiskColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.critical;
      case 'HIGH':
        return AppColors.high;
      case 'MODERATE':
        return AppColors.medium;
      case 'LOW':
        return AppColors.low;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_analysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Burnout Analysis')),
        body: const Center(child: Text('No data available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Burnout Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getRiskColor(_analysis?['burnout_risk_level']),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: AppColors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _analysis?['burnout_risk_level'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const Text(
                    'Risk Level',
                    style: TextStyle(fontSize: 16, color: AppColors.white),
                  ),
                  if (_analysis?['risk_score'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Score: ${_analysis!['risk_score']}/100',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MetricRow(
                    label: 'Hours Worked',
                    value: '${_analysis?['metrics']?['hours_worked'] ?? 0}',
                  ),
                  const Divider(),
                  _MetricRow(
                    label: 'Patients Seen',
                    value: '${_analysis?['metrics']?['patients_seen'] ?? 0}',
                  ),
                  const Divider(),
                  _MetricRow(
                    label: 'Stress Level',
                    value: '${_analysis?['metrics']?['stress_level'] ?? 0}/10',
                  ),
                  const Divider(),
                  _MetricRow(
                    label: 'Hours Since Break',
                    value:
                    '${_analysis?['metrics']?['hours_since_break'] ?? 0}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _analysis?['analysis'] ?? 'No analysis available',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// VOICE DOCUMENTATION SCREEN - FIXED
// ============================================
class VoiceDocScreen extends StatefulWidget {
  const VoiceDocScreen({Key? key}) : super(key: key);

  @override
  State<VoiceDocScreen> createState() => _VoiceDocScreenState();
}

class _VoiceDocScreenState extends State<VoiceDocScreen> {
  final _transcriptController = TextEditingController();
  final _patientIdController = TextEditingController();
  bool _isLoading = false;
  String? _documentation;

  void _generateDoc() async {
    if (_patientIdController.text.isEmpty) {
      _showError('Please enter patient ID');
      return;
    }
    if (_transcriptController.text.isEmpty) {
      _showError('Please enter notes');
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.post('/api/voice-to-doc', {
      'doctor_id': 'current_doctor',
      'patient_id': _patientIdController.text,
      'voice_transcript': _transcriptController.text,
    });

    setState(() {
      _isLoading = false;
      if (response['success'] == true) {
        _documentation =
        response['documentation']?['structured_documentation'];
      } else {
        _showError(response['error'] ?? 'Failed to generate documentation');
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Documentation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _patientIdController,
              decoration: InputDecoration(
                labelText: 'Patient ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _transcriptController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Voice Transcript / Notes',
                hintText:
                'Enter or paste your clinical notes here...\n\nExample: Patient complains of chest pain for 2 hours, BP 140/90, prescribed aspirin...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateDoc,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : const Text(
                  'Generate Documentation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_documentation != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description, color: AppColors.secondary),
                        SizedBox(width: 8),
                        Text(
                          'Generated Documentation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _documentation!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TASKS SCREEN - IMPROVED
// ============================================
class TasksScreen extends StatefulWidget {
  final String doctorId;

  const TasksScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Review lab results',
      'description': 'Patient #123 - Blood work',
      'completed': false
    },
    {
      'title': 'Follow-up call',
      'description': 'Patient #456 - Post-op check',
      'completed': false
    },
    {
      'title': 'Update medical records',
      'description': 'Complete documentation for 3 patients',
      'completed': true
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tasks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tasks assigned',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                task['title'] ?? '',
                style: TextStyle(
                  decoration: task['completed']
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(task['description'] ?? ''),
              trailing: Checkbox(
                value: task['completed'] ?? false,
                activeColor: AppColors.success,
                onChanged: (value) {
                  setState(() {
                    _tasks[index]['completed'] = value;
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add task functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add task feature coming soon!')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}

// ============================================
// PROFILE SCREEN
// ============================================
class ProfileScreen extends StatelessWidget {
  final String doctorId;

  const ProfileScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. $doctorId',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            'General Physician',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _ProfileOption(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help coming soon!')),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About'),
                  content: const Text(
                    'Doctor Workload Optimizer v2.0\n\nAI-powered medical management system',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}