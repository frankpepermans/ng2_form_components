library ng2_form_components.components.form_component;

import 'dart:async';

import 'package:angular2/angular2.dart';

import 'package:ng2_state/ng2_state.dart';

typedef String LabelHandler(dynamic data);

abstract class FormComponent<T extends Comparable> implements StatefulComponent, OnDestroy {

  final ChangeDetectorRef changeDetector;
  final StreamController<bool> _onDestroy$ctrl = new StreamController<bool>.broadcast();

  Stream<bool> get onDestroy => _onDestroy$ctrl.stream;

  String stateGroup, stateId;

  //-----------------------------
  // constructor
  //-----------------------------

  FormComponent(this.changeDetector);

  //-----------------------------
  // static internal properties
  //-----------------------------

  static final List<FormComponent> openFormComponents = <FormComponent>[];

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  void ngOnDestroy() => _onDestroy$ctrl.add(true);

}