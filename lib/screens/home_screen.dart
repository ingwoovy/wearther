// home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).updateData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    String formattedLocation = weatherProvider.location
        .replaceFirst("대전광역시", "대전")
        .replaceAll("서구", "")
        .trim();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 배경 색상 설정
          Container(
            color: getBackgroundColor(),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        formattedLocation,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 날씨 아이콘
                          Text(
                            weatherProvider
                                .getWeatherIcon(weatherProvider.weatherState),
                            style: const TextStyle(
                              fontSize: 50,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 기온
                          Text(
                            "${weatherProvider.temperature}",
                            style: const TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "어제보다 ${weatherProvider.temperatureDiff}° 낮아요",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "최저: ${weatherProvider.temperatureMin}  최고: ${weatherProvider.temperatureMax} ",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // 시간별 예보 섹션
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.access_time, color: Colors.black54),
                            SizedBox(width: 8),
                            Text(
                              "시간별 예보",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          thickness: 2,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),

                        // 시간별 예보 가로 스크롤 리스트
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: weatherProvider.hourlyForecast.length,
                            itemBuilder: (context, index) {
                              final forecast =
                                  weatherProvider.hourlyForecast[index];
                              final hour =
                                  int.parse(forecast["hour"]!.substring(0, 2));

                              return Container(
                                width: 60,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${forecast["hour"]?.substring(0, 2)}시",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      forecast["icon"] ?? "",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${forecast["temperature"]}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 시간에 따른 배경 색상 결정
  Color getBackgroundColor() {
    DateTime now = DateTime.now();
    int hour = now.hour;

    if (hour >= 6 && hour < 18) {
      return const Color(0xFF87CEFA); // 낮 시간대 - 파란색 배경 (하늘색)
    } else if (hour >= 18 && hour < 20) {
      return const Color(0xFFFFA07A); // 저녁 시간대 - 주황색 배경
    } else {
      return const Color(0xFF483D8B); // 밤 시간대 - 남색 배경
    }
  }
}
