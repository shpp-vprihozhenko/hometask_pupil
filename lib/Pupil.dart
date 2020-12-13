class Pupil {
  String id;
  String city;
  String school;
  String classRoom;
  String fio;
  String password;

  Pupil(this.id, this.city, this.school, this.classRoom, this.fio, this.password);

  @override
  String toString() {
    String res = id + ' ' + city + ' ' + school + ' ' + classRoom + ' ' + fio + ' / ' + password;
    return res;
  }
}
