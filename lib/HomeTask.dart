class HomeTask {
  String id;
  String fullDescription;
  List <String> linksToPhotos = [];
  DateTime dtStart;
  DateTime dtDeadline;
  String lesson;
  String city;
  String school;
  String teacher;
  String classRoom;
  bool isSolved = false;
  String status = '';

  HomeTask(this.id, this.fullDescription, this.linksToPhotos, this.dtStart, this.dtDeadline, this.lesson, this.city, this.school, this.teacher, this.classRoom);

  @override
  String toString() {
    return 'id $id, fullDescr, $fullDescription, arLinks $linksToPhotos, dtStart $dtStart, dtD $dtDeadline, '
        'lesson $lesson, city $city, school $school, teacher $teacher, classRoom $classRoom ';
  }
}
