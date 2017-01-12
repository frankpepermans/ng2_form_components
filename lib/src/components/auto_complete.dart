library ng2_form_components.components.auto_complete;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';
import 'package:dorm/dorm.dart';

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/drop_down.dart';
import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/list_renderer.dart';
import 'package:ng2_form_components/src/components/list_item.g.dart';
import 'package:ng2_form_components/src/components/animation/tween.dart';

import 'package:ng2_state/ng2_state.dart' show SerializableTuple2, SerializableTuple3, StatePhase, StateService, StatefulComponent;

@Component(
    selector: 'auto-complete',
    templateUrl: 'auto_complete.html',
    directives: const <Type>[ListRenderer, Tween, NgClass, NgIf],
    providers: const <dynamic>[StateService, const Provider(StatefulComponent, useExisting: AutoComplete)],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false
)
class AutoComplete<T extends Comparable<dynamic>> extends DropDown<T> implements OnChanges, OnDestroy, AfterViewInit {

  @ViewChild('searchInput') ElementRef searchInput;

  //-----------------------------
  // input
  //-----------------------------

  @override @Input() set labelHandler(LabelHandler value) {
    super.labelHandler = value;
  }

  @override @Input() set dataProvider(Iterable<ListItem<T>> value) {
    super.dataProvider = value;
  }

  @override @Input() set selectedItems(Iterable<ListItem<T>> value) {
    super.selectedItems = value;
  }

  @override @Input() set headerLabel(String value) {
    super.headerLabel = value;
  }

  @override @Input() set allowMultiSelection(bool value) {
    super.allowMultiSelection = value;
  }

  @override @Input() set childOffset(int value) {
    super.childOffset = value;
  }

  @override @Input() set resolveRendererHandler(ResolveRendererHandler value) {
    super.resolveRendererHandler = value;
  }

  @override @Input() set className(String value) {
    super.className = value;
  }

  bool _moveSelectionOnTop = true;
  bool get moveSelectionOnTop => _moveSelectionOnTop;
  @Input() set moveSelectionOnTop(bool value) {
    setState(() => _moveSelectionOnTop = value);
  }

