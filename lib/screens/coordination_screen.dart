import 'package:flutter/material.dart';

class CoordinationScreen extends StatelessWidget {
  // ScrollController 추가
  final ScrollController _scrollController = ScrollController();

  // 현재 온도 (예시로 설정)
  final double currentTemperature = 19.0;

  // 각 기온대별 추천 코디 목록
  final List<Map<String, dynamic>> temperatureOutfits = [
    {
      "range": "28°C 이상",
      "color": Colors.redAccent,
      "outfits": [
        {"emoji": "👕🩳", "description": "민소매 + 반바지"},
        {"emoji": "👚👖", "description": "얇은 셔츠 + 린넨 바지"},
        {"emoji": "🩳👕", "description": "반팔 티셔츠 + 반바지"},
      ],
    },
    {
      "range": "27~23°C",
      "color": Colors.orangeAccent,
      "outfits": [
        {"emoji": "👕👚", "description": "반팔 + 얇은 셔츠"},
        {"emoji": "👖🩳", "description": "린넨 바지 + 반바지"},
        {"emoji": "👚", "description": "면 티셔츠"},
      ],
    },
    {
      "range": "22~20°C",
      "color": Colors.yellowAccent,
      "outfits": [
        {"emoji": "👔👖", "description": "블라우스 + 슬랙스"},
        {"emoji": "👖👕", "description": "긴팔 티 + 면바지"},
        {"emoji": "👕👖", "description": "셔츠 + 청바지"},
      ],
    },
    {
      "range": "19~17°C",
      "color": Colors.lightGreenAccent,
      "outfits": [
        {"emoji": "🧥👚", "description": "얇은 가디건 + 후드"},
        {"emoji": "👖👕", "description": "맨투맨 + 청바지"},
        {"emoji": "👔👖", "description": "자켓 + 면바지"},
      ],
    },
    {
      "range": "16~12°C",
      "color": Colors.greenAccent,
      "outfits": [
        {"emoji": "🧥👖", "description": "자켓 + 청바지"},
        {"emoji": "🧥🧦", "description": "니트 + 스타킹"},
        {"emoji": "🧥👖", "description": "트렌치 코트 + 청바지"},
      ],
    },
    {
      "range": "11~9°C",
      "color": Colors.lightBlueAccent,
      "outfits": [
        {"emoji": "🧥👖", "description": "야상 + 기모바지"},
        {"emoji": "🧥🧦", "description": "점퍼 + 스타킹"},
        {"emoji": "🧥👖", "description": "가죽 자켓 + 청바지"},
      ],
    },
    {
      "range": "8~5°C",
      "color": Colors.blueAccent,
      "outfits": [
        {"emoji": "🧥👔", "description": "울코트 + 니트"},
        {"emoji": "🧥👖", "description": "히트텍 + 가죽 자켓"},
        {"emoji": "🧥👖", "description": "기모 옷 + 스타킹"},
      ],
    },
    {
      "range": "4°C 이하",
      "color": Colors.indigo,
      "outfits": [
        {"emoji": "🧥🧣", "description": "패딩 + 기모 바지"},
        {"emoji": "🧥🧣", "description": "두꺼운 코트 + 목도리"},
        {"emoji": "🧤🧢", "description": "장갑 + 모자"},
      ],
    },
  ];

  // 상황별 추천 코디 목록
  final List<Map<String, dynamic>> situationOutfits = [
    {
      "situation": "결혼식",
      "color": Colors.pinkAccent,
      "outfits": [
        {"emoji": "👗👠", "description": "드레스 + 하이힐"},
        {"emoji": "👔👖", "description": "셔츠 + 슬랙스"},
        {"emoji": "🧥👖", "description": "블레이저 + 정장 바지"},
      ],
    },
    {
      "situation": "장례식",
      "color": Colors.grey,
      "outfits": [
        {"emoji": "🖤👔", "description": "검은 정장 + 검은 넥타이"},
        {"emoji": "👞", "description": "검은 구두"},
        {"emoji": "🧥👖", "description": "검은 코트 + 정장 바지"},
      ],
    },
    {
      "situation": "출장",
      "color": Colors.blueGrey,
      "outfits": [
        {"emoji": "👔👖", "description": "셔츠 + 슬랙스"},
        {"emoji": "💼", "description": "서류 가방"},
        {"emoji": "🧥👖", "description": "자켓 + 정장 바지"},
      ],
    },
    {
      "situation": "등산",
      "color": Colors.green,
      "outfits": [
        {"emoji": "🧢👕", "description": "모자 + 땀 흡수 티셔츠"},
        {"emoji": "🎒", "description": "배낭"},
        {"emoji": "👖👟", "description": "등산 바지 + 등산화"},
      ],
    },
    {
      "situation": "해변",
      "color": Colors.lightBlueAccent,
      "outfits": [
        {"emoji": "🩳👕", "description": "반바지 + 반팔 티셔츠"},
        {"emoji": "🕶️", "description": "선글라스"},
        {"emoji": "🩴", "description": "슬리퍼"},
      ],
    },
  ];

