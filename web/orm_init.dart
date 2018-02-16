library orm_init;

import 'package:ng2_state/ng2_state.dart';
import 'package:dorm/dorm.dart';

import 'package:ng2_form_components/ng2_form_components.dart';

import 'person.g.dart' as domain;

void ormInitialize() {
  Entity.ASSEMBLER.usePointers = false;

  try {
    ListItem.DO_SCAN();
    domain.Person.DO_SCAN();
    HierarchyLevel.DO_SCAN();
    StateContainer.DO_SCAN();
    SerializableTuple1.DO_SCAN<Null>();
    SerializableTuple2.DO_SCAN<Null, Null>();
    SerializableTuple3.DO_SCAN<Null, Null, Null>();
    SerializableTuple4.DO_SCAN<Null, Null, Null, Null>();
  } catch (error) {
    print('orm failed...');
  }
}