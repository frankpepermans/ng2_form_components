library ng2_form_components.components.text_input;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:dorm/dorm.dart';

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:ng2_state/ng2_state.dart' show SerializableTuple2, StatePhase;

typedef void TextInputAction(String inputValue);

@Component(
    selector: 'text-input',
    templateUrl: 'text_input.html',
    directives: const [NgClass, NgIf],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class TextInput<T extends Comparable> extends FormComponent<T> implements OnChanges, OnDestroy {

  //-----------------------------
  // input
  //-----------------------------

  @Input() String placeHolder;
  @Input() String inputValue;
  @Input() TextInputAction action;
  @Input() String actionContainerClassName;
  @Input() String actionIconClassName;

  @Output() Stream<String> get valueChanged => _input$ctrl.stream;

  //-----------------------------
  // output
  //-----------------------------

  //-----------------------------
  // private properties
  //-----------------------------

  final StreamController<String> _input$ctrl = new StreamController<String>.broadcast(), _action$ctrl = new StreamController<String>.broadcast();

  StreamSubscription<String> _inputSubscription;

  Map<String, bool> actionContainerClassMap = const {}, actionIconClassMap = const {};

  //-----------------------------
  // public properties
  //-----------------------------

  //-----------------------------
  // constructor
  //-----------------------------

  TextInput(@Inject(ChangeDetectorRef) ChangeDetectorRef changeDetector) : super(changeDetector) {
    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<Entity> provideState() {
    return new rx.Observable<SerializableTuple2<String, bool>>.merge([
      _input$ctrl.stream.map((String inputValue) => new SerializableTuple2<String, bool>()..item1 = inputValue..item2 = false),
      _action$ctrl.stream.map((String inputValue) => new SerializableTuple2<String, bool>()..item1 = inputValue..item2 = true)
    ]);
  }

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple2<String, bool> tuple = entity as SerializableTuple2<String, bool>;

    inputValue = tuple.item1;

    if (tuple.item2 && inputValue != null && inputValue.isNotEmpty && action != null) action(inputValue);

    changeDetector.markForCheck();
  }

  @override void ngOnChanges(Map<String, SimpleChange> changes) {
    if (changes.containsKey('actionContainerClassName')) actionContainerClassMap = <String, bool>{actionContainerClassName: true};

    if (changes.containsKey('actionIconClassName')) actionIconClassMap = <String, bool>{actionIconClassName: true};
  }

  @override
  void ngOnDestroy() {
    _inputSubscription.cancel();

    super.ngOnDestroy();
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initStreams() {
    _inputSubscription = _input$ctrl.stream
      .listen((String inputValue) {
        this.inputValue = inputValue;
      });
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void handleInput(Event event) {
    final TextInputElement element = event.target;

    _input$ctrl.add(element.value);
  }

  void doAction() {
    if (action != null) {
      _action$ctrl.add(inputValue);

      action(inputValue);
    }
  }

}