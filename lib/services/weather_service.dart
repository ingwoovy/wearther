import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey =
      'EA4AAbCXXGqyAq9O%2BcZcE6%2FgZlRHARIEkTA022v2t%2B9IjX9Vj7I4Smpba8tWwMQgzPIJPlbjM9GYEMj48DLM6w%3D%3D';

  Future<Map<String, dynamic>> fetchWeatherData(
      String baseDate, String baseTime, int nx, int ny) async {
    final url =
        'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst?serviceKey=$apiKey&pageNo=1&numOfRows=1000&dataType=JSON&base_date=$baseDate&base_time=$baseTime&nx=$nx&ny=$ny';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['response']['body']['items']['item'][0];
    } else {
      throw Exception("Failed to load weather data");
    }
  }
}
