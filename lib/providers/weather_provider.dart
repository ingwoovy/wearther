import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../services/coordinate_converter.dart';

class WeatherProvider extends ChangeNotifier {
  String location = "대전 복수동";
  String temperature = "-";
  String temperatureMin = "-";
  String temperatureMax = "-";
  String weatherState = "-";
  String fineDustLevel = "좋음";
  String fineDustValue = "-";
  String ultraFineDustLevel = "매우나쁨";
  String ultraFineDustValue = "-";
  String feelsLikeTemperature = "-";
  String humidity = "-";
  String windSpeed = "-";
  String windDirectionText = "";
  String temperatureDiff = "-"; // 오늘과 어제 기온 차이를 저장하는 필드 추가

  double windDirection = 0.0;
  List<Map<String, String>> hourlyForecast = [];

  String getWeatherIcon(String state) {
    if (state.contains("맑음")) {
      return "☀️"; // 낮에는 해, 저녁에는 달
    } else if (state.contains("구름") && state.contains("비")) {
      return "🌦️"; // 흐리고 비가 올 때
    } else if (state.contains("흐림")) {
      return "☁️";
    } else if (state.contains("구름많음") || state.contains("구름")) {
      return "⛅";
    } else if (state.contains("비")) {
      return "🌧️";
    } else if (state.contains("비/눈")) {
      return "🌨️";
    } else if (state.contains("눈")) {
      return "❄️";
    } else if (state.contains("빗방울")) {
      return "🌦️";
    } else if (state.contains("빗방울") && state.contains("눈날림")) {
      return "🌧️❄️";
    } else if (state.contains("눈날림")) {
      return "🌨️";
    } else {
      return "❓"; // 알 수 없는 경우
    }
  }

  final String googleMapsApiKey = "AIzaSyDVOeSQ53s1AdV-kuy3yDR9NlThxloFuEQ";
  final String weatherServiceKey =
      "EA4AAbCXXGqyAq9O%2BcZcE6%2FgZlRHARIEkTA022v2t%2B9IjX9Vj7I4Smpba8tWwMQgzPIJPlbjM9GYEMj48DLM6w%3D%3D";

  List<Map<String, String>> weeklyForecast = [];

