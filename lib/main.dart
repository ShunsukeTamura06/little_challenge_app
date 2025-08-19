import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/history_screen.dart';
import 'screens/my_tasks_screen.dart';
import 'providers/app_state_manager.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneNew',
      theme: ThemeData(
        primaryColor: const Color(0xFF26A69A),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF26A69A),
          primary: const Color(0xFF26A69A),
          secondary: const Color(0xFFFF7043),
          background: const Color(0xFFFFFFFF),
          surface: const Color(0xFFF5F5F5),
          error: const Color(0xFFD32F2F),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.normal, color: Color(0xFF212121)),
          titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.normal, color: Color(0xFF212121)),
          bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: Color(0xFF212121)),
          bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: Color(0xFF757575)),
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    StockScreen(),
    HistoryScreen(), // Log Screen
    MyTasksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in AppStateManager
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        return Scaffold(
          body: Center(
            child: _widgetOptions.elementAt(appState.selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'ホーム',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: '探す',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                label: 'ストック',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_calendar_outlined),
                label: 'ログ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'マイタスク',
              ),
            ],
            currentIndex: appState.selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: const Color(0xFF757575), // Text (Secondary)
            onTap: (index) {
              // Use the provider to change the state
              Provider.of<AppStateManager>(context, listen: false).goToTab(index);
            },
          ),
        );
      },
    );
  }
}
