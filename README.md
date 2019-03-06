## 什么是Flutter

Flutter是目前市面上主流的跨平台框架之一。Flutter是谷歌的移动UI框架，可以快速在iOS和Android上构建高质量的原生用户界面，Flutter可以与现有的代码一起工作。在全世界，Flutter正在被越来越多的开发者和组织使用，并且Flutter是完全免费、开源的，未来可期。

## 上传方案

本文介绍的方案主要是是基于OSS [postObject](https://help.aliyun.com/document_detail/31988.html) 进行上传，PostObject使用HTML表单上传Object到指定Bucket。当然还有一种方案就是基于Flutter插件的模式进行开发，目前github已经有开发者进行有关的插件开发，可参考[aliossflutter](https://github.com/jlcool/aliossflutter)。

Flutter平台开发是基于谷歌的Dart语言。本方案中网络层框架采用的基于Dart的dio框架，dio是一个强大的Dart Http请求库，支持Restful API、FormData、拦截器、请求取消、Cookie管理、文件上传/下载、超时等。

签名过程中涉及到的加密库采用的是基于Dart的实现多种散列加密算法的crypto框架，支持
* SHA-1
* SHA-256
* MD5
* HMAC (i.e. HMAC-MD5, HMAC-SHA1, HMAC-SHA256)。

## 签名原理

对于验证的Post请求，HTML表单中必须包含policy和Signature信息。policy控制请求中那些值是允许的。计算Signature的具体流程为：

* 创建一个 UTF-8 编码的 policy。
* 将 policy 进行 base64 编码，其值即为 policy 表单域填入的值，将该值作为将要签名的字符串。
* 使用 AccessKeySecret 对要签名的字符串进行签名，签名方法与Header中签名的计算方法相同（将要签名的字符串替换为 policy 即可），请参见在Header中包含签名。

## 签名和上传
针对签名和上传封装一个统一的upload方法，支持OSSAccessKeyId、OSSAccesskeySecret、fileName(上传文件名(支持文件夹)、FileObject(File对象)、postUrl(eg:http://{yourbucket}.oss-cn-{yourregion}.aliyuncs.com)参数。其中File对象可通过第三方flutter插件获取，比如ImagePicker插件，比如：
```java
  File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
```
表单数据的构建通过Dart自带的FormData构造表单域数据key、policy、OSSAccessKeyId、success_action_status、signature。整个方法是异步的，采用Dart自带的`async await`封装

```dart
 void upload(String OSSAccessKeyId, String OSSAccesskeySecret, String fileName, File FileObject, String postUrl) async {

    //构建policy, `expriation`设置该Policy的失效时间，超过这个失效时间之后，就没有办法通过这个policy上传文件了, `content-length-range`设置上传文件的大小限制
    String policyText =
        '{"expiration": "2020-01-01T12:00:00.000Z","conditions": [["content-length-range", 0, 1048576000]]}';
    List<int> policyText_utf8 = utf8.encode(policyText);
    String policy_base64 = base64.encode(policyText_utf8);
    List<int> policy = utf8.encode(policy_base64);

    // 利用OSSAccesskeySecret签名Policy
    List<int> key = utf8.encode(OSSAccesskeySecret);
    List<int> signature_pre  = new Hmac(sha1, key).convert(policy).bytes;
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
```

## 参考链接

* [简单可运行demo](https://github.com/luozhang002/postflutter-demo.git)
* [ Flutter官网](https://flutter.io/)
* [Flutter实战-喜欢flutter的强烈推荐](https://book.flutterchina.club/)
* [OSS postObject](https://help.aliyun.com/document_detail/31988.html)
* [aliossflutter插件](https://github.com/jlcool/aliossflutter)