  // 현재 위치 정보를 업데이트하는 메서드
  Future<void> updateData() async {
    await _getCurrentLocation(); // 현재 위치를 가져오는 메서드 호출
    notifyListeners(); // 데이터가 업데이트되면 변경 사항 알림
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await _getAddressFromCoordinates(position.latitude, position.longitude);
      await fetchWeatherData(position.latitude, position.longitude);
      await fetchTemperatureData(position.latitude, position.longitude);
      await fetchAirQualityData();
      await fetchWeeklyForecast(position.latitude, position.longitude);
      await fetchHourlyForecast(
          position.latitude, position.longitude); // 시간별 예보 추가
    } catch (e) {
      print("현재 위치를 가져오는 데 실패했습니다: $e");
    }
  }

  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$googleMapsApiKey&language=ko');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final addressComponents = data['results'][0]['address_components'];
        String city = '';
        String district = '';
        String neighborhood = '';

        for (var component in addressComponents) {
          final types = component['types'];
          if (types.contains('administrative_area_level_1')) {
            city = component['long_name'];
          } else if (types.contains('sublocality_level_1')) {
            district = component['long_name'];
          } else if (types.contains('political') &&
              types.contains('sublocality')) {
            neighborhood = component['long_name'];
          }
        }

        location = '$city $district $neighborhood';
        notifyListeners();
      } else {
        print("지명을 가져오지 못했습니다: ${data['status']}");
      }
    } else {
      print("Google Maps API 요청 실패: ${response.statusCode}");
    }
  }

  Future<void> fetchTemperatureComparison(
      double latitude, double longitude) async {
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(Duration(days: 1));
    String todayDate = DateFormat('yyyyMMdd').format(now);
    String yesterdayDate = DateFormat('yyyyMMdd').format(yesterday);
    String baseTime = '1100'; // 오전 11시로 설정 예시

    final coordinates = convertToGridCoordinates(latitude, longitude);
    final int nx = coordinates['nx']!;
    final int ny = coordinates['ny']!;

    String todayTemp =
        await fetchTemperatureForDate(todayDate, baseTime, nx, ny);
    String yesterdayTemp =
        await fetchTemperatureForDate(yesterdayDate, baseTime, nx, ny);

    if (todayTemp != '-' && yesterdayTemp != '-') {
      double tempDiff = double.parse(todayTemp) - double.parse(yesterdayTemp);
      temperatureDiff = '${tempDiff.toStringAsFixed(1)}°';
    } else {
      temperatureDiff = '데이터 없음';
    }
    notifyListeners();
  }

  Future<String> fetchTemperatureForDate(
      String date, String time, int nx, int ny) async {
    final response = await http.get(Uri.parse(
      'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst?serviceKey=$weatherServiceKey&numOfRows=10&pageNo=1&dataType=JSON&base_date=$date&base_time=$time&nx=$nx&ny=$ny',
    ));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['response']['body']['items']['item'];
      for (var item in items) {
        if (item['category'] == 'T1H') {
          // T1H로 수정
          return item['fcstValue'];
        }
      }
    } else {
      print("날짜 $date 의 데이터를 가져오는 데 실패했습니다: ${response.statusCode}");
    }
    return '-';
  }

  Future<void> fetchHourlyForecast(double latitude, double longitude) async {
    final String apiUrl =
        "http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst";
    final DateTime now = DateTime.now();
    DateTime baseTimeDate = now;

    // 발표 시간대 결정
    final List<int> forecastTimes = [23, 20, 17, 14, 11, 8, 5, 2];
    int hour = forecastTimes.firstWhere((t) => now.hour >= t, orElse: () => 23);
    if (now.hour < hour)
      baseTimeDate = baseTimeDate.subtract(Duration(days: 1));

    String baseDate = DateFormat('yyyyMMdd').format(baseTimeDate);
    String baseTime = '${hour.toString().padLeft(2, '0')}00';

    final coordinates = convertToGridCoordinates(latitude, longitude);
    final int nx = coordinates['nx']!;
    final int ny = coordinates['ny']!;

    final response = await http.get(Uri.parse(
      "$apiUrl?serviceKey=$weatherServiceKey&numOfRows=200&pageNo=1&dataType=JSON&base_date=$baseDate&base_time=$baseTime&nx=$nx&ny=$ny",
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['response']['body']['items']['item'];

      List<Map<String, String>> forecastList = [];
      DateTime forecastTime = now;
      Map<String, dynamic>? lastAvailableData;

      for (int i = 0; i < 24; i++) {
        String formattedHour = DateFormat('HH00').format(forecastTime);
        String displayHour = DateFormat('HH시').format(forecastTime);
        String forecastDate = DateFormat('yyyyMMdd').format(forecastTime);

        // 시간별 예보 데이터를 찾기
        var tempItem = items.firstWhere(
          (item) =>
              item['fcstDate'] == forecastDate &&
              item['fcstTime'] == formattedHour &&
              item['category'] == 'TMP',
          orElse: () => null,
        );

        var skyItem = items.firstWhere(
          (item) =>
              item['fcstDate'] == forecastDate &&
              item['fcstTime'] == formattedHour &&
              item['category'] == 'SKY',
          orElse: () => null,
        );

        var ptyItem = items.firstWhere(
          (item) =>
              item['fcstDate'] == forecastDate &&
              item['fcstTime'] == formattedHour &&
              item['category'] == 'PTY',
          orElse: () => null,
        );

        // 유효한 데이터가 있을 경우 저장
        if (tempItem != null || skyItem != null || ptyItem != null) {
          lastAvailableData = {
            "temperature": tempItem != null ? "${tempItem['fcstValue']}°" : "-",
            "skyValue": skyItem != null ? skyItem['fcstValue'] : "",
            "ptyValue": ptyItem != null ? ptyItem['fcstValue'] : ""
          };
        }

        // 누락된 데이터의 경우 마지막으로 사용 가능한 데이터로 대체
        String temperature = lastAvailableData?["temperature"] ?? "-";
        String skyValue = lastAvailableData?["skyValue"] ?? "";
        String ptyValue = lastAvailableData?["ptyValue"] ?? "";

        // 날씨 상태 설정
        String weatherState;
        if (ptyValue.isNotEmpty && ptyValue != "0") {
          weatherState = getWeatherDescription("PTY", ptyValue);
        } else if (skyValue.isNotEmpty) {
          weatherState = getWeatherDescription("SKY", skyValue);
        } else {
          weatherState = "알 수 없음";
        }

        forecastList.add({
          "hour": displayHour,
          "temperature": temperature,
          "icon": getWeatherIcon(weatherState),
        });

        forecastTime = forecastTime.add(Duration(hours: 1));
      }

      hourlyForecast = forecastList;
      notifyListeners();
    } else {
      print("시간별 예보 데이터를 불러오는 데 실패했습니다: ${response.statusCode}");
    }
  }

  Future<void> fetchWeatherData(double latitude, double longitude) async {
    final String apiUrl =
        "http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtFcst";
    final DateTime now = DateTime.now();
    String baseDate = DateFormat('yyyyMMdd').format(now);
    int hour = now.hour;
    String baseTime;

    if (now.minute < 45) {
      hour = hour == 0 ? 23 : hour - 1;
      baseDate = hour == 23
          ? DateFormat('yyyyMMdd').format(now.subtract(Duration(days: 1)))
          : baseDate;
    }
    baseTime = '${hour.toString().padLeft(2, '0')}30';

    final coordinates = convertToGridCoordinates(latitude, longitude);
    final int nx = coordinates['nx']!;
    final int ny = coordinates['ny']!;

    final response = await http.get(Uri.parse(
      "$apiUrl?serviceKey=$weatherServiceKey&numOfRows=100&pageNo=1&dataType=JSON&base_date=$baseDate&base_time=$baseTime&nx=$nx&ny=$ny",
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['response']['body']['items']['item'];

      String skyValue = "";
      String ptyValue = "";

      for (var item in items) {
        switch (item['category']) {
          case 'T1H':
            temperature = "${item['fcstValue']}°";
            break;
          case 'SKY':
            skyValue = item['fcstValue'];
            break;
          case 'PTY':
            ptyValue = item['fcstValue'];
            break;
          case 'REH':
            humidity = "${item['fcstValue']}%";
            break;
          case 'WSD':
            windSpeed = "${item['fcstValue']} m/s";
            break;
          case 'VEC':
            windDirection = double.parse(item['fcstValue']);
            break;
        }
      }

      if (ptyValue.isNotEmpty && ptyValue != "0") {
        weatherState = getWeatherDescription("PTY", ptyValue);
      } else if (skyValue.isNotEmpty) {
        weatherState = getWeatherDescription("SKY", skyValue);
      } else {
        weatherState = "맑음";
      }

      feelsLikeTemperature = calculateFeelsLikeTemperature(
            double.parse(temperature.replaceAll('°', '')),
            double.parse(humidity.replaceAll('%', '')),
            double.parse(windSpeed.replaceAll(' m/s', '')),
          ).toStringAsFixed(1) +
          "°C";

      windDirectionText = convertWindDirectionToCompass(windDirection);

      notifyListeners();
    } else {
      print("데이터를 불러오는 데 실패했습니다: ${response.statusCode}");
    }
  }

  Future<void> fetchTemperatureData(double latitude, double longitude) async {
    final String apiUrl =
        'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst';
    final DateTime now = DateTime.now();
    final String baseDate = DateFormat('yyyyMMdd').format(now);
    final String baseTime = '0500';

    final coordinates = convertToGridCoordinates(latitude, longitude);
    final int nx = coordinates['nx']!;
    final int ny = coordinates['ny']!;

    final response = await http.get(Uri.parse(
      '$apiUrl?serviceKey=$weatherServiceKey&numOfRows=1000&pageNo=1&dataType=JSON&base_date=$baseDate&base_time=$baseTime&nx=$nx&ny=$ny',
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['response']['body']['items']['item'];

      String minTemp = '-';
      String maxTemp = '-';

      for (var item in items) {
        if (item['category'] == 'TMN') {
          minTemp = item['fcstValue'];
        } else if (item['category'] == 'TMX') {
          maxTemp = item['fcstValue'];
        }
      }

      temperatureMin = minTemp + '°';
      temperatureMax = maxTemp + '°';

      notifyListeners();
    } else {
      print("데이터를 불러오는 데 실패했습니다: ${response.statusCode}");
    }
  }

  Future<void> fetchAirQualityData() async {
    final String apiUrl =
        'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty'
        '?serviceKey=$weatherServiceKey&returnType=json&numOfRows=100&pageNo=1&sidoName=대전&ver=1.0';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['response']?['body']?['items'];

        if (items != null && items.isNotEmpty) {
          Map<String, dynamic>? validItem;
          for (var item in items) {
            if (item['pm10Value'] != null &&
                item['pm10Value'] != '-' &&
                item['pm25Value'] != null &&
                item['pm25Value'] != '-') {
              validItem = item;
              break;
            }
          }

          if (validItem != null) {
            double pm10Value = double.parse(validItem['pm10Value']);
            double pm25Value = double.parse(validItem['pm25Value']);
            fineDustValue = '${pm10Value}㎍/㎥';
            ultraFineDustValue = '${pm25Value}㎍/㎥';
            fineDustLevel = getDustLevel(pm10Value, 'pm10');
            ultraFineDustLevel = getDustLevel(pm25Value, 'pm25');
          } else {
            fineDustValue = "알 수 없음";
            ultraFineDustValue = "알 수 없음";
            fineDustLevel = "알 수 없음";
            ultraFineDustLevel = "알 수 없음";
            print("유효한 미세먼지 데이터를 찾을 수 없습니다.");
          }
          notifyListeners();
        } else {
          print("미세먼지 데이터가 없습니다.");
        }
      } else {
        print("미세먼지 데이터를 가져오는 데 실패했습니다: ${response.statusCode}");
      }
    } catch (e) {
      print("미세먼지 데이터를 가져오는 중 오류 발생: $e");
    }
  }

  Future<void> fetchWeeklyForecast(double latitude, double longitude) async {
    DateTime now = DateTime.now();
    String baseDate = DateFormat('yyyyMMdd').format(now);
    String tmFc = now.hour < 6
        ? DateFormat('yyyyMMdd').format(now.subtract(Duration(days: 1))) +
            "1800"
        : DateFormat('yyyyMMdd').format(now) + "0600";

    final String shortTermForecastUrl =
        'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst?serviceKey=$weatherServiceKey&numOfRows=1000&pageNo=1&dataType=json&base_date=$baseDate&base_time=0500&nx=60&ny=127';

    final String midTempApiUrl =
        'https://apis.data.go.kr/1360000/MidFcstInfoService/getMidTa?serviceKey=$weatherServiceKey&pageNo=1&numOfRows=10&dataType=json&regId=11B10101&tmFc=$tmFc';
    final String midLandApiUrl =
        'https://apis.data.go.kr/1360000/MidFcstInfoService/getMidLandFcst?serviceKey=$weatherServiceKey&pageNo=1&numOfRows=10&dataType=json&regId=11B00000&tmFc=$tmFc';

    List<Map<String, String>> forecastList = [];

    try {
      // 내일과 모레의 단기 예보 데이터를 가져오기
      final shortTermResponse = await http.get(Uri.parse(shortTermForecastUrl));
      if (shortTermResponse.statusCode == 200) {
        final shortTermData = json.decode(shortTermResponse.body);
        final shortTermItems =
            shortTermData['response']['body']['items']['item'];

        for (int i = 1; i <= 2; i++) {
          String day = DateFormat('MM월 dd일 (E)', 'ko_KR')
              .format(now.add(Duration(days: i)));

          String weatherAm = '';
          String weatherPm = '';
          String minTemp = '-';
          String maxTemp = '-';
          String rainProbabilityAm = '-';
          String rainProbabilityPm = '-';

          for (var item in shortTermItems) {
            String forecastDate =
                DateFormat('yyyyMMdd').format(now.add(Duration(days: i)));

            if (item['fcstDate'] == forecastDate) {
              if (item['fcstTime'] == '0600') {
                if (item['category'] == 'POP') {
                  rainProbabilityAm = item['fcstValue'].toString();
                }
                if (item['category'] == 'SKY' && weatherAm.isEmpty) {
                  weatherAm = getWeatherDescription(
                      item['category'], item['fcstValue']);
                }
                if (item['category'] == 'PTY' && item['fcstValue'] != "0") {
                  weatherAm = getWeatherDescription(
                      item['category'], item['fcstValue']);
                }
              }
              if (item['fcstTime'] == '1800') {
                if (item['category'] == 'POP') {
                  rainProbabilityPm = item['fcstValue'].toString();
                }
                if (item['category'] == 'SKY' && weatherPm.isEmpty) {
                  weatherPm = getWeatherDescription(
                      item['category'], item['fcstValue']);
                }
                if (item['category'] == 'PTY' && item['fcstValue'] != "0") {
                  weatherPm = getWeatherDescription(
                      item['category'], item['fcstValue']);
                }
              }
              if (item['category'] == 'TMN') {
                minTemp = item['fcstValue'] + '°C';
              } else if (item['category'] == 'TMX') {
                maxTemp = item['fcstValue'] + '°C';
              }
            }
          }

          forecastList.add({
            "day": day,
            "minTemp": minTemp,
            "maxTemp": maxTemp,
            "weatherAm": weatherAm,
            "weatherPm": weatherPm,
            "rainProbabilityAm": rainProbabilityAm,
            "rainProbabilityPm": rainProbabilityPm,
          });
        }
      } else {
        print("단기 예보 데이터를 불러오는 데 실패했습니다: ${shortTermResponse.statusCode}");
      }

      // 3일 후부터 7일 후까지의 중기 예보 데이터를 가져오기
      final tempResponse = await http.get(Uri.parse(midTempApiUrl));
      final landResponse = await http.get(Uri.parse(midLandApiUrl));

      if (tempResponse.statusCode == 200 && landResponse.statusCode == 200) {
        final tempData = json.decode(tempResponse.body);
        final landData = json.decode(landResponse.body);

        if (tempData['response']?['body']?['items']?['item'] != null &&
            landData['response']?['body']?['items']?['item'] != null) {
          for (int i = 3; i <= 7; i++) {
            String day = DateFormat('MM월 dd일 (E)', 'ko_KR')
                .format(now.add(Duration(days: i)));

            String minTemp = (tempData['response']['body']['items']['item'][0]
                        ['taMin$i'] ??
                    '-')
                .toString();
            String maxTemp = (tempData['response']['body']['items']['item'][0]
                        ['taMax$i'] ??
                    '-')
                .toString();
            String weatherAm = landData['response']['body']['items']['item'][0]
                    ['wf${i}Am'] ??
                '알 수 없음';
            String weatherPm = landData['response']['body']['items']['item'][0]
                    ['wf${i}Pm'] ??
                '알 수 없음';
            String rainProbabilityAm = (landData['response']['body']['items']
                        ['item'][0]['rnSt${i}Am'] ??
                    '-')
                .toString();
            String rainProbabilityPm = (landData['response']['body']['items']
                        ['item'][0]['rnSt${i}Pm'] ??
                    '-')
                .toString();

            forecastList.add({
              "day": day,
              "minTemp": '$minTemp°C',
              "maxTemp": '$maxTemp°C',
              "weatherAm": weatherAm,
              "weatherPm": weatherPm,
              "rainProbabilityAm": rainProbabilityAm,
              "rainProbabilityPm": rainProbabilityPm,
            });
          }
        } else {
          print("중기 예보 데이터가 비어 있습니다.");
        }
      } else {
        print("중기 예보 데이터를 가져오는 데 실패했습니다.");
      }

      weeklyForecast = forecastList; // 데이터를 상태에 반영
      notifyListeners(); // 변경 사항 알림
    } catch (e) {
      weeklyForecast = [];
      print("예보 데이터를 가져오는 중 오류 발생: $e");
      notifyListeners();
    }
  }
}

