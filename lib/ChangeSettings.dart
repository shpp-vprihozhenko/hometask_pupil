import 'package:flutter/material.dart';
import 'Service.dart' as Service;

class ChangeSettings extends StatefulWidget {
  final programLanguage;
  ChangeSettings(this.programLanguage);

  @override
  _ChangeSettingsState createState() => _ChangeSettingsState();
}

class _ChangeSettingsState extends State<ChangeSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Service.msgs['Настройки'][widget.programLanguage]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(

        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        heroTag: 'btnDone',
        onPressed: _done,
        tooltip: 'Ок',
        child: Icon(Icons.done),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  _done(){

  }
}
