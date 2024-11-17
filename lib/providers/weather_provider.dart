import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../services/coordinate_converter.dart';

class WeatherProvider extends ChangeNotifier {
  String location = "-";
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
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("위치 서비스가 비활성화되었습니다.");
      }

      // 권한 체크 및 요청
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("위치 권한이 거부되었습니다.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("위치 권한이 영구적으로 거부되었습니다.");
      }

      // 위치 정보 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 위치 정보를 이용한 추가 작업
      await _getAddressFromCoordinates(position.latitude, position.longitude);
      await fetchWeatherData(position.latitude, position.longitude);
      await fetchTemperatureData(position.latitude, position.longitude);
      await fetchAirQualityData();
      await fetchWeeklyForecast(position.latitude, position.longitude);
      await fetchHourlyForecast(position.latitude, position.longitude);
      await fetchTemperatureComparison(position.latitude, position.longitude);
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
        String city = ''; // 시
        String district = ''; // 구
        String neighborhood = ''; // 동

        for (var component in addressComponents) {
          final types = component['types'];
          if (types.contains('administrative_area_level_1')) {
            // 광역시/도
            city = component['long_name'];
          } else if (types.contains('administrative_area_level_2')) {
            // 구
            district = component['long_name'];
          } else if (types.contains('sublocality_level_1') ||
              types.contains('sublocality')) {
            // 동
            neighborhood = component['long_name'];
          }
        }

        // 최종 주소를 "대전광역시 서구 도안동" 형식으로 조합
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

    // 오늘과 어제 날짜
    String todayDate = DateFormat('yyyyMMdd').format(now);
    String yesterdayDate = DateFormat('yyyyMMdd').format(yesterday);

    // 단기예보의 가장 최근 발표 시간 계산
    String todayBaseTime = getNearestBaseTime(now);
    String yesterdayBaseTime = getNearestBaseTime(yesterday);

    final coordinates = convertToGridCoordinates(latitude, longitude);
    final int nx = coordinates['nx']!;
    final int ny = coordinates['ny']!;

    // 어제와 오늘의 데이터를 각각 가져옴
    String todayTemp =
        await fetchTemperatureForDate(todayDate, todayBaseTime, nx, ny);
    String yesterdayTemp =
        await fetchTemperatureForDate(yesterdayDate, yesterdayBaseTime, nx, ny);

    // 기온 차이 계산
    if (todayTemp != '-' && yesterdayTemp != '-') {
      double today = double.parse(todayTemp);
      double yesterday = double.parse(yesterdayTemp);
      double diff = today - yesterday;

      temperatureDiff = diff > 0
          ? '어제보다 ${diff.toStringAsFixed(1)}° 더 따뜻합니다.'
          : '어제보다 ${diff.abs().toStringAsFixed(1)}° 더 춥습니다.';
    } else {
      temperatureDiff = '기온 데이터를 가져올 수 없습니다.';
    }
    notifyListeners(); // 데이터 변경을 알림
  }

  String getNearestBaseTime(DateTime dateTime) {
    // 단기예보 발표 시간: 0200, 0500, 0800, 1100, 1400, 1700, 2000, 2300
    List<int> baseTimes = [2, 5, 8, 11, 14, 17, 20, 23];
    int hour = dateTime.hour;

    // 현재 시간보다 작거나 같은 가장 가까운 발표 시간을 선택
    int nearestBaseTime = baseTimes.lastWhere((time) => hour >= time,
        orElse: () => baseTimes.last);

    // 시간 변환
    if (hour < nearestBaseTime) {
      // 발표 전이라면 하루 전날 기준으로 계산
      dateTime = dateTime.subtract(Duration(days: 1));
    }

    return nearestBaseTime.toString().padLeft(2, '0') + '00';
  }

  Future<String> fetchTemperatureForDate(
      String date, String time, int nx, int ny) async {
    final response = await http.get(Uri.parse(
      'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst'
      '?serviceKey=$weatherServiceKey'
      '&numOfRows=100'
      '&pageNo=1'
      '&dataType=JSON'
      '&base_date=$date'
      '&base_time=$time'
      '&nx=$nx'
      '&ny=$ny',
    ));

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data['response'] != null &&
            data['response']['header']['resultCode'] == "00" &&
            data['response']['body']['items'] != null) {
          final items = data['response']['body']['items']['item'];
          var tempItem = items.firstWhere(
            (item) => item['category'] == 'TMP',
            orElse: () => null,
          );

          if (tempItem != null) {
            return tempItem['fcstValue'];
          } else {
            print("TMP 데이터가 없습니다: $items");
            return '-';
          }
        } else {
          print("API 응답 데이터가 예상과 다릅니다: ${response.body}");
          return '-';
        }
      } catch (e) {
        print("JSON 파싱 실패: $e");
        return '-';
      }
    } else {
      print("HTTP 요청 실패: ${response.statusCode}, ${response.reasonPhrase}");
      return '-';
    }
  }

  Future<void> fetchHourlyForecast(double latitude, double longitude) async {
    final String apiUrl =
        "http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst";
    final DateTime now = DateTime.now();
    DateTime baseTimeDate = now;

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
      "$apiUrl?serviceKey=$weatherServiceKey&numOfRows=300&pageNo=1&dataType=JSON&base_date=$baseDate&base_time=$baseTime&nx=$nx&ny=$ny",
    ));

    Map<String, dynamic>? cachedPreviousData;

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

        var tempItem =
            _findForecastItem(items, forecastDate, formattedHour, 'TMP');
        var skyItem =
            _findForecastItem(items, forecastDate, formattedHour, 'SKY');
        var ptyItem =
            _findForecastItem(items, forecastDate, formattedHour, 'PTY');

        // 이전 데이터 요청 및 사용
        if (tempItem == null) {
          if (cachedPreviousData == null) {
            cachedPreviousData =
                await _fetchPreviousData(baseDate, baseTime, nx, ny, apiUrl);
          }
          tempItem = _findForecastItem(
              cachedPreviousData?['items'], forecastDate, formattedHour, 'TMP');
        }

        if (tempItem != null || skyItem != null || ptyItem != null) {
          lastAvailableData = {
            "temperature": tempItem != null ? "${tempItem['fcstValue']}°" : "-",
            "skyValue": skyItem != null ? skyItem['fcstValue'] : "",
            "ptyValue": ptyItem != null ? ptyItem['fcstValue'] : "",
          };
        }

        String temperature = lastAvailableData?["temperature"] ?? "-";
        String skyValue = lastAvailableData?["skyValue"] ?? "";
        String ptyValue = lastAvailableData?["ptyValue"] ?? "";

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

  Future<Map<String, dynamic>?> _fetchPreviousData(
      String baseDate, String baseTime, int nx, int ny, String apiUrl) async {
    String previousBaseTime = calculatePreviousBaseTime(baseTime);
    String previousBaseDate = calculatePreviousBaseDate(baseDate, baseTime);

    final previousResponse = await http.get(Uri.parse(
      "$apiUrl?serviceKey=$weatherServiceKey&numOfRows=300&pageNo=1&dataType=JSON&base_date=$previousBaseDate&base_time=$previousBaseTime&nx=$nx&ny=$ny",
    ));

    if (previousResponse.statusCode == 200) {
      final previousData = json.decode(previousResponse.body);
      return {
        "items": previousData['response']['body']['items']['item'],
      };
    }
    print("이전 데이터를 불러오는 데 실패했습니다: ${previousResponse.statusCode}");
    return null;
  }

  dynamic _findForecastItem(
      List<dynamic>? items, String date, String time, String category) {
    if (items == null) return null;
    return items.firstWhere(
      (item) =>
          item['fcstDate'] == date &&
          item['fcstTime'] == time &&
          item['category'] == category,
      orElse: () => null,
    );
  }

