library ng2_form_components.components.form_component;

import 'dart:async';

import 'package:angular/angular.dart';

import 'package:ng2_state/ng2_state.dart';

import 'package:ng2_form_components/src/components/list_item.g.dart';

typedef dynamic LabelHandler(dynamic data);

typedef List<ListItem<Comparable<dynamic>>> ResolveChildrenHandler(int level, ListItem<Comparable<dynamic>> listItem);
typedef Type ResolveRendererHandler(int level, [ListItem<Comparable<dynamic>> listItem]);

abstract class FormComponent<T extends Comparable<dynamic>> extends ComponentState implements StatefulComponent, OnDestroy {

  final ElementRef elementRef;
  final StreamController<bool> _onDestroy$ctrl = new StreamController<bool>.broadcast();

  @override Stream<bool> get onDestroy => _onDestroy$ctrl.stream;

  @override String stateGroup, stateId;

  //-----------------------------
  // constructor
  //-----------------------------

  FormComponent(this.elementRef) {
    stateChangeCallback = () {};
  }

  //-----------------------------
  // static internal properties
  //-----------------------------

  static final List<FormComponent<Comparable<dynamic>>> openFormComponents = <FormComponent<Comparable<dynamic>>>[];

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override void ngOnDestroy() {
    _onDestroy$ctrl.add(true);

    _onDestroy$ctrl.close();
  }

}