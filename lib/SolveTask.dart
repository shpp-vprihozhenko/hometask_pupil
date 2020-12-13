import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_tasker_pupil/HomeTask.dart';
import 'package:school_tasker_pupil/MyPhotoView.dart';
import 'Pupil.dart';
import 'Service.dart' as Service;
import 'MyPhotoView.dart';
import 'PupilSolution.dart';

class SolveTask extends StatefulWidget {
  final HomeTask homeTask;
  final Pupil pupil;
  final int programLanguage;

  SolveTask(this.homeTask, this.pupil, this.programLanguage);

  @override
  _SolveTaskState createState() => _SolveTaskState();
}

class _SolveTaskState extends State<SolveTask> {
  List <Widget> filesList = [];
  List <Widget> pupilPhotosList = [];
  ScrollController _sc = ScrollController();
  ScrollController _sc2 = ScrollController();
  PupilSolution solution;
  bool showProgressWhileSave = false;


  @override
  void initState() {
    if (widget.homeTask.linksToPhotos != null && widget.homeTask.linksToPhotos.length > 0) {
      loadImages(widget.homeTask.linksToPhotos);
    }
    tryLoadPupilSolution();
    super.initState();
  }

  tryLoadPupilSolution() async {
    solution = await Service.getPupilSolvedTaskData(widget.homeTask, widget.pupil, context);
    if (solution == null) {
      print('not found current solution');
      return;
    }
    print('got solution $solution');
    if (solution.files.length > 0) {
      solution.files.forEach((fileName){
        print(fileName);
        _loadPupilImageFromServer(fileName);
      });
    }
  }

  _loadPupilImageFromServer(fileName) {
    Service.loadImageFromServer(fileName, 'solution')
    .then((imageWidget){
      print('_loadImageFromServer with $imageWidget');
      if (imageWidget != null) {
        print('add to fileList');
        pupilPhotosList.add(imageWidget);
        setState(() {});
      }
    });
  }

  loadImages(imgList) {
    imgList.forEach((fileName){
      print(fileName);
      _loadImageFromServer(fileName);
    });
  }

  _loadImageFromServer(fileName) {
    filesList.add(CircularProgressIndicator());
    setState(() {});
    int idx = filesList.length - 1;
    Service.loadImageFromServer(fileName, 'task')
    .then((imageWidget){
      print('_loadImageFromServer with $imageWidget');
      if (imageWidget != null) {
        print('add to fileList');
        filesList[idx] = imageWidget;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Service.msgs['Решаем ДЗ'][widget.programLanguage]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            SizedBox(height: 16),
            Text(widget.homeTask.lesson+': '+widget.homeTask.fullDescription, textScaleFactor: 1.5,),
            Text(Service.msgs['Выдано: '][widget.programLanguage]+Service.dateRus(widget.homeTask.dtStart, widget.programLanguage), textScaleFactor: 1.2,),
            Row(
              children: [
                filesList.length == 0? SizedBox()
                    : Container(
                  height: 150, width: MediaQuery.of(context).size.width*0.95,
                  child: Scrollbar(
                    isAlwaysShown: true,
                    controller: _sc,
                    child: ListView.builder(
                        controller: _sc,
                        scrollDirection: Axis.horizontal,
                        itemCount: filesList.length,
                        itemBuilder:  (BuildContext context, int index) {
                          int backIdx =  filesList.length - index - 1;
                          return GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: filesList[backIdx],
                            ),
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => MyPhotoView(filesList[backIdx])));
                            },
                          );
                        }
                    ),
                  ),
                ),

              ],
            ),
            SizedBox(height: 20,),
            Container(
              color: Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(Service.msgs['Твоё решение: '][widget.programLanguage], textScaleFactor: 1.4,),
                    Text(_curStatusStr(), textScaleFactor: 1.5, style: TextStyle(color: Colors.blue),),
                  ],
                ),
              )
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: (!(solution==null || solution.status == null || solution.status == ''))? SizedBox() :
                Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                    onPressed: (){_addImageFrom('Camera');},
                    child: Text(Service.msgs['Сфотографировать'][widget.programLanguage]),
                  ),
                  SizedBox(width: 14),
                  RaisedButton(
                    onPressed: (){_addImageFrom('Gallery');},
                    child: Text(Service.msgs['Из галереи'][widget.programLanguage]),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                pupilPhotosList.length == 0? SizedBox()
                    : Container(
                  height: 150, width: MediaQuery.of(context).size.width*0.95,
                  child: Scrollbar(
                    isAlwaysShown: true,
                    controller: _sc2,
                    child: ListView.builder(
                        controller: _sc2,
                        scrollDirection: Axis.horizontal,
                        itemCount: pupilPhotosList.length,
                        itemBuilder:  (BuildContext context, int index) {
                          int backIdx =  pupilPhotosList.length - index - 1;
                          return GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: pupilPhotosList[backIdx],
                            ),
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => MyPhotoView(pupilPhotosList[backIdx])));
                            },
                          );
                        }
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20,),

          ],
        ),
      ),
      floatingActionButton: (!(solution == null || solution.status == null  || solution.status == '') || pupilPhotosList.length == 0)? null :
        Container(
          width: 80, height: 80,
          child: FittedBox(
            child: showProgressWhileSave?
            CircularProgressIndicator()
            :
            FloatingActionButton(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              heroTag: 'btnOk',
              onPressed: _saveTaskCmd,
              tooltip: 'Отправить',
              child: Icon(Icons.done_rounded, size: 40,),//      bottomNavigationBar: Container(
            ),
          ),
        ),

    );
  }

  void _addImageFrom(source) async {
    File file;
    if (source=='Camera') {
      file = await ImagePicker.pickImage(source: ImageSource.camera, maxWidth: 1500, maxHeight: 1500);
    } else {
      file = await ImagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1500, maxHeight: 1500);
    }
    if (file == null) return;

    Service.uploadPupilImage(widget.homeTask, widget.pupil, file);

    setState(() {
      pupilPhotosList.add(Image.file(file));
    });
  }

  _curStatusStr(){
    if (solution == null) {
      return Service.msgs['Ещё нет'][widget.programLanguage];
    } if (solution.status == null || solution.status != '-') {
      return Service.msgs['не отправлено'][widget.programLanguage];
    } else {
      if (solution.mark == null || solution.mark == 'null') {
        return Service.msgs['на проверке'][widget.programLanguage];
      } else {
        return Service.msgs['оценка'][widget.programLanguage]+' ${solution.mark}';
      }
    }
  }

  _saveTaskCmd(){
    showProgressWhileSave = true;
    Service.markPupilTaskAsSolved(widget.homeTask, widget.pupil, context)
    .then((value){
      if (value == 'OK') {
        widget.homeTask.isSolved = true;
        widget.homeTask.status = '-';
        Navigator.pop(context);
      }
    });
  }

}
