# StarGAN-FE Flutter App

## 자폐 아동을 위한 감정 생성 모델 Test 용 Flutter 앱

### Environment Set-up

flutter 환경 세팅은 다음 [영상](https://youtu.be/usE9IKaogDU?feature=shared)을 참고한다.

- git clone
  ```
  git clone https://github.com/seoin0110/StarGAN-FE_App.git
  cd StarGAN-FE_App
  ```
- Flutter 실행 (갤러리/카메라 앱 참조를 위해 실제 device에서 테스트 권장)
  ```bash
  flutter pub get
  flutter run lib/main.dart
  ```
- 코드 수정 (백엔드 서버 주소 할당)
  ```dart
  // backend 실행 후, lib/main.dart에서
  // 아래와 같이 server_uri 변수 수정
  var server_uri = '127.0.0.1:3000';
  ```

### 실행 영상
