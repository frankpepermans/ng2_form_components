library domain.person;

import 'package:dorm/dorm.dart';

@dorm
abstract class Person implements Entity, Comparable<dynamic> {

  String get name;
  String get image;

  @override int compareTo(dynamic other) {
    if (other is Person) return (other.name.compareTo(name) == 0 && other.image.compareTo(image) == 0) ? 0 : 1;

    return -1;
  }

}