double calculateFeelsLikeTemperature(
    double temperature, double humidity, double windSpeed) {
  return 13.12 +
      0.6215 * temperature -
      11.37 * pow(windSpeed, 0.16) +
      0.3965 * temperature * pow(windSpeed, 0.16);
}

String convertWindDirectionToCompass(double direction) {
  if ((direction >= 337.5 && direction <= 360) ||
      (direction >= 0 && direction < 22.5)) {
    return '북풍';
  } else if (direction >= 22.5 && direction < 67.5) {
    return '북동풍';
  } else if (direction >= 67.5 && direction < 112.5) {
    return '동풍';
  } else if (direction >= 112.5 && direction < 157.5) {
    return '남동풍';
  } else if (direction >= 157.5 && direction < 202.5) {
    return '남풍';
  } else if (direction >= 202.5 && direction < 247.5) {
    return '남서풍';
  } else if (direction >= 247.5 && direction < 292.5) {
    return '서풍';
  } else if (direction >= 292.5 && direction < 337.5) {
    return '북서풍';
  } else {
    return '알 수 없음';
  }
}

String getWeatherDescription(String category, String value) {
  if (category == 'PTY') {
    switch (value) {
      case "0":
        return "강수 없음";
      case "1":
        return "비";
      case "2":
        return "비/눈";
      case "3":
        return "눈";
      case "5":
        return "빗방울";
      case "6":
        return "빗방울/눈날림";
      case "7":
        return "눈날림";
      default:
        return "알 수 없음";
    }
  } else if (category == 'SKY') {
    switch (value) {
      case "1":
        return "맑음";
      case "3":
        return "구름 많음";
      case "4":
        return "흐림";
      default:
        return "알 수 없음";
    }
  }
  return "알 수 없음";
}

String getDustLevel(double value, String type) {
  if (type == 'pm10') {
    if (value <= 30) return '좋음';
    if (value <= 80) return '보통';
    if (value <= 150) return '나쁨';
    return '매우나쁨';
  } else if (type == 'pm25') {
    if (value <= 15) return '좋음';
    if (value <= 35) return '보통';
    if (value <= 75) return '나쁨';
    return '매우나쁨';
  }
  return '알 수 없음';
}
