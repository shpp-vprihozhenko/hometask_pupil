import 'package:flutter/material.dart';
import 'Pupil.dart';
import 'School.dart';
import 'Service.dart' as Service;

class IdentifyPupil extends StatefulWidget {
  final programLanguage;
  IdentifyPupil(this.programLanguage);

  @override
  _IdentifyPupilState createState() => _IdentifyPupilState();
}

class _IdentifyPupilState extends State<IdentifyPupil> {
  List <String> cities = [];
  String _selectedCity, _selectedSchool = '...';
  TextEditingController _pwdController = TextEditingController();
  TextEditingController _fioController = TextEditingController();
  int classLevel = 4;
  int classLetterNumber = 0;
  List<String> classLetters = ['А','Б','В','Г','Д','Е','Ж','З','И','К'];
  int schoolNumber = 1;
  List <DropdownMenuItem<String>> schoolsDDI = [DropdownMenuItem(
    value: '...',
    child: new Text('...', style: TextStyle(color: Colors.blue), textScaleFactor: 1.1,),
  )];
  bool _showSchoolNumber = true;

  @override
  void initState() {
    if (widget.programLanguage == 1){
      classLetters = ['А','Б','В','Г','Д','Е','Є','Ж','З','И','І','Ї','К'];
    }
    cities.add('Черноморск');
    cities.add('Харьков');
    cities.add('Донецк');
    _selectedCity = null;
    Service.getCitiesList()
    .then((val){
      if (val == null) return;
      cities.clear();
      val.forEach((element) { cities.add(element); });
      setState((){});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Service.msgs['Идентификация'][widget.programLanguage]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${Service.msgs['Твой город'][widget.programLanguage]}: ', textScaleFactor: 1.2,),
                  DropdownButton<String>(
                    hint: Text(Service.msgs['Город'][widget.programLanguage]),
                    value: _selectedCity,
                    items: _citiesDDI(),
                    onChanged: (String val) {
                      setState(() {
                        _selectedCity = val;
                      });
                      _fillCitySchools();
                    },
                  ),
                ],
              ),
              Container(
                color: Colors.grey[200],
                child: Column(
                  children: [
                    _showSchoolNumber? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Твоя школа № ',textScaleFactor: 1.3,),
                        Column(children: [
                          IconButton(icon: Icon(Icons.keyboard_arrow_up), onPressed: (){
                            if (schoolNumber<100)
                              schoolNumber++;
                            setState(() {});
                          }),
                          Text(schoolNumber.toString(), textScaleFactor: 2, style: TextStyle(color: Colors.blue),),
                          IconButton(icon: Icon(Icons.keyboard_arrow_down), onPressed: (){
                            if (schoolNumber>1)
                              schoolNumber--;
                            setState(() {});
                          }),
                        ],),
                      ],
                    ) : SizedBox(),
                    Text(Service.msgs['Или выберите школу из списка:'][widget.programLanguage], textScaleFactor: 1.4,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<String>(
                          hint: Text("Школа"),
                          value: _selectedSchool,
                          items: schoolsDDI,
                          onChanged: (String val) {
                            _showSchoolNumber = (val == '...');
                            setState(() {
                              _selectedSchool = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('${Service.msgs['Твой класс'][widget.programLanguage]}:',textScaleFactor: 1.5,),
                  Column(children: [
                    IconButton(icon: Icon(Icons.keyboard_arrow_up), onPressed: (){
                      if (classLevel<11)
                        classLevel++;
                      setState(() {});
                    }),
                    Text(classLevel.toString(), textScaleFactor: 2, style: TextStyle(color: Colors.blue),),
                    IconButton(icon: Icon(Icons.keyboard_arrow_down), onPressed: (){
                      if (classLevel>1)
                        classLevel--;
                      setState(() {});
                    }),
                  ],),
                  Column(children: [
                    IconButton(icon: Icon(Icons.keyboard_arrow_up), onPressed: (){
                      if (classLetterNumber<classLetters.length)
                        classLetterNumber++;
                      setState(() {});
                    }),
                    Text(classLetters[classLetterNumber], textScaleFactor: 2, style: TextStyle(color: Colors.blue)),
                    IconButton(icon: Icon(Icons.keyboard_arrow_down), onPressed: (){
                      if (classLetterNumber>0)
                        classLetterNumber--;
                      setState(() {});
                    }),
                  ],)
              ],),
              Container(
                color: Colors.grey[200],
                child: Column(
                  children: [
                    TextField(
                      maxLines: 2,
                      //style: TextStyle(fontSize: 16), Прихоженко Ирина
                      decoration: InputDecoration(labelText: Service.msgs['Фамилия и имя'][widget.programLanguage]),
                      controller: _fioController,
                      maxLength: 100,
                    ),
                    TextField(
                      //style: TextStyle(fontSize: 15),
                      decoration: InputDecoration(labelText: '${Service.msgs['Твой'][widget.programLanguage]} пароль'),
                      controller: _pwdController,
                      maxLength: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  _fillCitySchools() async {
    print('_fillCitySchools with $_selectedCity');
    if (_selectedCity == '') return;
    List <School> _schools = await Service.getSchools(_selectedCity);
    schoolsDDI.clear();
    schoolsDDI.add(
        DropdownMenuItem(
          value: '...',
          child: new Text('...', style: TextStyle(color: Colors.blue), textScaleFactor: 1.1,),
        )
    );
    _schools.forEach((element) {
      schoolsDDI.add(
          DropdownMenuItem(
            value: element.name,
            child: new Text(element.name, style: TextStyle(color: Colors.blue), textScaleFactor: 1.1,),
          )
      );
    });
    setState(() {});
  }

  _citiesDDI() {
    List <DropdownMenuItem<String>> res = [];
    cities.forEach((el) {
      res.add(DropdownMenuItem(
        value: el,
        child: Text(el, style: TextStyle(color: Colors.blue), textScaleFactor: 1.1,),
      ));
    });
    return res;
  }

  _done() async {
    String classRoom = '$classLevel${classLetters[classLetterNumber]}';
    String fio = _fioController.text.trim();
    String pwd = _pwdController.text.trim();
    if (fio == '') {
      Service.showAlertPage(context, Service.msgs['Укажи фамилию и имя'][widget.programLanguage]);
      return;
    }
    if (pwd == '') {
      Service.showAlertPage(context, '${Service.msgs['Укажи'][widget.programLanguage]} пароль');
      return;
    }
    String _school = (_selectedSchool == null || _selectedSchool == '...') ? schoolNumber.toString() : _selectedSchool;

    print('identify with г. $_selectedCity школа № $_school класс $classRoom фио $fio пароль $pwd');
    Pupil pupil = Pupil('', _selectedCity, _school, classRoom, fio, pwd);
    String _id = await Service.identifyPupil(pupil, context);
    if (_id != '') {
      pupil.id = _id;
      print ('ok pupil with $pupil');
      Navigator.pop(context, pupil);
    }
  }

}
