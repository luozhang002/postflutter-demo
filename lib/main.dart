import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  void upload(String OSSAccessKeyId, String accesskeySecret, String fileName, File FileObject, String postUrl) async {

    //构建policy expriation设置该Policy的失效时间，超过这个失效时间之后，就没有办法通过这个policy上传文件了, content-length-range设置上传文件的大小限制
    String policyText =
        '{"expiration": "2020-01-01T12:00:00.000Z","conditions": [["content-length-range", 0, 1048576000]]}';
    List<int> policyText_utf8 = utf8.encode(policyText);
    String policy_base64 = base64.encode(policyText_utf8);
    List<int> policy = utf8.encode(policy_base64);

    // 利用accessKeySecret签名Policy
    List<int> keyM = utf8.encode(accesskeySecret);
    List<int> signature_pre  = new Hmac(sha1, keyM).convert(policy).bytes;
    String signature = base64.encode(signature_pre);

    Options options = new Options();
    options.responseType = ResponseType.PLAIN;
    Dio dio = new Dio(options);

    // 构建formData数据
    FormData data = new FormData.from({
      'key' : fileName,
      'policy': policy_base64,
      'OSSAccessKeyId': OSSAccessKeyId,
      'success_action_status' : '200',
      'signature': signature,
      'file': new UploadFileInfo(FileObject, fileName)
    });
    try {
      Response response = await dio.post(postUrl,data: data);
      print(response.headers);
    } on DioError catch(e) {
      print(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Welcome to Flutter'),
        ),
        body: Center(
          child: Text('Hello World'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
            upload('youraccesskeyId','yourAccessKeySecret','1.jpg',imageFile,"http://luozhang002.oss-cn-zhangjiakou.aliyuncs.com");
          },
          tooltip: 'Pick Image',
          child: Icon(Icons.add_a_photo),
        ),
      ),
    );
  }
}