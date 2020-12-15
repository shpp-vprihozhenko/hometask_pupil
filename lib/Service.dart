import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'HomeTask.dart';
import 'Pupil.dart';
import 'PupilSolution.dart';
import 'School.dart';

final String nodeEndPoint = 'http://62.109.10.134:6613';
//final String nodeEndPoint = 'http://192.168.1.15:6613';
//final String nodeEndPoint = 'http://144.76.198.99:6613';

Future<List<String>> getCitiesList() async {
  print('send req to '+nodeEndPoint+'/getCities');
  var value = await http.post(nodeEndPoint+'/getCities',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
  );
  if (value.body == null) {
    print('some err at get pupils cb( No body');
    return [];
  }
  var res;
  try {
    res = jsonDecode(value.body);
    if (res["err"] != null) {
      print('some err on server side on pupils get');
      return [];
    }
  } catch (e) {
    print('some err on parse server\'s response on pupils get');
    return [];
  }
  print('got decoded ar ${res["ar"]}');
  List <String> cities = [];
  res["ar"].forEach((el) {
    print('add $el');
    cities.add(el["city"]);
  });
  cities.sort((el1, el2)=>el1.compareTo(el2));
  return cities;
}

Future <String> identifyPupil(Pupil pupil, context) async {
  print('send req to '+nodeEndPoint+'/check_pupil');
  var value = await http.post(
    nodeEndPoint+'/check_pupil',
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
        <String, dynamic> {
      "city": pupil.city,
      "school": pupil.school,
      "classRoom": pupil.classRoom,
      "fio": pupil.fio,
      "password": pupil.password
    })
  );

  if (value.body == null) {
    print('some err at get pupils cb( No body');
    showAlertPage(context, 'Нет ответа от сервера.');
    return '';
  }

  if (value.body.substring(0,2)=='OK') {
    print('check ok');
    return value.body.split(' ')[1];
  }

  showAlertPage(context, 'Получен неправильный ответ от сервера.');
  return '';
}

showAlertPage(context, String msg) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
        );
      }
  );
}

Future<dynamic> askYesNo(context, String msg) {
  final c = new Completer();
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
          actions: [
            FlatButton(
              child: Text('Да'),
              onPressed: (){
                c.complete(true);
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text('Нет'),
              onPressed: (){
                c.complete(false);
                Navigator.pop(context);
              },
            ),
          ],
        );
      }
  );
  return c.future;
}

Future <dynamic> getHomeTasks(homeTasks, pupil, arcMode, context) async {
  print('send req to '+nodeEndPoint+'/getPupilTasks');
  var value = await http.post(
      nodeEndPoint+'/getPupilTasks',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
          <String, dynamic> {
            "city": pupil.city,
            "school": pupil.school,
            "classRoom": pupil.classRoom,
            "arcMode": arcMode? 'true':'false'
          })
  );
  if (value.body == null) {
    print('some err at get pupils cb( No body');
    showAlertPage(context, 'Нет ответа от сервера.');
    return '';
  }
  var jBody;
  try {
    jBody = jsonDecode(value.body);
  } catch(e) {
    showAlertPage(context, 'Ошибка связи с сервером. Попробуйте зайти позже.');
    return '';
  }
  print('got jBody $jBody');

  if (jBody["ar"] != null) {
    homeTasks.clear();
    jBody["ar"].forEach((el){
      homeTasks.add(HomeTask(el["_id"], el["taskDescription"], [], DateTime.parse(el["dtStart"]), DateTime.parse(el["dtDeadline"]),
                            el["lesson"], el["city"], el["school"], el["teacher"], el["classRoom"]));
      try {
        el["taskFileName"].forEach((pic){
          homeTasks[homeTasks.length-1].linksToPhotos.add(pic);
        });
      } catch(e) {}
    });
    print ('got homeTasks $homeTasks');
    return 'OK';
  }
  showAlertPage(context, 'Получен неправильный ответ от сервера.');
  return '';
}

Future <Widget> loadImageFromServer(String fileName, String mode) async {
  var value;
  print('send req to '+nodeEndPoint+'/loadImage');
  value = await http.post(nodeEndPoint+'/loadImage',
    body: {
      "fileName": fileName,
      "mode": mode,
    },
  );
  var imageWidget;
  try {
    imageWidget = Image.memory(base64Decode(value.body));
  } catch(e) {
    print('got err on loadImage $e');
  }
  return imageWidget;
}

String dateRus(DateTime dt, [programLanguage = 0]) {
  List <String> _monthes = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
  if (programLanguage == 1) {
    _monthes = ['січня', 'лютого', 'березня', 'квітня', 'травня', 'червня', 'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня'];
  }
  return '${dt.day} ${_monthes[dt.month-1]} ${dt.year}';
}

