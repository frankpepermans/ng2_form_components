library ng2_form_components.components.form_input;

import 'dart:async';
import 'dart:html';

import 'package:dorm/dorm.dart';
import 'package:rxdart/rxdart.dart' as rx;

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:ng2_state/ng2_state.dart' show SerializableTuple1, StatePhase, StateService;

@Component(
    selector: 'form-input',
    templateUrl: 'form_input.html',
    directives: const <Type>[],
    providers: const <Type>[],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class FormInput<T extends Comparable<dynamic>> extends FormComponent<T> implements OnDestroy {

  //-----------------------------
  // input
  //-----------------------------

  String _inputType;
  String get inputType => _inputType;
  @Input() set inputType(String value) {
    _inputType = value;

    _inputType$ctrl.add(value);
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output() Stream<String> get inputValue => _inputValue$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  StreamController<String> _inputValue$ctrl = new StreamController<String>.broadcast();
  StreamController<String> _inputType$ctrl = new StreamController<String>.broadcast();

  StreamSubscription<String> _inputTypeSubscription;

  //-----------------------------
  // public properties
  //-----------------------------

  String startValue = '';

  //-----------------------------
  // constructor
  //-----------------------------

  FormInput(
    @Inject(ChangeDetectorRef) ChangeDetectorRef changeDetector,
    @Inject(ElementRef) ElementRef elementRef,
    @Inject(StateService) StateService stateService) : super(changeDetector, elementRef, stateService) {
      final Element element = elementRef.nativeElement;

      element.style.display = 'flex';
      element.style.flexDirection = 'column';
      element.style.flexGrow = '1';

      _initStreams();
    }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<Entity> provideState() => _inputValue$ctrl.stream
    .map((String inputValue) => new SerializableTuple1<String>()..item1 = inputValue);

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple1<String> tuple = entity as SerializableTuple1<String>;

    _inputTypeSubscription?.cancel();

    _inputTypeSubscription = rx.observable(_inputType$ctrl.stream)
      .where((String inputType) => inputType != null)
      .take(1)
      .listen((String inputType) {
        if (inputType == 'text' || inputType == 'amount' || inputType == 'numeric') startValue = tuple.item1;
        else if (inputType == 'date') {
          final List<String> parts = tuple.item1.split('/');

          if (parts.length == 3) startValue = '${parts[2]}-${parts[1]}-${parts[0]}';
        }

        changeDetector.markForCheck();
      });

    _inputValue$ctrl.add(tuple.item1);
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();

    _inputTypeSubscription?.cancel();

    _inputValue$ctrl.close();
    _inputType$ctrl.close();
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initStreams() {
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void handleInput(Event event) {
    final InputElement target = event.target;
    String valueToSet;

    if (inputType == 'text' || inputType == 'amount' || inputType == 'numeric') valueToSet = target.value;
    else if (inputType == 'date') {
      final List<String> parts = target.value.split('-');

      if (parts.length == 3) valueToSet = '${parts[2]}/${parts[1]}/${parts[0]}';
      else valueToSet = null;
    }

    _inputValue$ctrl.add(valueToSet);
  }

}