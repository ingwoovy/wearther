import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String currentTheme;

  SettingsScreen({this.currentTheme = "도시"});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> themes = ["도시", "숲", "바다", "한강 뷰"];
  late String selectedTheme;

  @override
  void initState() {
    super.initState();
    selectedTheme = widget.currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정 화면'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "배경 테마 선택",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedTheme,
              onChanged: (String? newTheme) {
                setState(() {
                  selectedTheme = newTheme!;
                });
              },
              items: themes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, selectedTheme); // 선택된 테마 반환
                },
                child: Text("저장"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
