import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'HomeTask.dart';
import 'IdentifyPupil.dart';
import 'Pupil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Service.dart' as Service;
import 'SolveTask.dart';
import 'package:devicelocale/devicelocale.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Домашнее задание. Ученик',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Домашнее задание. Ученик'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Pupil pupil = Pupil('','','','','','');
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  List <HomeTask> homeTasks = [];
  bool arcMode = false;
  int programLanguage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => checkIdentification(context));
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    List languages;
    String currentLocale;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      languages = await Devicelocale.preferredLanguages;
      print(languages);
    } on PlatformException {
      print("Error obtaining preferred languages");
    }
    try {
      currentLocale = await Devicelocale.currentLocale;
      print(currentLocale);
    } on PlatformException {
      print("Error obtaining current locale");
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    print('got phone languages $languages');
    print('got currentLocale $currentLocale');
    if (currentLocale == 'uk_UA') {
      print('change program language to UA');
      programLanguage = 1;
      setState(() {});
    }
  }

  checkIdentification(ctx) async {
    print('check id');
    await initPlatformState();
    SharedPreferences prefs = await _prefs;
    int _lang = prefs.getInt('lang');
    print('got lang from prefs $_lang');
    if (_lang != null) {
      programLanguage = _lang;
    }
    String _id = prefs.getString('id') ?? '';
    if (_id == null || _id == '') {
      print('no id - identify pupil');
      while (pupil.id == '') {//Прихоженко Ирина 123
        var res = await Navigator.push(ctx, MaterialPageRoute(builder: (context) => IdentifyPupil(programLanguage)));
        if (res != null) {
          pupil = res;
        }
      }
      print('got pupil $pupil');
      savePupilData(prefs);
    } else {
      getPupilData(prefs);
    }
    print('got id ${pupil.id}');
    setState((){});
    await getTasksFromServer();
  }

  getTasksFromServer() async {
    print('update homeTasks list ${homeTasks.length}');
    await Service.getHomeTasks(homeTasks, pupil, arcMode, context);
    setState((){});
    print('updated homeTasks list ${homeTasks.length}');
    if (homeTasks.length > 0) {
      markSolvedTasks();
    }
  }

  markSolvedTasks() async {
    print('markSolvedTasks');
    List <String> tasksIdToCheck = [];
    homeTasks.forEach((element) { tasksIdToCheck.add(element.id); });
    String tasksStatus = await Service.getTasksStatus(tasksIdToCheck, pupil);
    if (tasksStatus.length < 20 || tasksStatus.substring(0,11) != '{"err":null') {
      Service.showAlertPage(context, Service.msgs['Ошибка при получении статусов ДЗ'][programLanguage]);
    } else {
      try {
        var statesList = jsonDecode(tasksStatus)["arTaskStatus"];
        print('got statesList ${statesList.length}');
        homeTasks.forEach((task) {
          String taskStatus = '';
          statesList.forEach((taskState){
            if (taskState["taskId"] == task.id) {
              taskStatus = taskState["status"].toString();
            }
          });
          task.status = taskStatus;
          print('task $task');
        });
        setState(() {});
      } catch(e) {
        print('err on parse server answer $e');
      }
    }
  }

  getPupilData(prefs){
    pupil.id = prefs.getString('id');
    pupil.city = prefs.getString('city');
    pupil.school = prefs.getString('school');
    pupil.classRoom = prefs.getString('classRoom');
    pupil.fio = prefs.getString('fio');
    print('pupil data restored from SharedPreferences $pupil');
  }

  savePupilData(prefs){
    prefs.setString("id", pupil.id);
    prefs.setString("city", pupil.city);
    prefs.setString("school", pupil.school);
    prefs.setString("classRoom", pupil.classRoom);
    prefs.setString("fio", pupil.fio);
    print('pupil data saved into SharedPreferences $pupil');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.refresh), onPressed: getTasksFromServer,),
        title: Text(arcMode? Service.msgs['Архив'][programLanguage] : Service.msgs['Активные ДЗ'][programLanguage]),
      ),
      body: pupil.id==''? Center(child: Text('Здесь будет список ДЗ для ученика $pupil', textAlign: TextAlign.center,))
            : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(pupil.fio, textScaleFactor: 1.5,),
                ),
                Expanded(
                  child: ListView.builder(
                      itemCount: homeTasks.length,
                      itemBuilder: (BuildContext context, int index) {
                        return InkWell(
                            onTap: (){_openTask(index);},
                            child: ListTile(
                              tileColor: index%2 == 1? Colors.white : Colors.grey[200],
                              title: Text(homeTasks[index].lesson+': '+homeTasks[index].fullDescription),
                              subtitle: Text('${Service.msgs['Выдано'][programLanguage]}: '+Service.dateRus(homeTasks[index].dtStart, programLanguage)),
                              trailing: (homeTasks[index].status == null || homeTasks[index].status == '')?
                                SizedBox(width: 16,)
                                : (homeTasks[index].status == '-') ?
                                  Icon(Icons.done, size: 26, color: Colors.blueAccent,)
                                  : Text(homeTasks[index].status, textScaleFactor: 1.6, style: TextStyle(color: Colors.green),)
                            )
                        );
                      }
                    ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        //color: Colors.brown[300],
          height: 60,
          child: ButtonBar(
            alignment: MainAxisAlignment.center,
            //mainAxisSize: MainAxisSize.min,
            //buttonPadding: EdgeInsets.all(3),
            children: [
              FloatingActionButton(onPressed: _showAbout, tooltip: 'О программе', child: Text('?', textScaleFactor: 2,), heroTag: "btnAbout",),
              FloatingActionButton(onPressed: _switchArcMode,
                  tooltip: 'Архив/Активные ДЗ',
                  child: Icon(arcMode? Icons.business_center : Icons.account_balance, size: 33,),
                  heroTag: "btnSwitchArcTasks"
              ),
              FloatingActionButton(onPressed: _settings, tooltip: 'Настройки', child: Icon(Icons.settings), heroTag: "btnSettings",),
            ],
          )
      ),
    );
  }

  _switchArcMode(){
    setState(() {
      arcMode = !arcMode;
      homeTasks.clear();
    });
    getTasksFromServer();
  }

  _showAbout(){
    Service.showAlertPage(context, Service.msgs['Разработчик: \nПрихоженко Владимир, \nvprihogenko@gmail.com'][programLanguage]);
  }

  _settings(){
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Container(
            height: 120,
            child: Center(
              child: Column(
                children: [
                  Text(programLanguage == 0? 'Язык программы: Русский':'Мова програми: Українська', textAlign: TextAlign.center,),
                  SizedBox(height: 10),
                  FlatButton(
                    color: programLanguage == 0? Colors.yellow : Colors.lightBlueAccent,
                    child: programLanguage == 0? Text('Змінити на Українську'):Text('Поменять на Русский'),
                    onPressed: (){
                      Navigator.pop(context, programLanguage == 0? 1:0);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }
    ).then((value){
      if (value == null) return;
      print('new lang value $value');
      programLanguage = value;
      setState(() {});
      saveLangPrefs();
    });
  }

  saveLangPrefs() async {
    SharedPreferences prefs = await _prefs;
    prefs.setInt("lang", programLanguage);
  }

  _openTask(index){
    print('o $index');
    Navigator.push(context, MaterialPageRoute(builder: (context) => SolveTask(homeTasks[index], pupil, programLanguage)))
    .then((value){
      setState(() {});
    });
  }
}
