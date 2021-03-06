library ng2_form_components.components.side_panel;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart';
import 'package:dorm/dorm.dart';
import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/interfaces/before_destroy_child.dart'
    show BeforeDestroyChild;

import 'package:ng2_form_components/src/components/animation/side_panel_animation.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:ng2_state/ng2_state.dart'
    show SerializableTuple1, StatePhase, StateService, StatefulComponent;

@Component(
    selector: 'side-panel',
    templateUrl: 'side_panel.html',
    directives: <dynamic>[coreDirectives, SidePanelAnimation],
    pipes: <dynamic>[commonPipes],
    providers: <dynamic>[
      StateService,
      ExistingProvider.forToken(OpaqueToken('statefulComponent'), SidePanel)
    ],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class SidePanel extends FormComponent implements OnDestroy, BeforeDestroyChild {
  //-----------------------------
  // input
  //-----------------------------

  String _orientation = 'right';
  String get orientation => _orientation;
  @Input()
  set orientation(String value) {
    if (_orientation != value) setState(() => _orientation = value);
  }

  //-----------------------------
  // output
  //-----------------------------

  @override
  StreamController<bool> get beforeDestroyChild => _beforeDestroyChild$ctrl;

  final StreamController<bool> _beforeDestroyChild$ctrl =
      StreamController<bool>.broadcast();
  final StreamController<bool> _isOpen$ctrl =
      StreamController<bool>.broadcast();
  final StreamController<bool> _toggle$ctrl =
      StreamController<bool>.broadcast();

  StreamSubscription<bool> _beforeDestroyChildSubscription;
  StreamSubscription<bool> _toggleStateSubscription;

  bool isOpen = false;

  //-----------------------------
  // constructor
  //-----------------------------

  SidePanel(@Inject(Element) Element elementRef) : super(elementRef) {
    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override
  Stream<Entity> provideState() => _isOpen$ctrl.stream
      .map((bool isOpen) => SerializableTuple1<bool>()..item1 = isOpen);

  @override
  void receiveState(SerializableTuple1 entity, StatePhase phase) {
    final bool item1 = entity.item1;

    _isOpen$ctrl.add(item1);

    if (isOpen != item1) setState(() => isOpen = item1);
  }

  @override
  void ngOnDestroy() {
    super.ngOnDestroy();

    _beforeDestroyChildSubscription?.cancel();
    _toggleStateSubscription?.cancel();

    _beforeDestroyChild$ctrl.close();
    _isOpen$ctrl.close();
    _toggle$ctrl.close();
  }

  @override
  Stream<bool> ngBeforeDestroyChild([List<dynamic> args]) async* {
    final Completer<bool> completer = Completer<bool>();

    beforeDestroyChild.add(true);

    beforeDestroyChild.stream.take(1).listen((_) {
      completer.complete(true);
    });

    await completer.future;

    yield true;
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initStreams() {
    _toggleStateSubscription = Observable(_isOpen$ctrl.stream.distinct())
        .startWith(false)
        .switchMap((isOpen) => Observable(_toggle$ctrl.stream)
            .debounce(const Duration(milliseconds: 100))
            .map((_) => isOpen)
            .take(1))
        .listen(_toggleState);
  }

  void _toggleState(bool newIsOpenState) {
    if (!newIsOpenState) {
      _isOpen$ctrl.add(true);

      if (!isOpen) setState(() => this.isOpen = true);
    } else {
      _beforeDestroyChildSubscription?.cancel();

      _beforeDestroyChildSubscription =
          ngBeforeDestroyChild().take(1).listen((_) {
        _isOpen$ctrl.add(false);

        if (isOpen) setState(() => this.isOpen = false);
      });
    }
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void toggle() => _toggle$ctrl.add(true);
}
