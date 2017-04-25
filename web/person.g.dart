// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: CodeGenerator
// Target: abstract class Person
// **************************************************************************

import 'package:dorm/dorm.dart';

import 'person.dart' as sup;

class Person extends Entity with sup.Person implements Comparable<dynamic> {
  /// refClassName
  @override
  String get refClassName => 'i102ng2_form_components_web_person';

  /// Public properties
  /// image
  static const String IMAGE = 'image';
  static const Symbol IMAGE_SYMBOL = #i102ng2_form_components_web_person_image;

  final DormProxy<String> _image = new DormProxy<String>(IMAGE, IMAGE_SYMBOL);
  @override
  String get image => _image.value;
  set image(String value) {
    _image.value = value;
  }

  /// name
  static const String NAME = 'name';
  static const Symbol NAME_SYMBOL = #i102ng2_form_components_web_person_name;

  final DormProxy<String> _name = new DormProxy<String>(NAME, NAME_SYMBOL);
  @override
  String get name => _name.value;
  set name(String value) {
    _name.value = value;
  }

  /// DO_SCAN
  static void DO_SCAN([String _R, Entity _C()]) {
    _R ??= 'i102ng2_form_components_web_person';
    _C ??= () => new Person();
    Entity.DO_SCAN(_R, _C);
    Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[
      const PropertyData(
          symbol: Person.IMAGE_SYMBOL,
          name: 'image',
          type: String,
          metatags: const <dynamic>[]),
      const PropertyData(
          symbol: Person.NAME_SYMBOL,
          name: 'name',
          type: String,
          metatags: const <dynamic>[]),
    ]);
  }

  /// Constructor
  Person() {
    Entity.ASSEMBLER.registerProxies(this, <DormProxy<dynamic>>[_image, _name]);
  }

  /// Internal constructor
  static Person construct() => new Person();

  /// withImage
  Person withImage(String value) =>
      duplicate(ignoredSymbols: const <Symbol>[Person.IMAGE_SYMBOL])
        ..image = value;

  /// withName
  Person withName(String value) =>
      duplicate(ignoredSymbols: const <Symbol>[Person.NAME_SYMBOL])
        ..name = value;

  /// Duplicates the [Person] and any recusrive entities to a new [Person]
  @override
  Person duplicate({List<Symbol> ignoredSymbols: null}) =>
      super.duplicate(ignoredSymbols: ignoredSymbols);

  /// toString implementation for debugging purposes
  @override
  String toString() {
    return 'i102ng2_form_components_web_person';
  }
}
