import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:OptiFit/screens/schedule_screen.dart';
import 'package:OptiFit/services/notification_service.dart';
import 'theme/theme.dart';
import 'screens/home_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/custom_bottom_nav_bar.dart';

// The navigatorKey remains global
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // This must be called before any async work in main
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// MyApp is now a StatelessWidget that uses FutureBuilder for initialization
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This function performs all async startup tasks and returns the payload if found
  Future<Map<String, dynamic>?> _initializeApp() async {
    // 1. Initialize services
    tz.initializeTimeZones();
    await NotificationService().initialize();
    await dotenv.load(fileName: ".env");

    // 2. Check for notification launch details
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final notificationLaunchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    final payloadString = notificationLaunchDetails?.notificationResponse?.payload;

    if (payloadString != null) {
      return jsonDecode(payloadString);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'OptiFit',
      theme: AppTheme.lightTheme,
      home: FutureBuilder<Map<String, dynamic>?>(
        future: _initializeApp(),
        builder: (context, snapshot) {
          // While the future is resolving, show a blank container.
          // This avoids adding a "splash screen" but prevents UI freezes.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: SizedBox.shrink());
          }

          // If there was an error, you could show an error screen
          if (snapshot.hasError) {
            return const Scaffold(body: Center(child: Text("Error initializing app")));
          }

          // Once initialization is complete, decide the home screen
          final payloadData = snapshot.data;
          if (payloadData != null) {
            // If opened from a notification, the first screen is ScheduleScreen
            return ScheduleScreen(notificationData: payloadData);
          } else {
            // Otherwise, the first screen is the normal MainScaffold
            return const MainScaffold();
          }
        },
      ),
      routes: {
        ScheduleScreen.routeName: (context) {
          final notificationData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ScheduleScreen(notificationData: notificationData);
        },
      },
    );
  }
}


// MainScaffold is simplified, as it no longer handles startup logic
class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _selectedIndex;
  final List<Widget?> _screens = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens[_selectedIndex] = _buildScreen(_selectedIndex);

    // This handler is now ONLY for notifications tapped while the app is already running
    NotificationHandler.onPayload = (data) {
      print('DEBUG: Handling onPayload notification while app is running: $data');
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed(
          ScheduleScreen.routeName,
          arguments: data,
        );
      }
    };
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