  // 현재 온도에 맞는 추천 코디 가져오기
  List<Map<String, String>> getRecommendedOutfits(double temperature) {
    if (temperature >= 28) {
      return [
        {"emoji": "👕🩳", "description": "민소매 + 반바지"},
        {"emoji": "👚👖", "description": "얇은 셔츠 + 린넨 바지"},
        {"emoji": "🩳👕", "description": "반팔 티셔츠 + 반바지"},
      ];
    } else if (temperature >= 23) {
      return [
        {"emoji": "👕👚", "description": "반팔 + 얇은 셔츠"},
        {"emoji": "👖🩳", "description": "린넨 바지 + 반바지"},
        {"emoji": "👚", "description": "면 티셔츠"},
      ];
    } else if (temperature >= 20) {
      return [
        {"emoji": "👔👖", "description": "블라우스 + 슬랙스"},
        {"emoji": "👖👕", "description": "긴팔 티 + 면바지"},
        {"emoji": "👕👖", "description": "셔츠 + 청바지"},
      ];
    } else if (temperature >= 17) {
      return [
        {"emoji": "🧥👚", "description": "얇은 가디건 + 후드"},
        {"emoji": "👖👕", "description": "맨투맨 + 청바지"},
        {"emoji": "👔👖", "description": "자켓 + 면바지"},
      ];
    } else if (temperature >= 12) {
      return [
        {"emoji": "🧥👖", "description": "자켓 + 청바지"},
        {"emoji": "🧥🧦", "description": "니트 + 스타킹"},
        {"emoji": "🧥👖", "description": "트렌치 코트 + 청바지"},
      ];
    } else if (temperature >= 9) {
      return [
        {"emoji": "🧥👖", "description": "야상 + 기모바지"},
        {"emoji": "🧥🧦", "description": "점퍼 + 스타킹"},
        {"emoji": "🧥👖", "description": "가죽 자켓 + 청바지"},
      ];
    } else if (temperature >= 5) {
      return [
        {"emoji": "🧥👔", "description": "울코트 + 니트"},
        {"emoji": "🧥👖", "description": "히트텍 + 가죽 자켓"},
        {"emoji": "🧥👖", "description": "기모 옷 + 스타킹"},
      ];
    } else {
      return [
        {"emoji": "🧥🧣", "description": "패딩 + 기모 바지"},
        {"emoji": "🧥🧣", "description": "두꺼운 코트 + 목도리"},
        {"emoji": "🧤🧢", "description": "장갑 + 모자"},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 온도에 맞는 추천 코디 리스트 가져오기
    List<Map<String, String>> recommendedOutfits =
        getRecommendedOutfits(currentTemperature);

    return Scaffold(
      appBar: AppBar(
        title: Text('기온별 코디 추천'),
      ),
      body: Scrollbar(
        controller: _scrollController, // ScrollController 연결
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController, // ScrollController 연결
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("기온별 코디표",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              // 전체 기온 범위별 코디표
              Column(
                children: temperatureOutfits.map((temp) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: temp['color'],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          temp['range'],
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:
                              (temp['outfits'] as List<Map<String, String>>)
                                  .map((outfit) {
                            return Column(
                              children: [
                                Text(
                                  outfit['emoji']!,
                                  style: TextStyle(fontSize: 20),
                                ),
                                Text(
                                  outfit['description']!,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              // 현재 온도와 그에 맞는 추천 코디
              Text("현재 온도: ${currentTemperature.toStringAsFixed(1)}°C",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: recommendedOutfits.map((outfit) {
                    return Row(
                      children: [
                        Text(
                          outfit['emoji']!,
                          style: TextStyle(fontSize: 30),
                        ),
                        SizedBox(width: 10),
                        Text(outfit['description']!),
                      ],
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16),
              // 상황별 코디표
              Text("상황별 코디표",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Column(
                children: situationOutfits.map((situation) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: situation['color'],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          situation['situation'],
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: (situation['outfits']
                                  as List<Map<String, String>>)
                              .map((outfit) {
                            return Column(
                              children: [
                                Text(
                                  outfit['emoji']!,
                                  style: TextStyle(fontSize: 20),
                                ),
                                Text(
                                  outfit['description']!,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
