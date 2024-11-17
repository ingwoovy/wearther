import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 로케일 초기화용
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // 권한 요청용
import 'providers/weather_provider.dart'; // WeatherProvider 가져오기
import 'screens/home_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/coordination_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/alert_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null); // 한국어 로케일 초기화

  // 위치 권한 요청
  bool hasPermission = await requestLocationPermission();
  if (!hasPermission) {
    print("위치 권한이 없습니다. 앱이 올바르게 작동하지 않을 수 있습니다.");
  }

  runApp(const MyApp());
}

// 위치 권한 요청 함수
Future<bool> requestLocationPermission() async {
  var status = await Permission.location.request();
  if (status.isGranted) {
    print("위치 권한이 허용되었습니다.");
    return true;
  } else if (status.isDenied) {
    print("위치 권한이 거부되었습니다.");
    return false;
  } else if (status.isPermanentlyDenied) {
    print("위치 권한이 영구적으로 거부되었습니다. 설정으로 이동합니다.");
    await openAppSettings();
    return false;
  }
  return false;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(), // WeatherProvider 등록
        ),
      ],
      child: MaterialApp(
        title: 'Weather App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(),
      WeatherScreen(),
      CoordinationScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        leading: IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AlertScreen()),
            );
          },
        ),
        actions: _selectedIndex == 3
            ? [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny),
            label: '날씨',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom),
            label: '코디',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.lightBlueAccent,
        selectedItemColor: const Color.fromARGB(255, 29, 104, 173),
        unselectedItemColor: Colors.black54,
      ),
    );
  }
}
