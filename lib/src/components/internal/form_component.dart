import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:ng2_state/ng2_state.dart';

import 'package:ng2_form_components/src/components/list_item.g.dart';

typedef String LabelHandler<T>(T data);

typedef List<ListItem<Comparable<dynamic>>> ResolveChildrenHandler(
    int level, ListItem<Comparable<dynamic>> listItem);
typedef ComponentFactory ResolveRendererHandler(int level,
    [ListItem<Comparable<dynamic>> listItem]);

abstract class FormComponent extends ComponentState
    implements StatefulComponent, OnDestroy {
  final Element elementRef;
  final StreamController<bool> _onDestroy$ctrl =
      StreamController<bool>.broadcast();

  @override
  Stream<bool> get onDestroy => _onDestroy$ctrl.stream;

  @override
  String stateGroup, stateId;

  //-----------------------------
  // constructor
  //-----------------------------

  FormComponent(this.elementRef) {
    stateChangeCallback = () {};
  }

  //-----------------------------
  // static internal properties
  //-----------------------------

  static final List<FormComponent> openFormComponents = <FormComponent>[];

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override
  void ngOnDestroy() {
    _onDestroy$ctrl.add(true);

    _onDestroy$ctrl.close();
  }
}
