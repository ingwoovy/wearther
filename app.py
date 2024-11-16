from flask import Flask, jsonify, request
import requests
import os
from dotenv import load_dotenv

load_dotenv()  # .env 파일에서 API 키 로드

app = Flask(__name__)
API_KEY = os.getenv("API_KEY")  # .env에 저장된 API 키를 사용

@app.route('/weather', methods=['GET'])
def get_weather():
    base_date = request.args.get('base_date')
    base_time = request.args.get('base_time')
    nx = request.args.get('nx')
    ny = request.args.get('ny')
    
    url = (
        f'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst'
        f'?serviceKey={API_KEY}&pageNo=1&numOfRows=1000&dataType=JSON'
        f'&base_date={base_date}&base_time={base_time}&nx={nx}&ny={ny}'
    )

    response = requests.get(url)
    
    if response.status_code == 200:
        weather_data = response.json()
        return jsonify(weather_data)
    else:
        return jsonify({"error": "Failed to fetch weather data"}), response.status_code

if __name__ == '__main__':
    app.run(debug=True)