// 이전 baseTime 계산
  String calculatePreviousBaseTime(String currentBaseTime) {
    final baseTimes = [23, 20, 17, 14, 11, 8, 5, 2];
    int currentHour = int.parse(currentBaseTime.substring(0, 2));
    int previousHour = baseTimes.lastWhere((hour) => hour < currentHour,
        orElse: () => baseTimes.last);
    return previousHour.toString().padLeft(2, '0') + "00";
  }

// 이전 baseDate 계산
  String calculatePreviousBaseDate(String baseDate, String baseTime) {
    if (baseTime == "0200") {
      DateTime date =
          DateFormat("yyyyMMdd").parse(baseDate).subtract(Duration(days: 1));
      return DateFormat("yyyyMMdd").format(date);
    }
    return baseDate;
  }

  Future<void> fetchWeatherData(double latitude, double longitude) async {
    final String apiUrl =
        "http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtFcst";
    final DateTime now = DateTime.now();
    String baseDate = DateFormat('yyyyMMdd').format(now);
    int hour = now.hour;
    String baseTime;

    // 현재 시각 기준으로 가장 가까운 발표 시간 결정
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
      final items = data['response']['body']['items']['item'] as List;

      // 현재 시간에 가장 가까운 fcstTime 찾기
      String nowTime = DateFormat('HHmm').format(now);
      String closestFcstTime = items.map((item) => item['fcstTime']).reduce(
          (a, b) => (int.parse(a).abs() - int.parse(nowTime).abs()).abs() <
                  (int.parse(b).abs() - int.parse(nowTime).abs()).abs()
              ? a
              : b);

      // 필터링: closestFcstTime과 일치하는 데이터만 가져오기
      final filteredItems =
          items.where((item) => item['fcstTime'] == closestFcstTime);

      // 필요한 데이터를 추출
      String skyValue = "";
      String ptyValue = "";

      for (var item in filteredItems) {
        switch (item['category']) {
          case 'T1H': // 기온
            temperature = "${item['fcstValue']}°";
            break;
          case 'SKY': // 하늘 상태
            skyValue = item['fcstValue'];
            break;
          case 'PTY': // 강수 형태
            ptyValue = item['fcstValue'];
            break;
          case 'REH': // 습도
            humidity = "${item['fcstValue']}%";
            break;
          case 'WSD': // 풍속
            windSpeed = "${item['fcstValue']} m/s";
            break;
          case 'VEC': // 풍향
            windDirection = double.parse(item['fcstValue']);
            break;
        }
      }

      // 날씨 상태 결정
      if (ptyValue.isNotEmpty && ptyValue != "0") {
        weatherState = getWeatherDescription("PTY", ptyValue);
      } else if (skyValue.isNotEmpty) {
        weatherState = getWeatherDescription("SKY", skyValue);
      } else {
        weatherState = "맑음";
      }

      // 체감 온도 계산
      feelsLikeTemperature = calculateFeelsLikeTemperature(
            double.parse(temperature.replaceAll('°', '')),
            double.parse(humidity.replaceAll('%', '')),
            double.parse(windSpeed.replaceAll(' m/s', '')),
          ).toStringAsFixed(1) +
          "°";

      // 풍향 변환
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