  int _minCharsRequired = 3;
  int get minCharsRequired => _minCharsRequired;
  @Input() set minCharsRequired(int value) {
    setState(() => _minCharsRequired = value);
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output() Stream<String> get inputChanged => _inputChanged$;
  @override @Output() Stream<Iterable<ListItem<T>>> get selectedItemsChanged => super.selectedItemsChanged;

  //-----------------------------
  // private properties
  //-----------------------------

  Stream<String> _inputChanged$;

  StreamSubscription<Tuple2<bool, List<ListItem<T>>>> _mergedDataProviderChangedSubscription;
  StreamSubscription<String> _inputChangedSubscription;
  StreamSubscription<String> _currentHeaderLabelSubscription;

  final StreamController<String> _input$ctrl = new StreamController<String>.broadcast();
  final StreamController<Iterable<ListItem<T>>> _dataProviderChanged$ctrl = new StreamController<Iterable<ListItem<T>>>.broadcast();
  final StreamController<bool> _inputCriteriaMet$ctrl = new StreamController<bool>.broadcast();
  final StreamController<bool> _focus$ctrl = new StreamController<bool>.broadcast();

  //-----------------------------
  // public properties
  //-----------------------------

  bool showLoading = false;
  bool hasDropDownValues = false;
  String inputValue, lastReplayedInputValue;

  List<ListItem<T>> mergedDataProvider = <ListItem<T>>[];

  //-----------------------------
  // constructor
  //-----------------------------

  AutoComplete(
      @Inject(ElementRef) ElementRef elementRef) : super(elementRef) {
    super.className = 'ng2-form-components-auto-complete';

    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override
  Stream<Entity> provideState() {
    final rx.Observable<SerializableTuple2<bool, Iterable<ListItem<T>>>> superProvider = super.provideState() as rx.Observable<SerializableTuple2<bool, Iterable<ListItem<T>>>>;

    return rx.Observable.combineTwoLatest(
        superProvider,
        rx.observable(_input$ctrl.stream)
            .startWith('')
            .distinct((String vA, String vB) => vA.compareTo(vB) == 0)
        , (SerializableTuple2<bool, Iterable<ListItem<T>>> tuple, String input) =>
    new SerializableTuple3<bool, Iterable<ListItem<T>>, String>()
      ..item1 = tuple.item1
      ..item2 = tuple.item2
      ..item3 = input
    );
  }

  @override
  void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple3<bool, Iterable<Entity>, String> tuple = entity as SerializableTuple3<bool, Iterable<Entity>, String>;

    if (phase == StatePhase.REPLAY) _focus$ctrl.add(true);

    if (tuple.item3 != lastReplayedInputValue) {
      lastReplayedInputValue = inputValue = tuple.item3;

      _inputCriteriaMet$ctrl.add(tuple.item3.length >= minCharsRequired);

      _input$ctrl.add(tuple.item3);
    }

    super.receiveState(new SerializableTuple2<bool, List<Entity>>()
      ..item1 = tuple.item1
      ..item2 = tuple.item2, phase);
  }

  @override
  void ngOnChanges(Map<String, SimpleChange> changes) {
    super.ngOnChanges(changes);

    if (changes.containsKey('dataProvider')) _dataProviderChanged$ctrl.add(dataProvider);
  }

  @override
  void ngOnDestroy() {
    super.ngOnDestroy();

    if (_mergedDataProviderChangedSubscription != null) _mergedDataProviderChangedSubscription.cancel();
    if (_inputChangedSubscription != null) _inputChangedSubscription.cancel();
    if (_currentHeaderLabelSubscription != null) _currentHeaderLabelSubscription.cancel();

    _input$ctrl.close();
    _dataProviderChanged$ctrl.close();
    _inputCriteriaMet$ctrl.close();
    _focus$ctrl.close();
  }

  void setInputValue(String value) {
    if (searchInput != null) (searchInput.nativeElement as InputElement).value = value;

    _inputCriteriaMet$ctrl.add(value.length >= minCharsRequired);

    _input$ctrl.add(value);

    setState(() => inputValue = value);
  }

  @override void clear() {
    super.clear();

    setInputValue('');
  }

  //-----------------------------
  // private methods
  //-----------------------------

  @override void setSelectedItems(Iterable<ListItem<T>> value) {
    if (mergedDataProvider == null) mergedDataProvider = value;
    else {
      final List<ListItem<T>> clonedList = mergedDataProvider.toList(growable: true);

      value.forEach((ListItem<T> listItem) {
        ListItem<T> matchingListItem = mergedDataProvider.firstWhere((ListItem<T> existingListItem) => existingListItem.compareTo(listItem) == 0, orElse: () => null);

        if (matchingListItem == null) clonedList.add(listItem);
      });

      mergedDataProvider = clonedList;
    }

    _updateHasDropDownValues();

    super.setSelectedItems(value);
  }

  @override void setOpenOrClosed(bool value) {
    super.setOpenOrClosed(value);

    _updateHasDropDownValues();
  }

  void _updateHasDropDownValues() {
    hasDropDownValues = (isOpen && mergedDataProvider != null && mergedDataProvider.isNotEmpty);
  }

  void _initStreams() {
    _currentHeaderLabelSubscription = rx.observable(selectedItemsChanged).startWith(const [])
      .map((Iterable<ListItem<T>> selectedItems) {
        if (selectedItems != null && selectedItems.isNotEmpty) {
          return (selectedItems.length == 1) ?
            labelHandler(selectedItems.first.data) as String :
            selectedItems.map((ListItem<T> listItem) => labelHandler(listItem.data) as String).join(', ');
        }

        return '';
      }).listen((String headerLabel) {
        setState(() => currentHeaderLabel = headerLabel);
      });

    _inputChanged$ = rx.observable(_input$ctrl.stream)
      .debounce(const Duration(milliseconds: 50))
      .where((String input) => input.length >= minCharsRequired);

    final Stream<Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>> mergedDataProviderChanged$ = rx.Observable.combineThreeLatest(
        rx.observable(_focus$ctrl.stream)
            .distinct((bool bA, bool bB) => bA == bB)
            .startWith(false),
        rx.observable(_dataProviderChanged$ctrl.stream),
        rx.observable(selectedItemsChanged)
            .startWith(const [])
        , (bool hasBeenFocused, Iterable<ListItem<T>> dataProvider, Iterable<ListItem<T>> selectedItems) => new Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>(hasBeenFocused, dataProvider, selectedItems, true), asBroadcastStream: true);

    final Stream<Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>> mergedSelectedItemsChangedChanged$ = rx.Observable.combineThreeLatest(
        rx.observable(_focus$ctrl.stream)
            .distinct((bool bA, bool bB) => bA == bB)
            .startWith(false),
        rx.observable(_input$ctrl.stream)
            .startWith(null),
        rx.observable(selectedItemsChanged)
            .startWith(null)
        , (bool hasBeenFocused, _, Iterable<ListItem<T>> selectedItems) => new Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>(hasBeenFocused, null, selectedItems, false), asBroadcastStream: true);

    final rx.Observable<Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>> merged$ = new rx.Observable<Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>>.merge(<Stream<Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>>>[
      mergedDataProviderChanged$,
      mergedSelectedItemsChangedChanged$
    ], asBroadcastStream: true);

    _mergedDataProviderChangedSubscription = rx.observable(_inputCriteriaMet$ctrl.stream)
      .distinct((bool bA, bool bB) => bA == bB)
      .flatMapLatest((bool isCriteriaMet) =>
        merged$
          .where((Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool> tuple) => tuple.item4 == isCriteriaMet)
          .map((Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool> tuple) => new Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>(tuple.item1, tuple.item2, tuple.item3, isCriteriaMet)))
      .map(_rebuildMergedDataProvider)
      .tap((Tuple2<bool, List<ListItem<T>>> tuple) {
        mergedDataProvider = tuple.item2;

        showLoading = false;

        _updateHasDropDownValues();

        if (tuple.item1) open();

        setState(() => showLoading = false);
      })
      .debounce(const Duration(milliseconds: 30))
      .listen((_) => deliverStateChanges());

    _inputChangedSubscription = _inputChanged$.listen((_) {
      if (!showLoading) setState(() => showLoading = true);
    });
  }

  Tuple2<bool, List<ListItem<T>>> _rebuildMergedDataProvider(Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool> tuple) {
    final List<ListItem<T>> list = new List<ListItem<T>>();

    if (moveSelectionOnTop && tuple.item3 != null) {
      tuple.item3.forEach((ListItem<T> listItem) {
        if (list.firstWhere((ListItem<T> item) => listItem.compareTo(item) == 0, orElse: () => null) == null) list.add(listItem);
      });
    }

    if (tuple.item4 && tuple.item2 != null) {
      tuple.item2.forEach((ListItem<T> listItem) {
        if (list.firstWhere((ListItem<T> item) => listItem.compareTo(item) == 0, orElse: () => null) == null) list.add(listItem);
      });
    }

    return new Tuple2<bool, List<ListItem<T>>>(tuple.item1, list);
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void handleFocus() {
    _focus$ctrl.add(true);

    open();
  }

  void open() {
    if (!isOpen) openOrClose();
  }

  void handleInput(Event event) {
    final TextInputElement element = event.target;

    _inputCriteriaMet$ctrl.add(element.value.length >= minCharsRequired);

    _input$ctrl.add(element.value);

    //setSelectedItems(const []);
  }

}