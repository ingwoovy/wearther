import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  // 성별 정보 (예시: "남성" 또는 "여성")
  final String gender = "남성"; // 예: "남성" 또는 "여성"

  @override
  Widget build(BuildContext context) {
    // 성별에 따른 아이콘 설정
    Icon genderIcon = gender == "남성"
        ? Icon(Icons.male, color: Colors.blue, size: 20)
        : Icon(Icons.female, color: Colors.pink, size: 20);

    return Scaffold(
      appBar: AppBar(
        title: Text('프로필'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 사진과 사용자 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, size: 60),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.add_a_photo),
                        onPressed: () {
                          // 사진 업로드 기능 추가
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "사용자 이름(ID)", // 사용자 이름
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        genderIcon, // 성별 아이콘
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "1999.05.26",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "대전 광역시",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 30),

            // 스타일 태그와 해시태그
            Wrap(
              spacing: 8.0,
              children: [
                Chip(label: Text('#해시태그1')),
                Chip(label: Text('#해시태그2')),
                Chip(label: Text('#해시태그3')),
                Chip(label: Text('#해시태그4')),
                Chip(label: Text('#해시태그5')),
                Chip(label: Text('#해시태그6')),
              ],
            ),
            SizedBox(height: 30),

            // 로그인 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('로그인'),
            ),
            SizedBox(height: 10),
            // 로그아웃 버튼
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('로그아웃'),
                      content: Text('정말 로그아웃 하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('확인'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: '아이디'),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 10),

            // 아이디/비밀번호 찾기, 회원가입 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    // 아이디 찾기 기능 추가
                  },
                  child: Text('아이디 찾기'),
                ),
                TextButton(
                  onPressed: () {
                    // 비밀번호 찾기 기능 추가
                  },
                  child: Text('비밀번호 찾기'),
                ),
                TextButton(
                  onPressed: () {
                    // 회원가입 기능 추가
                  },
                  child: Text('회원가입'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 계정 연동 버튼
            Center(
              child: Wrap(
                spacing: 16.0,
                children: [
                  IconButton(
                    icon: Image.asset('assets/images/google.png', width: 24),
                    onPressed: () {
                      // 구글 연동 코드 추가
                    },
                  ),
                  IconButton(
                    icon: Image.asset('assets/images/kakao.png', width: 24),
                    onPressed: () {
                      // 카카오 연동 코드 추가
                    },
                  ),
                  IconButton(
                    icon: Image.asset('assets/images/naver.png', width: 24),
                    onPressed: () {
                      // 네이버 연동 코드 추가
                    },
                  ),
                  IconButton(
                    icon: Image.asset('assets/images/instagram.png', width: 24),
                    onPressed: () {
                      // 인스타그램 연동 코드 추가
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
