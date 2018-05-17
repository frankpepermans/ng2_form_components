library ng2_form_components.components.text_input;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:dorm/dorm.dart';

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:ng2_state/ng2_state.dart'
    show SerializableTuple2, StatePhase, StateService, StatefulComponent;

typedef void TextInputAction(String inputValue);

@Component(
    selector: 'text-input',
    templateUrl: 'text_input.html',
    directives: const <dynamic>[coreDirectives],
    pipes: const <dynamic>[commonPipes],
    providers: const <dynamic>[
      StateService,
      const Provider<Type>(StatefulComponent, useExisting: TextInput)
    ],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class TextInput<T extends Comparable<dynamic>> extends FormComponent<T>
    implements OnChanges, OnDestroy {
  @ViewChild('inputField')
  Element inputField;

  //-----------------------------
  // input
  //-----------------------------
  TextInputAction _action;
  TextInputAction get action => _action;
  @Input()
  set action(TextInputAction value) {
    _action = value;

    _textInputAction$ctrl.add(value);
  }

  String _inputValue;
  String get inputValue => _inputValue;
  @Input()
  set inputValue(String value) {
    if (_inputValue != value) setState(() => _inputValue = value);
  }

  @Input()
  String placeHolder;
  @Input()
  String actionContainerClassName;
  @Input()
  String actionIconClassName;

  //-----------------------------
  // output
  //-----------------------------

  @Output()
  Stream<String> get valueChanged => _input$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  final StreamController<String> _input$ctrl =
          new StreamController<String>.broadcast(),
      _action$ctrl = new StreamController<String>.broadcast();
  final StreamController<TextInputAction> _textInputAction$ctrl =
      new StreamController<TextInputAction>.broadcast();

  StreamSubscription<String> _inputSubscription;
  StreamSubscription<KeyboardEvent> _enterKeySubscription;

  Map<String, bool> actionContainerClassMap = const <String, bool>{},
      actionIconClassMap = const <String, bool>{};

  String _internalValue;

  //-----------------------------
  // public properties
  //-----------------------------

  //-----------------------------
  // constructor
  //-----------------------------

  TextInput(@Inject(Element) Element elementRef) : super(elementRef) {
    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override
  Stream<Entity> provideState() {
    return new rx.Observable<SerializableTuple2<String, bool>>.merge(<
        Stream<SerializableTuple2<String, bool>>>[
      _input$ctrl.stream
          .map((String inputValue) => new SerializableTuple2<String, bool>()
            ..item1 = inputValue
            ..item2 = false),
      _action$ctrl.stream
          .map((String inputValue) => new SerializableTuple2<String, bool>()
            ..item1 = inputValue
            ..item2 = true)
    ]);
  }

  @override
  void receiveState(SerializableTuple2<String, bool> entity, StatePhase phase) {
    inputValue = _internalValue = entity.item1;

    if (entity.item2 && _internalValue != null && _internalValue.isNotEmpty) {
      if (action != null)
        action(_internalValue);
      else {
        _textInputAction$ctrl.stream
            .take(1)
            .listen((TextInputAction action) => action(_internalValue));
      }
    }

    deliverStateChanges();
  }

  @override
  void ngOnChanges(Map<String, SimpleChange> changes) {
    if (changes.containsKey('actionContainerClassName'))
      actionContainerClassMap = <String, bool>{actionContainerClassName: true};

    if (changes.containsKey('actionIconClassName'))
      actionIconClassMap = <String, bool>{actionIconClassName: true};
  }

  @override
  void ngOnDestroy() {
    _inputSubscription.cancel();
    _enterKeySubscription.cancel();

    super.ngOnDestroy();

    _input$ctrl.close();
    _action$ctrl.close();
    _textInputAction$ctrl.close();
  }

  void clear() {
    final InputElement inputElement = inputField;

    _input$ctrl.add('');

    if (action != null) action('');

    inputValue = '';
    inputElement.value = '';
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initStreams() {
    final Element element = elementRef;

    _inputSubscription = _input$ctrl.stream.listen((String inputValue) {
      _internalValue = inputValue;
    });

    _enterKeySubscription = element.onKeyDown
        .where((_) => action != null)
        .where((KeyboardEvent event) => event.keyCode == KeyCode.ENTER)
        .listen((_) => action(_internalValue));
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void handleInput(Event event) {
    final TextInputElement element = event.target as TextInputElement;

    _input$ctrl.add(element.value);
  }

  void doAction() {
    if (action != null) {
      _action$ctrl.add(_internalValue);

      action(_internalValue);
    }
  }
}
