import 'dart:io' show Directory, File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ssh2/ssh2.dart' show SSHClient;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatefulWidget(),
    );
  }
}

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {

  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final TextEditingController _controller3 = TextEditingController();
  final TextEditingController _controller4 = TextEditingController();
  late String ip;
  late String port;
  late String login;
  late String pass;

  _write(String text) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/settings.txt');
    await file.writeAsString(text);
  }

  void setSettings() {
    if (_controller1.text.isNotEmpty && _controller2.text.isNotEmpty && _controller3.text.isNotEmpty && _controller4.text.isNotEmpty) {
      var ip = _controller1.text;
      var port = _controller4.text;
      var login = _controller2.text;
      var pass = _controller3.text;
      var text = "$ip\n$port\n$login\n$pass";
      _write(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: <Widget>[
          Column(
            children: <Widget>[
              Material(
                child: TextField(
                  controller: _controller1,
                  decoration: InputDecoration(
                    hintText: 'IP',
                    suffixIcon: IconButton(
                      onPressed: _controller1.clear,
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
              ),
              Material(
                child: TextField(
                  controller: _controller4,
                  decoration: InputDecoration(
                    hintText: 'port',
                    suffixIcon: IconButton(
                      onPressed: _controller4.clear,
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
              ),
              Material(
                child: TextField(
                  controller: _controller2,
                  decoration: InputDecoration(
                    hintText: 'login',
                    suffixIcon: IconButton(
                      onPressed: _controller2.clear,
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
              ),
              Material(
                child: TextField(
                  controller: _controller3,
                  decoration: InputDecoration(
                    hintText: 'password',
                    suffixIcon: IconButton(
                      onPressed: _controller3.clear,
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                setSettings();
              });
            },
            child: const Text("OK"),
          ),
        ],
      )
    );
  }
}

class WorkWidget extends StatefulWidget {
  const WorkWidget({super.key});

  @override
  State<WorkWidget> createState() => _WorkWidgetState();
}

class _WorkWidgetState extends State<WorkWidget> {

  late String ip;
  late String port;
  late String login;
  late String pass;
  late SSHClient client;
  final TextEditingController _controller = TextEditingController();
  late String cmd;

  @override
  void initState() {
    super.initState();
    _read();
    cmd = "ls";
  }

  void _read() async {
    String text = "";
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/settings.txt');
      text = await file.readAsString();
    } catch (e) {
      print("Couldn't read file");
    }
    var text_ = text.split("\n");
    ip = text_[0];
    port = text_[1];
    login =text_[2];
    pass = text_[3];
    client = SSHClient(
      host: ip,
      port: int.parse(port),
      username: login,
      passwordOrKey: pass,
    );
  }

  late Future<String> _result;
  bool showWidget = false;

  void sendToSSH() {
    _result = sendCmd();
    showWidget = true;
  }

  Future<String> sendCmd() async {
    String result = "";
    cmd = _controller.text;
    try {
      result = await client.connect() ?? 'Null result';
      if (result == "session_connected") result = await client.execute(cmd) ?? 'Null result';
      await client.disconnect();
    } on PlatformException catch (e) {
      String errorMessage = 'Error: ${e.code}\nError Message: ${e.message}';
      result = errorMessage;
      print(errorMessage);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Work'),
        ),
        body: Column(
          children: <Widget>[
            Column(
              children: <Widget>[
                Material(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'input command',
                      suffixIcon: IconButton(
                        onPressed: _controller.clear,
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  sendToSSH();
                });
              },
              child: const Text("OK"),
            ),
            showWidget
            ? FutureBuilder<String>(
              future: _result,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(snapshot.data!.toString())
                        ],
                      )
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                // By default, show a loading spinner.
                return const CircularProgressIndicator();
              },
            ) : Container(),
          ],
        )
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH client'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'SSH client',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sunny),
              title: const Text('SSH work'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const WorkWidget()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const SettingsWidget()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
