import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  var server_uri = 'http://192.168.1.28:3000';

  Future<void> _pickImg(ImageSource imageSource) async {
    print("You pressed button and you are now in _pickImg method");
    showSnackBar(context, 'You pressed button and you are now in _pickImg method');
    final XFile? pickedImage = await _picker.pickImage(source: imageSource);

    if (pickedImage != null) {
      setState(() {
        image = pickedImage;
        loading = 1;
      });
      showSnackBar(context, 'Right before calling _generateImg method');
      _generateImg();
    } else {
      showSnackBar(context, 'No image selected');
    }
  }

  Future<void> _reImage(ImageSource imageSource, int index) async {
    final XFile? pickedImage = await _picker.pickImage(source: imageSource);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() {
        images[index] = base64Encode(bytes);
      });
    }
  }

  void goBack() {
    if (current_index > 1) {
      setState(() {
        current_index = current_index - 1;
      });
    }
  }

  void goNext() {
    if (current_index < labels.length - 1) {
      setState(() {
        current_index = current_index + 1;
      });
    }
  }

  Future<void> _generateImg() async {
    showSnackBar(context, 'Inside _generateImg method');

    if (image == null) {
      print('No image selected.');
      showSnackBar(context, 'No image selected.');
      return;
    }

    final bytes = await image!.readAsBytes();
    String base64Image = base64Encode(bytes);
    var uri = server_uri + '/generate';
    showSnackBar(context, 'Requesting to: $uri');

    try {
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
        showSnackBar(context, 'Image processed successfully!');

        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          images = data['images'];
          labels = data['labels'];
          loading = 0;
        });

        print(images[0]);
      } else {
        showSnackBar(context, 'Failed to process image: Status ${response.statusCode}');
        print('Image upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      showSnackBar(context, 'Request error: $e');
      print('Error occurred during POST request: $e');
    }
  }

  Future<void> _submitData() async {
    if (images.isEmpty) {
      print('No image exists.');
      showSnackBar(context, 'No image exists.');
      return;
    }

    var uri = server_uri + '/submit';
    print('Requesting to: $uri');
    showSnackBar(context, 'Requesting to: $uri');

    try {
      http.Response response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'images': images,
        }),
      );

      print('Response status: ${response.statusCode}');
      showSnackBar(context, 'Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Image upload successful.');
        showSnackBar(context, 'Image upload successful.');
      } else {
        print('Image upload failed with status: ${response.statusCode}');
        showSnackBar(context, 'Image upload failed: ${response.statusCode}');
      }

      print('Response body: ${response.body}');
      showSnackBar(context, 'Response body: ${response.body}');

    } catch (e) {
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
                      _pickImg(ImageSource.camera);
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
                  if (images.isNotEmpty) ...[
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
              if (images.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    _submitData();
                    Fluttertoast.showToast(
                        msg: "이미지 전송이 완료되었습니다.",
                        gravity: ToastGravity.BOTTOM_RIGHT,
                        backgroundColor: Colors.lightGreenAccent,
                        fontSize: 20,
                        textColor: Colors.black,
                        toastLength: Toast.LENGTH_SHORT
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
        ? FutureBuilder<Uint8List>(
      future: image!.readAsBytes(),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Container(
            width: 200,
            height: 300,
            child: Image.memory(snapshot.data!, fit: BoxFit.fitHeight),
          );
        } else {
          return Container(
            width: 200,
            height: 300,
            color: Colors.grey,
          );
        }
      },
    )
        : Container(
      width: 200,
      height: 300,
      color: Colors.grey,
    );
  }
}