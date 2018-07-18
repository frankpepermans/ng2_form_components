library ng2_form_components.components.auto_complete;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';
import 'package:dorm/dorm.dart';

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/drop_down.dart';
import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/list_renderer.dart';
import 'package:ng2_form_components/src/components/list_item.g.dart';
import 'package:ng2_form_components/src/components/animation/tween.dart';

import 'package:ng2_state/ng2_state.dart'
    show
        SerializableTuple2,
        SerializableTuple3,
        StatePhase,
        StateService,
        StatefulComponent;

@Component(
    selector: 'auto-complete',
    templateUrl: 'auto_complete.html',
    directives: const <dynamic>[ListRenderer, Tween, coreDirectives],
    pipes: const <dynamic>[commonPipes],
    providers: const <dynamic>[
      StateService
    ],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class AutoComplete<T extends Comparable<dynamic>> extends DropDown<T>
    implements OnDestroy, AfterViewInit {
  @ViewChild('searchInput')
  Element searchInput;

  //-----------------------------
  // input
  //-----------------------------

  @override
  List<ListItem<Comparable<dynamic>>> get selectedItemsCast =>
      selectedItems?.toList()?.cast<ListItem<Comparable<dynamic>>>();

  bool _moveSelectionOnTop = true;
  bool get moveSelectionOnTop => _moveSelectionOnTop;
  @Input()
  set moveSelectionOnTop(bool value) {
    if (_moveSelectionOnTop != value) setState(() => _moveSelectionOnTop = value);
  }

  int _minCharsRequired = 2;
  int get minCharsRequired => _minCharsRequired;
  @Input()
  set minCharsRequired(int value) {
    if (_minCharsRequired != value) setState(() => _minCharsRequired = value);
  }

  @Input()
  @override
  set dataProvider(Iterable<ListItem<T>> value) {
    if (dataProvider != value) {
      super.dataProvider = value;

      _dataProviderChanged$ctrl.add(dataProvider);
    }
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output()
  Stream<String> get inputChanged => _inputChanged$;
  @override
  @Output()
  Stream<Iterable<ListItem<T>>> get selectedItemsChanged =>
      super.selectedItemsChanged;

  //-----------------------------
  // private properties
  //-----------------------------

  Stream<String> _inputChanged$;

  StreamSubscription<Tuple2<bool, List<ListItem<T>>>>
      _mergedDataProviderChangedSubscription;
  StreamSubscription<String> _inputChangedSubscription;
  StreamSubscription<String> _currentHeaderLabelSubscription;

  final StreamController<String> _input$ctrl =
      new StreamController<String>.broadcast();
  final StreamController<Iterable<ListItem<T>>> _dataProviderChanged$ctrl =
      new StreamController<Iterable<ListItem<T>>>.broadcast();
  final StreamController<bool> _inputCriteriaMet$ctrl =
      new StreamController<bool>.broadcast();
  final StreamController<bool> _focus$ctrl =
      new StreamController<bool>.broadcast();

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

  AutoComplete(@Inject(Element) Element elementRef) : super(elementRef) {
    super.className = 'ng2-form-components-auto-complete';

    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override
  Stream<Entity> provideState() {
    final rx.Observable<SerializableTuple2<bool, Iterable<ListItem<T>>>>
        superProvider = super.provideState()
            as rx.Observable<SerializableTuple2<bool, Iterable<ListItem<T>>>>;

    return rx.Observable.combineLatest2(
        superProvider,
        new rx.Observable<String>(_input$ctrl.stream)
            .startWith('')
            .distinct((String vA, String vB) => vA.compareTo(vB) == 0),
        (SerializableTuple2<bool, Iterable<ListItem<T>>> tuple, String input) =>
            new SerializableTuple3<bool, Iterable<ListItem<T>>, String>()
              ..item1 = tuple.item1
              ..item2 = tuple.item2
              ..item3 = input);
  }

  @override
  void receiveState(SerializableTuple3<bool, Iterable<Entity>, String> entity,
      StatePhase phase) {
    if (phase == StatePhase.REPLAY) _focus$ctrl.add(true);

    if (entity.item3 != lastReplayedInputValue) {
      lastReplayedInputValue = inputValue = entity.item3;

      _inputCriteriaMet$ctrl.add(entity.item3.length >= minCharsRequired);

      _input$ctrl.add(entity.item3);
    }

    super.receiveState(
        new SerializableTuple2<bool, Iterable<Entity>>()
          ..item1 = entity.item1
          ..item2 = entity.item2,
        phase);
  }

  @override
  void ngOnDestroy() {
    super.ngOnDestroy();

    if (_mergedDataProviderChangedSubscription != null)
      _mergedDataProviderChangedSubscription.cancel();
    if (_inputChangedSubscription != null) _inputChangedSubscription.cancel();
    if (_currentHeaderLabelSubscription != null)
      _currentHeaderLabelSubscription.cancel();

    _input$ctrl.close();
    _dataProviderChanged$ctrl.close();
    _inputCriteriaMet$ctrl.close();
    _focus$ctrl.close();
  }

  void setInputValue(String value) {
    if (searchInput != null)
      (searchInput as InputElement).value = value;

    _inputCriteriaMet$ctrl.add(value.length >= minCharsRequired);

    _input$ctrl.add(value);

    setState(() => inputValue = value);
  }

  @override
  void clear() {
    super.clear();

    setInputValue('');
  }

  //-----------------------------
  // private methods
  //-----------------------------

  @override
  void setSelectedItems(Iterable<ListItem<T>> value) {
    if (mergedDataProvider == null)
      mergedDataProvider = new List<ListItem<T>>.from(value);
    else {
      final List<ListItem<T>> clonedList =
          mergedDataProvider.toList(growable: true);

      value.forEach((ListItem<T> listItem) {
        ListItem<T> matchingListItem = mergedDataProvider.firstWhere(
            (ListItem<T> existingListItem) =>
                existingListItem.compareTo(listItem) == 0,
            orElse: () => null);

        if (matchingListItem == null) clonedList.add(listItem);
      });

      mergedDataProvider = clonedList;
    }

    _updateHasDropDownValues();

    super.setSelectedItems(value);
  }

  @override
  void setOpenOrClosed(bool value) {
    super.setOpenOrClosed(value);

    _updateHasDropDownValues();
  }

  void _updateHasDropDownValues() {
    hasDropDownValues =
        isOpen && mergedDataProvider != null && mergedDataProvider.isNotEmpty;
  }

  void _initStreams() {
    _currentHeaderLabelSubscription =
        new rx.Observable<Iterable<ListItem<T>>>(selectedItemsChanged)
            .startWith(const []).map((Iterable<ListItem<T>> selectedItems) {
      if (selectedItems != null && selectedItems.isNotEmpty) {
        return (selectedItems.length == 1)
            ? labelHandler(selectedItems.first.data)
            : selectedItems
                .map((ListItem<T> listItem) =>
                    labelHandler(listItem.data))
                .join(', ');
      }

      return '';
    }).listen((String headerLabel) {
      setState(() => currentHeaderLabel = headerLabel);
    });

    _inputChanged$ = new rx.Observable<String>(_input$ctrl.stream)
        .debounce(const Duration(milliseconds: 50))
        .where((String input) => input.length >= minCharsRequired);

    final Stream<Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>>
        mergedDataProviderChanged$ = rx.Observable
            .combineLatest3(
                new rx.Observable<bool>(_focus$ctrl.stream)
                    .distinct((bool bA, bool bB) => bA == bB)
                    .startWith(false),
                new rx.Observable<Iterable<ListItem<T>>>(
                    _dataProviderChanged$ctrl.stream),
                new rx.Observable<Iterable<ListItem<T>>>(selectedItemsChanged)
                    .startWith(const []),
                (bool hasBeenFocused, Iterable<ListItem<T>> dataProvider,
                        Iterable<ListItem<T>> selectedItems) =>
                    new Tuple4<
                        bool,
                        Iterable<ListItem<T>>,
                        Iterable<ListItem<T>>,
                        bool>(hasBeenFocused, dataProvider, selectedItems, true))
            .asBroadcastStream();

    final Stream<
            Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>>
        mergedSelectedItemsChangedChanged$ = rx.Observable
            .combineLatest3(
                new rx.Observable<bool>(_focus$ctrl.stream)
                    .distinct((bool bA, bool bB) => bA == bB)
                    .startWith(false),
                new rx.Observable<String>(_input$ctrl.stream).startWith(null),
                new rx.Observable<Iterable<ListItem<T>>>(selectedItemsChanged)
                    .startWith(null),
                (bool hasBeenFocused, dynamic _,
                        Iterable<ListItem<T>> selectedItems) =>
                    new Tuple4<
                        bool,
                        Iterable<ListItem<T>>,
                        Iterable<ListItem<T>>,
                        bool>(hasBeenFocused, null, selectedItems, false))
            .asBroadcastStream();

    final rx.Observable<
        Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>,
            bool>> merged$ = new rx.Observable<
        Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>,
            bool>>.merge(<
        Stream<
            Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>>>[
      mergedDataProviderChanged$,
      mergedSelectedItemsChangedChanged$
    ]).asBroadcastStream();

    _mergedDataProviderChangedSubscription = new rx.Observable<bool>(
            _inputCriteriaMet$ctrl.stream)
        .distinct((bool bA, bool bB) => bA == bB)
        .switchMap((bool isCriteriaMet) => merged$
            .where(
                (Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool> tuple) =>
                    tuple.item4 == isCriteriaMet)
            .map((Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>
                    tuple) =>
                new Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool>(
                    tuple.item1, tuple.item2, tuple.item3, isCriteriaMet)))
        .map(_rebuildMergedDataProvider)
        .doOnData((Tuple2<bool, List<ListItem<T>>> tuple) {
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

  Tuple2<bool, List<ListItem<T>>> _rebuildMergedDataProvider(
      Tuple4<bool, Iterable<ListItem<T>>, Iterable<ListItem<T>>, bool> tuple) {
    final List<ListItem<T>> list = <ListItem<T>>[];

    if (moveSelectionOnTop && tuple.item3 != null) {
      tuple.item3.forEach((ListItem<T> listItem) {
        if (list.firstWhere((ListItem<T> item) => listItem.compareTo(item) == 0,
                orElse: () => null) ==
            null) list.add(listItem);
      });
    }

    if (tuple.item4 && tuple.item2 != null) {
      tuple.item2.forEach((ListItem<T> listItem) {
        if (list.firstWhere((ListItem<T> item) => listItem.compareTo(item) == 0,
                orElse: () => null) ==
            null) list.add(listItem);
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
    final TextInputElement element = event.target as TextInputElement;

    _inputCriteriaMet$ctrl.add(element.value.length >= minCharsRequired);

    _input$ctrl.add(element.value);

    //setSelectedItems(const []);
  }

  @override
  void updateSelectedItemsCast(List<ListItem<Comparable<dynamic>>> items) =>
      super.updateSelectedItems(items?.cast<ListItem<T>>());
}