Future<PupilSolution> getPupilSolvedTaskData(task, pupil, context) async {
  print('send req to '+nodeEndPoint+'/getPupilSolvedTaskData');
  var value = await http.post(nodeEndPoint+'/getPupilSolvedTaskData',
    body: {
      "taskId": task.id,
      "pupilId": pupil.id,
    },
  );

  PupilSolution sol;
  String respStr = value.body;

  print('got respStr $respStr');

  if (respStr == '{}') {
    print('no solution just now');
    sol = PupilSolution('', task.id, pupil.id, [], null, null);
    return sol;
  }

  if (respStr.substring(0,8) == '{"data":') {
    try {
      var jData = jsonDecode(respStr);
      var data = jData["data"];
      sol = PupilSolution(data["_id"], data["taskId"], data["pupilId"], [], '', data["mark"].toString());
      data["files"].forEach((fileName){
        sol.files.add(fileName);
      });

      print('\n\ndata is solved ${data["isSolved"]}');

      if (data["isSolved"] != null) {
        if (data["isSolved"]) {
          sol.status = '-';
        }
      }
    } catch(e) {
      print('no correct data, got parse err $e');
      showAlertPage(context, 'Что-то пошло не так. Не смог прочитать данные по этой задаче. Попробуй позже.');
    }
  } else {
    print('no correct data');
    showAlertPage(context, 'Что-то пошло не так. Не смог прочитать данные по этой задаче. Попробуй позже.');
  }
  return sol;
}

Future<dynamic> uploadPupilImage(task, pupil, file) {
  final c = new Completer();
  print('send req to '+nodeEndPoint+'/uploadPupilImage');
  String base64Image = base64Encode(file.readAsBytesSync());
  String fileName = '${task.id}_${pupil.id}_${file.path.split("/").last}';
  print('fn '+fileName);

  http.post(nodeEndPoint+'/uploadPupilImage',
    body: {
      "taskId": task.id,
      "pupilId": pupil.id,
      "image": base64Image,
      "name": fileName,
    },
  ).then((value) {
    c.complete(value.body);
  });

  return c.future;
}

Future<String> markPupilTaskAsSolved(task, pupil, context) async {
  print('send req to '+nodeEndPoint+'/markPupilTaskAsSolved with ${task.id} ${pupil.id}');
  var value = await http.post(nodeEndPoint+'/markPupilTaskAsSolved',
    body: {
      "taskId": task.id,
      "pupilId": pupil.id,
    },
  );

  String respStr = value.body;
  print('got respStr $respStr');

  if (respStr.substring(0,2) == 'OK') {
    print('ok, status changed');
    return 'OK';
  } else {
    print('no correct data');
    showAlertPage(context, 'Что-то пошло не так. Не смог изменить статус этой задаче. Попробуй позже.');
    return respStr;
  }
}

Future<String> getTasksStatus(List <String> tasksIdToCheck, Pupil pupil) async {
  var value = await http.post(nodeEndPoint+'/getTasksStatus',
    body: {
      "tasksId": jsonEncode(tasksIdToCheck),
      "pupilId": pupil.id,
    },
  );

  String respStr = value.body;
  print('got respStr $respStr');
  return respStr;
  //{"err":null,"arTaskStatus":[{"taskId":"5fa2b6d28f202d2bd08ef266","status":"-"}]}
}

Future<List <School>> getSchools(String cityName) async {
  print('send req to '+nodeEndPoint+'/getSchools');
  var value = await http.post(nodeEndPoint+'/getSchools',
      headers: <String, String>{ 'Content-Type': 'application/json; charset=UTF-8', },
      body: jsonEncode(
          <String, dynamic>{
            'city': cityName,
          })
  );
  if (value.body == null) {
    print('some err at get schools cb( No body');
    return [];
  }
  var res;
  try {
    res = jsonDecode(value.body);
    if (res["err"] != null) {
      print('some err on server side on schools get');
      return [];
    }
  } catch (e) {
    print('some err on parse server\'s response on schools get');
    return [];
  }
  print('got decoded ar schools ${res["ar"]}');
  List <School> schools = [];
  res["ar"].forEach((el) {
    print('add $el');
    schools.add(School(el["_id"], el["school"], cityName));
  });
  return schools;
}

Map <String, List<String>> msgs = {
  'Идентификация':  ['Идентификация','Ідентифікація'],
  'Твой город': ['Твой город','Твоє місто'],
  'Город': ['Город','Місто'],
  'Твой класс': ['Твой класс','Твій клас'],
  'Твой': ['Твой','Твій'],
  'Фамилия и имя': ['Фамилия и имя','Призвище та ім’я'],
  'Укажи фамилию и имя': ['Укажи фамилию и имя','Вкажи призвище та ім’я'],
  'Укажи': ['Укажи','Вкажи'],
  'Ошибка при получении статусов ДЗ': ['Ошибка при получении статусов ДЗ','Виникла помилка при отриманні статусів ДЗ'],
  'Архив': ['Архив','Архів'],
  'Активные ДЗ': ['Активные ДЗ','Активні ДЗ'],
  'Выдано': ['Выдано','Видано'],
  'Разработчик: \nПрихоженко Владимир, \nvprihogenko@gmail.com': ['Разработчик: \nПрихоженко Владимир, \nvprihogenko@gmail.com','Розробник: \nПрихоженко Володимир, \nvprihogenko@gmail.com'],
  'Решаем ДЗ': ['Решаем ДЗ','Вирішуєм ДЗ'],
  'Выдано: ': ['Выдано: ','Видано: '],
  'Твоё решение: ': ['Твоё решение: ','Твоє рішення: '],
  'Сфотографировать': ['Сфотографировать','Сфотографувати'],
  'Из галереи': ['Из галереи','З галереї'],
  'Ещё нет': ['Ещё нет','Ще нема'],
  'не отправлено': ['не отправлено','не відправлено'],
  'на проверке': ['на проверке','на перевірці'],
  'оценка': ['оценка','оцінка'],
  'Настройки': ['Настройки','Налаштування'],
  'Или выберите школу из списка:': ['Или выберите школу из списка:','Або виберіть школу зі списку:'],
};