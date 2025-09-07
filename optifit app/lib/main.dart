import 'package:OptiFit/screens/schedule_screen.dart';
import 'package:OptiFit/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/theme.dart';
import 'screens/home_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'package:timezone/data/latest_all.dart' as tz;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Initialize notification service
  try {
    await NotificationService().initialize();
    print('✅ Notification service initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize notification service: $e');
  }
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'OptiFit',
      theme: AppTheme.lightTheme,
      home: const MainScaffold(),
      debugShowCheckedModeBanner: false,
      routes: {
        //'/': (context) => const MainScaffold(),
        ScheduleScreen.routeName: (context) => ScheduleScreen(notificationData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?),
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic>? notificationData;
  const MainScaffold({super.key, this.initialIndex = 0, this.notificationData});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _selectedIndex;
  final List<Widget?> _screens = List<Widget?>.filled(5, null);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens[_selectedIndex] = _buildScreen(_selectedIndex);
  }

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return WorkoutsScreen(onGoHome: () => _changeTab(0));
      case 2:
        return const AIChatScreen();
      case 3:
        return const ProgressScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the selected screen if not already built
    if (_screens[_selectedIndex] == null) {
      _screens[_selectedIndex] = _buildScreen(_selectedIndex);
    }
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          _screens.length,
          (i) => _screens[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _changeTab,
      ),
    );
  }
}
