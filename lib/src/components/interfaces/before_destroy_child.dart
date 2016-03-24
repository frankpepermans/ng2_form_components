library ng2_form_components.interfaces.before_destroy_child;

import 'dart:async';

abstract class BeforeDestroyChild {

  StreamController<dynamic> get beforeDestroyChild;

  Stream<dynamic> ngBeforeDestroyChild([List args]);
}