library orm_init;

import 'package:angular2/angular2.dart';
import 'package:ng2_state/ng2_state.dart';
import 'package:dorm/dorm.dart';

import 'package:ng2_form_components/ng2_form_components.dart';

import 'person.dart' as domain;

void ormInitialize() {
  Entity.ASSEMBLER.usePointers = false;

  try {
    ListItem.DO_SCAN();
    domain.Person.DO_SCAN();
    HierarchyLevel.DO_SCAN();
    StateContainer.DO_SCAN();
    SerializableTuple1.DO_SCAN();
    SerializableTuple2.DO_SCAN();
    SerializableTuple3.DO_SCAN();
    SerializableTuple4.DO_SCAN();
  } catch (error) {
    print('orm failed...');
  }
}