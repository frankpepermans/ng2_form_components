library ng2_form_components.components.form_input;

import 'dart:async';
import 'dart:html';

import 'package:dorm/dorm.dart';
import 'package:rxdart/rxdart.dart' as rx;

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:ng2_state/ng2_state.dart' show SerializableTuple1, StatePhase, StatefulComponent;

@Component(
    selector: 'form-input',
    templateUrl: 'form_input.html',
    directives: const <Type>[],
    providers: const <dynamic>[const Provider(StatefulComponent, useExisting: FormInput)],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false
)
class FormInput<T extends Comparable<dynamic>> extends FormComponent<T> implements OnDestroy, AfterViewInit {

  @ViewChild('textarea') ElementRef textarea;

  //-----------------------------
  // input
  //-----------------------------

  String _inputType;
  String get inputType => _inputType;
  @Input() set inputType(String value) {
    _inputType = value;

    _inputType$ctrl.add(value);
  }

  @Input() set initialValue(String value) {
    if (value == null) return;

    _inputValue$ctrl.add(value);
  }

  @Input() int heightCalcAdjustment = 0;

  //-----------------------------
  // output
  //-----------------------------

  @Output() Stream<String> get inputValue => _inputValue$ctrl.stream.distinct();
  @Output() Stream<FocusEvent> get focus => _focusEvent$ctrl.stream;
  @Output() Stream<FocusEvent> get blur => _blurEvent$ctrl.stream;
  @Output() Stream<bool> get hasValue => rx.Observable.combineLatest2(
      rx.observable(_value$ctrl.stream)
        .startWith(''),
      rx.observable(inputValue)
        .startWith(null)
    , (String a, String b) {
      if (b == null) {
        if (a != null) return a.trim().isNotEmpty;

        return false;
      }

      return b.trim().isNotEmpty;
    })
    .distinct();

  //-----------------------------
  // private properties
  //-----------------------------

  StreamController<String> _value$ctrl = new StreamController<String>.broadcast();
  StreamController<String> _inputValue$ctrl = new StreamController<String>.broadcast();
  StreamController<String> _inputType$ctrl = new StreamController<String>.broadcast();
  StreamController<FocusEvent> _focusEvent$ctrl = new StreamController<FocusEvent>.broadcast();
  StreamController<FocusEvent> _blurEvent$ctrl = new StreamController<FocusEvent>.broadcast();

  StreamSubscription<String> _inputTypeSubscription;
  StreamSubscription<String> _valueSubscription;

  //-----------------------------
  // public properties
  //-----------------------------

  String startValue = '';
  String textareaHeight = '0';

  //-----------------------------
  // constructor
  //-----------------------------

  FormInput(
    @Inject(ElementRef) ElementRef elementRef) : super(elementRef) {
      final Element element = elementRef.nativeElement;

      element.style.display = 'flex';
      element.style.flexDirection = 'column';
      element.style.flexGrow = '1';

      _initStreams();
    }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<Entity> provideState() => _inputValue$ctrl.stream.distinct()
    .map((String inputValue) => new SerializableTuple1<String>()..item1 = inputValue);

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple1<String> tuple = entity as SerializableTuple1<String>;

    _inputValue$ctrl.add(tuple.item1);
  }

  @override void ngAfterViewInit() {
    if (inputType == 'text') {
      final TextAreaElement target = textarea.nativeElement;

      window.animationFrame.whenComplete(() {
        final String newValue = '${target.scrollHeight - heightCalcAdjustment}px';

        if (textareaHeight != newValue) setState(() => textareaHeight = newValue);
      });
    }
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();

    _inputTypeSubscription?.cancel();
    _valueSubscription?.cancel();

    _value$ctrl.close();
    _inputValue$ctrl.close();
    _inputType$ctrl.close();
    _focusEvent$ctrl.close();
    _blurEvent$ctrl.close();
  }

  void setFocus() {
    final Element element = elementRef.nativeElement;

    element.children.first.focus();
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initStreams() {
    _valueSubscription = _value$ctrl.stream
      .listen((String value) => setState(() => startValue = value));

    _inputTypeSubscription = rx.Observable.combineLatest2(
      _inputType$ctrl.stream,
      _inputValue$ctrl.stream
      , (String inputType, String inputValue) {
        if (inputType == 'text' || inputType == 'amount' || inputType == 'numeric') return inputValue;
        else if (inputType == 'date') {
          if (inputValue != null) {
            final List<String> parts = inputValue.split('/');

            if (parts.length == 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
          }
        }
      })
        .listen((String value) {
          _value$ctrl.add(value);

          deliverStateChanges();
        });
    }

  //-----------------------------
  // template methods
  //-----------------------------

  void handleInput(Event event) {
    String valueToSet;

    if (inputType == 'text') {
      final TextAreaElement target = event.target;

      valueToSet = target.value;

      final String newValue = '${target.scrollHeight - heightCalcAdjustment}px';

      if (textareaHeight != newValue) setState(() => textareaHeight = newValue);
    } else if (inputType == 'amount' || inputType == 'numeric') {
      final InputElement target = event.target;

      valueToSet = target.value;
    } else if (inputType == 'date') {
      final InputElement target = event.target;
      final List<String> parts = target.value.split('-');

      if (parts.length == 3) valueToSet = '${parts[2]}/${parts[1]}/${parts[0]}';
      else valueToSet = null;
    }

    _inputValue$ctrl.add(valueToSet);
  }

  void handleFocus(FocusEvent event) => _focusEvent$ctrl.add(event);

  void handleClick(MouseEvent event) {
    event.stopPropagation();
    event.stopImmediatePropagation();
  }

  void handleBlur(FocusEvent event) => _blurEvent$ctrl.add(event);
}