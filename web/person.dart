library domain.person;

import 'package:dorm/dorm.dart';

@Ref('domain.person')
class Person extends Entity implements Comparable {

  String get refClassName => 'domain.person';

  @Property(NAME_SYMBOL, 'name', String, 'name')
  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = const Symbol('domain.person.name');

  String name;

  @Property(IMAGE_SYMBOL, 'image', String, 'image')
  static const String IMAGE = 'image';
  static const Symbol IMAGE_SYMBOL = const Symbol('domain.person.image');

  String image;

  Person() : super();

  static Person construct() => new Person();

  int compareTo(Person other) {
    if (other != null) return (other.name.compareTo(name) == 0 && other.image.compareTo(image) == 0) ? 0 : 1;

    return -1;
  }

}