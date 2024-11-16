import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    // 초기 위치와 날씨 데이터를 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).updateData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("날씨 정보"),
        leading: IconButton(
          icon: Icon(Icons.my_location),
          onPressed: weatherProvider.updateData, // 위치 업데이트
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UI가 날씨 데이터를 표시
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/skyblue.jpg'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR')
                            .format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 20,
                          color: const Color.fromARGB(255, 24, 23, 23),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        weatherProvider
                            .getWeatherIcon(weatherProvider.weatherState),
                        style: TextStyle(fontSize: 60),
                      ),
                      SizedBox(height: 8),
                      Text(
                        weatherProvider.weatherState,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 5, 5, 5),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weatherProvider.location,
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        weatherProvider.temperature,
                        style: TextStyle(fontSize: 48, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '최저 : ${weatherProvider.temperatureMin}',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '최고 : ${weatherProvider.temperatureMax}',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '체감 온도 : ${weatherProvider.feelsLikeTemperature}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        '습도 : ${weatherProvider.humidity}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        '${weatherProvider.windDirectionText} ${weatherProvider.windSpeed}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAirQualityInfo("미세먼지", weatherProvider.fineDustLevel,
                    weatherProvider.fineDustValue),
                VerticalDivider(),
                _buildAirQualityInfo(
                    "초미세먼지",
                    weatherProvider.ultraFineDustLevel,
                    weatherProvider.ultraFineDustValue),
              ],
            ),
            Divider(),
            SizedBox(height: 10),
            Text(
              "주간 예보",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            weatherProvider.weeklyForecast.isNotEmpty
                ? Column(
                    children: weatherProvider.weeklyForecast.map((dayForecast) {
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  dayForecast["day"] ?? "정보 없음",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("오전", style: TextStyle(fontSize: 14)),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dayForecast["rainProbabilityAm"] ??
                                              "-",
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          weatherProvider.getWeatherIcon(
                                              dayForecast["weatherAm"] ?? ""),
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("오후", style: TextStyle(fontSize: 14)),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dayForecast["rainProbabilityPm"] ??
                                              "-",
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          weatherProvider.getWeatherIcon(
                                              dayForecast["weatherPm"] ?? ""),
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "${dayForecast["minTemp"] ?? "-"}",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue),
                                        ),
                                        Text(" / ",
                                            style: TextStyle(fontSize: 14)),
                                        Text(
                                          "${dayForecast["maxTemp"] ?? "-"}",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Center(child: Text("주간 예보 데이터를 불러오는 중입니다.")),
          ],
        ),
      ),
    );
  }

  Widget _buildAirQualityInfo(String title, String level, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 16)),
        Icon(Icons.circle, color: getAirQualityColor(level)),
        Text(level, style: TextStyle(fontSize: 16)),
        Text(value, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Color getAirQualityColor(String level) {
    switch (level) {
      case "좋음":
        return Colors.green;
      case "보통":
        return Colors.yellow;
      case "나쁨":
        return Colors.orange;
      case "매우나쁨":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
