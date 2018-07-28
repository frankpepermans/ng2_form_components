import 'dart:async';
import 'dart:html';

import 'package:dorm/dorm.dart';
import 'package:rxdart/rxdart.dart' as rx;

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:ng2_state/ng2_state.dart'
    show SerializableTuple1, StatePhase, StatefulComponent;

@Component(
    selector: 'form-input',
    templateUrl: 'form_input.html',
    directives: const <dynamic>[coreDirectives],
    pipes: const <dynamic>[commonPipes],
    providers: const <dynamic>[
      const ExistingProvider.forToken(
          const OpaqueToken('statefulComponent'), FormInput)
    ],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class FormInput extends FormComponent
    implements OnDestroy, AfterViewInit {
  @ViewChild('textarea')
  Element textarea;

  //-----------------------------
  // input
  //-----------------------------

  String _inputType;
  String get inputType => _inputType;
  @Input()
  set inputType(String value) {
    if (_inputType != value) {
      _inputType = value;

      _inputType$ctrl.add(value);
    }
  }

  String _placeHolder = 'Vrije text';
  String get placeHolder => _placeHolder;
  @Input()
  set placeHolder(String value) {
    if (value != _placeHolder) setState(() => _placeHolder = value);
  }

  @Input()
  set initialValue(String value) {
    if (value == null) return;

    if (value != _inputValue$ctrl.value) _inputValue$ctrl.add(value);
  }

  int _heightCalcAdjustment = 0;
  int get heightCalcAdjustment => _heightCalcAdjustment;
  @Input()
  set heightCalcAdjustment(int value) {
    if (value != _heightCalcAdjustment)
      setState(() => _heightCalcAdjustment = value);
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output()
  Stream<String> get inputValue => _inputValue$ctrl.stream.distinct();
  @Output()
  Stream<FocusEvent> get focus => _focusEvent$ctrl.stream;
  @Output()
  Stream<FocusEvent> get blur => _blurEvent$ctrl.stream;
  @Output()
  Stream<bool> get hasValue => rx.Observable.combineLatest2(
          new rx.Observable<String>(_value$ctrl.stream).startWith(''),
          new rx.Observable<String>(inputValue).startWith(null),
          (String a, String b) {
        if (b == null) {
          if (a != null) return a.trim().isNotEmpty;

          return false;
        }

        return b.trim().isNotEmpty;
      }).distinct();

  //-----------------------------
  // private properties
  //-----------------------------

  final StreamController<String> _value$ctrl =
      new StreamController<String>.broadcast();
  final rx.BehaviorSubject<String> _inputValue$ctrl =
      new rx.BehaviorSubject<String>();
  final StreamController<String> _inputType$ctrl =
      new StreamController<String>.broadcast();
  final StreamController<FocusEvent> _focusEvent$ctrl =
      new StreamController<FocusEvent>.broadcast();
  final StreamController<FocusEvent> _blurEvent$ctrl =
      new StreamController<FocusEvent>.broadcast();

  StreamSubscription<String> _inputTypeSubscription;
  StreamSubscription<String> _valueSubscription;

  bool _setFocusRequested = false;

  //-----------------------------
  // public properties
  //-----------------------------

  String startValue = '';
  String textareaHeight = '0';

  //-----------------------------
  // constructor
  //-----------------------------

  FormInput(@Inject(Element) Element elementRef) : super(elementRef) {
    final Element element = elementRef;

    element.style.display = 'flex';
    element.style.flexDirection = 'column';
    element.style.flexGrow = '1';

    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override
  Stream<Entity> provideState() =>
      _inputValue$ctrl.stream.distinct().map((String inputValue) =>
          new SerializableTuple1<String>()..item1 = inputValue);

  @override
  void receiveState(SerializableTuple1 entity, StatePhase phase) =>
      _inputValue$ctrl.add(entity.item1 as String);

  @override
  void ngAfterViewInit() {
    if (inputType == 'text') {
      final TextAreaElement target = textarea as TextAreaElement;

      window.animationFrame.whenComplete(() {
        final String newValue =
            '${target.scrollHeight - heightCalcAdjustment}px';

        if (textareaHeight != newValue)
          setState(() => textareaHeight = newValue);
      });
    }

    if (_setFocusRequested) setFocus();
  }

  @override
  void ngOnDestroy() {
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
    final Element element = elementRef;

    if (element.children.isNotEmpty) {
      element.children.first.focus();

      _setFocusRequested = false;
    } else
      _setFocusRequested = true;
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initStreams() {
    _valueSubscription = _value$ctrl.stream
        .listen((String value) => setState(() => startValue = value));

    _inputTypeSubscription = rx.Observable
        .combineLatest2(_inputType$ctrl.stream, _inputValue$ctrl.stream,
            (String inputType, String inputValue) {
      if (inputType == 'text' ||
          inputType == 'amount' ||
          inputType == 'numeric')
        return inputValue;
      else if (inputType == 'date') {
        if (_isValidDateFormat(inputValue)) return inputValue;

        if (inputValue != null) {
          final List<String> parts = inputValue.split('/');

          if (parts.length == 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }
    }).listen((String value) {
      _value$ctrl.add(value);

      deliverStateChanges();
    });
  }

  bool _isValidDateFormat(String value) {
    if (value == null || value.isEmpty) return false;

    final List<String> parts = value.split('-');

    return parts.length == 3;
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void clear() {
    setState(() => startValue = null);

    _inputValue$ctrl.add(null);
  }

  void handleInput(Event event) {
    String valueToSet;

    if (inputType == 'text') {
      final TextAreaElement target = event.target as TextAreaElement;

      valueToSet = target.value;

      final String newValue = '${target.scrollHeight - heightCalcAdjustment}px';

      if (textareaHeight != newValue) setState(() => textareaHeight = newValue);
    } else if (inputType == 'amount' || inputType == 'numeric') {
      final InputElement target = event.target as InputElement;

      valueToSet = target.value;
    } else if (inputType == 'date') {
      final InputElement target = event.target as InputElement;
      final List<String> parts = target.value.split('-');

      if (parts.length == 3)
        valueToSet = '${parts[2]}/${parts[1]}/${parts[0]}';
      else
        valueToSet = null;
    }

    _inputValue$ctrl.add(valueToSet);
  }

  void handleFocus(FocusEvent event) => _focusEvent$ctrl.add(event);

  void handleClick(MouseEvent event) {
    event.stopPropagation();
    event.stopImmediatePropagation();
  }

  void handleBlur(FocusEvent event, [bool handleInput = false]) {
    _blurEvent$ctrl.add(event);

    if (handleInput) this.handleInput(event);
  }
}
