//import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '驚喜',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '来，给我翻译翻译'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//翻译结果
class TransResult {
  String from;
  String to;
  List<Translation> translations;
  String error_msg;

  TransResult(
      {required this.from,
      required this.to,
      required this.translations,
      required this.error_msg});

  factory TransResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('trans_result')) {
      return TransResult(
        from: json['from'],
        to: json['to'],
        translations: List<Translation>.from(
            json['trans_result'].map((t) => Translation.fromJson(t))),
        error_msg: "",
      );
    } else {
      return TransResult(
        from: "",
        to: "",
        translations: [],
        error_msg: "出错了！" + json['error_msg'],
      );
    }
  }
}

class Translation {
  String src;
  String dst;

  Translation({required this.src, required this.dst});

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      src: json['src'],
      dst: json['dst'],
    );
  }
}

class ConfigReader {
  Future<Map<String, dynamic>> loadConfig() async {
    final String configString = await rootBundle.loadString('assets/conf.json');
    final Map<String, dynamic> config = json.decode(configString);
    return config;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  String _inputText = "";
  final TextEditingController _textEditingController = TextEditingController();
  String _apiId = "";
  String _apiKey = "";
  final ConfigReader _configReader = ConfigReader();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    var config = await _configReader.loadConfig();
    _apiId = config['baiduAppid'];
    _apiKey = config['baiduKey'];
    //setState(() {}); // 触发widget重新构建
  }

  void _onBtnHit() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _inputText = _textEditingController.text;
      futureTransResult = translate(_inputText);
    });
  }

  bool containsChinese(String input) {
    // 使用正则表达式匹配中文字符
    RegExp chineseRegExp = RegExp(r'[\u4e00-\u9fa5]');
    return chineseRegExp.hasMatch(input);
  }

  Future<TransResult> translate(String inputText) async {
    final String salt = DateTime.now().millisecondsSinceEpoch.toString();
    const String baseUrl =
        'https://fanyi-api.baidu.com/api/trans/vip/translate';
    String q = inputText.trim();
    if (q.isEmpty) {
      q = '这还用翻译，都说了...惊喜嘛。';
    }
    bool zhToEn = containsChinese(q);
    const String from = 'auto';
    final String to = zhToEn ? 'en' : 'zh';
    final String sign = getSign(salt, q);
    final Uri uri = Uri.parse(
        '$baseUrl?q=$q&from=$from&to=$to&appid=$_apiId&salt=$salt&sign=$sign');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      print("Translation: ${response.body}");
      return TransResult.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      print("Request failed with status: ${response.statusCode}");
      throw Exception('Failed to translate');
    }
  }

  //生成签名
  String getSign(String saltTime, String input) {
    var salt = saltTime;
    var query = input;
    var str1 = _apiId + query + salt + _apiKey;
    var content = const Utf8Encoder().convert(str1);
    var sign = md5.convert(content).toString();
    return sign;
  }

  late Future<TransResult> futureTransResult = Future.value(
      TransResult(from: "", to: "", translations: [], error_msg: ""));

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _textEditingController,
                      decoration: const InputDecoration(
                        hintText: '什么叫他喵的惊喜？',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 60),
                      autofocus: true,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: FutureBuilder<TransResult>(
                future: futureTransResult,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data!.translations.isEmpty) {
                      return Text(snapshot.data!.error_msg);
                    } else {
                      return Text(
                        snapshot.data!.translations[0].dst,
                        style: const TextStyle(fontSize: 40),
                      );
                    }
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  // By default, show a loading spinner.
                  return const CircularProgressIndicator();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onBtnHit,
        tooltip: '翻译',
        child: const Icon(Icons.edit_sharp),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
