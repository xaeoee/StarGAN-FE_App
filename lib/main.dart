// import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';


void main() {
  runApp(const MyApp());
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),  // 2초 동안 표시
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generate Facial Expression Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: '감정 생성하기'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? image;
  List<dynamic> images = [];
  List<dynamic> labels = [];
  int loading = 0;
  int current_index = 1;
  var server_uri = 'http://192.168.1.28:3000';  // 또는 192.168.1.119 중 하나 사용
  Future<void> _pickImg(ImageSource imageSource) async {
    print("You pressed button and you are now in _pcikImg method'");
    showSnackBar(context, 'You pressed button and you are now in _pcikImg method');  // 함수 호출 시 Snackbar 표시
    final XFile? pickedImage = await _picker.pickImage(source: imageSource);

    if (pickedImage != null) {
      setState(() {
        image = XFile(pickedImage.path);
        loading = 1;
      });
      showSnackBar(context, 'right before calling _generateImg method');  // 함수 호출 시 Snackbar 표시
      _generateImg();
    }
    showSnackBar(context, 'probably pcikedImage is null');  // 함수 호출 시 Snackbar 표시
  }

  Future<void> _reImage(ImageSource imageSource, int index) async {
    final XFile? pickedImage = await _picker.pickImage(source: imageSource);
    if (pickedImage != null) {
      final bytes = await File(pickedImage.path).readAsBytes();
      setState(() {
        images[index] = base64Encode(bytes);
      });
    }
  }

  void goBack(){
    if(current_index > 1){
      setState((){
        current_index = current_index - 1;
      });
    }
  }

  void goNext(){
    if(current_index < labels.length - 1){
      setState((){
        current_index = current_index + 1;
      });
    }
  }

  // Future<void> _generateImg() async{
  //   showSnackBar(context, 'Inside _generateImg method');  // 함수 호출 시 Snackbar 표시
  //
  //   if (image == null) {
  //     print('No image selected.');
  //     showSnackBar(context, 'No image selected.');  // 함수 호출 시 Snackbar 표시
  //     return;
  //   }
  //   final bytes = await File(image!.path).readAsBytes();
  //   String base64Image = base64Encode(bytes);
  //   var uri = server_uri + '/generate';
  //   showSnackBar(context, uri);  // 함수 호출 시 Snackbar 표시
  //   showSnackBar(context, uri);  // 함수 호출 시 Snackbar 표시
  //
  //   http.Response response = await http.post(
  //     Uri.parse(uri),
  //     headers: {
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode({
  //       'image': base64Image,
  //     }),
  //   );
  //   showSnackBar(context, 'after posting');  // 함수 호출 시 Snackbar 표시
  //   showSnackBar(context, uri);  // 함수 호출 시 Snackbar 표시
  //
  //   if (response.statusCode == 200) {
  //     showSnackBar(context, 'success');  // 함수 호출 시 Snackbar 표시
  //
  //     final Map<String, dynamic> data = json.decode(response.body);
  //     setState(() {
  //       images = data['images'];
  //       labels = data['labels'];
  //       loading = 0;
  //     });
  //     print(images[0]);
  //   } else {
  //     showSnackBar(context, 'failed');  // 함수 호출 시 Snackbar 표시
  //
  //     print('Image upload failed with status: ${response.statusCode}');
  //   }
  // }

  Future<void> _generateImg() async {
    // 처음 함수 호출 시 _generateImg 실행 알림
    showSnackBar(context, 'Inside _generateImg method');

    // 이미지가 선택되지 않은 경우
    if (image == null) {
      print('No image selected.');
      showSnackBar(context, 'No image selected.');
      return;
    }

    // 이미지가 선택된 경우 base64 인코딩 및 URL 설정
    final bytes = await File(image!.path).readAsBytes();
    String base64Image = base64Encode(bytes);
    var uri = server_uri + '/generate';

    // 요청할 URI를 SnackBar로 표시
    showSnackBar(context, 'Requesting to: $uri');

    try {
      // POST 요청 전송
      http.Response response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      // 요청 후 결과 처리
      if (response.statusCode == 200) {
        // 성공적으로 이미지가 처리된 경우
        showSnackBar(context, 'Image processed successfully!');

        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          images = data['images'];
          labels = data['labels'];
          loading = 0;
        });

        // 첫 번째 이미지 출력
        print(images[0]);
      } else {
        // 서버가 200이 아닌 상태 코드를 반환했을 때
        showSnackBar(context, 'Failed to process image: Status ${response.statusCode}');
        print('Image upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // 요청 중 오류 발생 시
      showSnackBar(context, 'Request error: $e');
      print('Error occurred during POST request: $e');
    }
  }

  Future<void> _submitData() async {
    // 이미지가 null인지 확인
    if (images == null || images.isEmpty) {
      print('No image exists.');
      showSnackBar(context, 'No image exists.');  // SnackBar로 알림
      return;
    }

    // 서버 URI 확인
    var uri = server_uri + '/submit';
    print('Requesting to: $uri');
    showSnackBar(context, 'Requesting to: $uri');

    try {
      // HTTP POST 요청
      http.Response response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'images': images,
        }),
      );

      // 요청 완료 후 상태 코드 확인
      print('Response status: ${response.statusCode}');
      showSnackBar(context, 'Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 성공 메시지 출력
        print('Image upload successful.');
        showSnackBar(context, 'Image upload successful.');
      } else {
        // 실패 시 상태 코드 출력
        print('Image upload failed with status: ${response.statusCode}');
        showSnackBar(context, 'Image upload failed: ${response.statusCode}');
      }

      // 응답 본문 출력 (디버깅용)
      print('Response body: ${response.body}');
      showSnackBar(context, 'Response body: ${response.body}');

    } catch (e) {
      // 예외 발생 시 처리
      print('Error during request: $e');
      showSnackBar(context, 'Error during request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPhotoArea(),
                  if (loading == 1)
                    Text("로딩 중 ..."),
                  ElevatedButton(
                    onPressed: () {
                      _pickImg(ImageSource.camera); //getImage 함수를 호출해서 카메라로 찍은 사진 가져오기
                    },
                    child: Text("카메라"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _pickImg(ImageSource.gallery);
                    },
                    child: Text('갤러리'),
                  ),
                ],
              ),
              Column(
                children: [
                  if (images.length > 0) ...[
                    Text(labels[current_index], style: TextStyle(fontSize: 20)),
                    Row(
                      children: [
                        IconButton(onPressed: goBack, icon: Icon(Icons.arrow_back_ios), iconSize: 30),
                        Image.memory(
                          base64Decode(images[current_index]),
                          height: 370,
                          fit: BoxFit.fitHeight,
                        ),
                        IconButton(onPressed: goNext, icon: Icon(Icons.arrow_forward_ios), iconSize: 30),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _reImage(ImageSource.camera, current_index);
                      },
                      child: Text("재촬영"),
                    ),
                  ],
                ],
              ),
              if (images.length > 0)
                ElevatedButton(
                  onPressed: () {
                    _submitData();
                    Fluttertoast.showToast(
                      msg: "이미지 전송이 완료되었습니다.",
                      gravity: ToastGravity.BOTTOM_RIGHT,
                      backgroundColor: Colors.lightGreenAccent,
                      fontSize: 20,
                      textColor: Colors.black,
                      toastLength:Toast.LENGTH_SHORT
                    );
                  },
                  child: Text("완료"),
                ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoArea() {
    return image != null
        ? Container(
      width: 200,
      height: 300,
      child: Image.file(File(image!.path), fit: BoxFit.fitHeight),
    )
        : Container(
      width: 200,
      height: 300,
      color: Colors.grey,
    );
  }
}
