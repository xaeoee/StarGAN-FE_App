import 'dart:ffi';
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
  var server_uri = '백엔드 서버 주소'; // 서버 주소와 엔드포인트 확인 필요 ex) 127.0.0.1:3000
  Future<void> _pickImg(ImageSource imageSource) async {
    final XFile? pickedImage = await _picker.pickImage(source: imageSource);
    if (pickedImage != null) {
      setState(() {
        image = XFile(pickedImage.path);
        loading = 1;
      });
      _generateImg();
    }
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

  Future<void> _generateImg() async{
    if (image == null) {
      print('No image selected.');
      return;
    }
    final bytes = await File(image!.path).readAsBytes();
    String base64Image = base64Encode(bytes);
    var uri = server_uri + '/generate';
    http.Response response = await http.post(
      Uri.parse(uri),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image': base64Image,
      }),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        images = data['images'];
        labels = data['labels'];
        loading = 0;
      });
      print(images[0]);
    } else {
      print('Image upload failed with status: ${response.statusCode}');
    }
  }

  Future<void> _submitData() async{
    if (images == null) {
      print('No image exists.');
      return;
    }
    var uri = server_uri + '/submit';
    http.Response response = await http.post(
      Uri.parse(uri),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'images': images,
      }),
    );
    if (response.statusCode != 200) {
      print('Image upload failed with status: ${response.statusCode}');
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
