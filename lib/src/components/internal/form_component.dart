library ng2_form_components.components.form_component;

import 'dart:async';

import 'package:angular2/angular2.dart';

import 'package:ng2_state/ng2_state.dart';

import 'package:ng2_form_components/src/components/list_item.dart';

typedef String LabelHandler(dynamic data);

typedef List<ListItem<Comparable>> ResolveChildrenHandler(int level, ListItem<Comparable> listItem);
typedef Type ResolveRendererHandler(int level, [ListItem<Comparable> listItem]);

abstract class FormComponent<T extends Comparable> implements StatefulComponent, OnDestroy {

  @override final ChangeDetectorRef changeDetector;
  final StreamController<bool> _onDestroy$ctrl = new StreamController<bool>.broadcast();

  @override Stream<bool> get onDestroy => _onDestroy$ctrl.stream;

  @override String stateGroup, stateId;

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

  @override void ngOnDestroy() => _onDestroy$ctrl.add(true);

}