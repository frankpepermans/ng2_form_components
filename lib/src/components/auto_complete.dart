import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';
import 'package:dorm/dorm.dart';

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/drop_down.dart';
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
    directives: <dynamic>[ListRenderer, Tween, coreDirectives],
    pipes: <dynamic>[commonPipes],
    providers: <dynamic>[StateService],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class AutoComplete extends DropDown implements OnDestroy, AfterViewInit {
  @ViewChild('searchInput')
  Element searchInput;

  //-----------------------------
  // input
  //-----------------------------

  @override
  List<ListItem<Comparable>> get selectedItemsCast =>
      selectedItems?.toList()?.cast<ListItem<Comparable>>();

  bool _moveSelectionOnTop = true;
  bool get moveSelectionOnTop => _moveSelectionOnTop;
  @Input()
  set moveSelectionOnTop(bool value) {
    if (_moveSelectionOnTop != value)
      setState(() => _moveSelectionOnTop = value);
  }

  int _minCharsRequired = 2;
  int get minCharsRequired => _minCharsRequired;
  @Input()
  set minCharsRequired(int value) {
    if (_minCharsRequired != value) setState(() => _minCharsRequired = value);
  }

  @Input()
  @override
  set dataProvider(Iterable<ListItem<Comparable>> value) {
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
  Stream<Iterable<ListItem<Comparable>>> get selectedItemsChanged =>
      super.selectedItemsChanged;

  //-----------------------------
  // private properties
  //-----------------------------

  Stream<String> _inputChanged$;

  StreamSubscription<Tuple2<bool, List<ListItem<Comparable>>>>
      _mergedDataProviderChangedSubscription;
  StreamSubscription<String> _inputChangedSubscription;
  StreamSubscription<String> _currentHeaderLabelSubscription;

  final StreamController<String> _input$ctrl =
      StreamController<String>.broadcast();
  final StreamController<Iterable<ListItem<Comparable>>>
      _dataProviderChanged$ctrl =
      StreamController<Iterable<ListItem<Comparable>>>.broadcast();
  final StreamController<bool> _inputCriteriaMet$ctrl =
      StreamController<bool>.broadcast();
  final StreamController<bool> _focus$ctrl = StreamController<bool>.broadcast();

  //-----------------------------
  // public properties
  //-----------------------------

  bool showLoading = false;
  bool hasDropDownValues = false;
  String inputValue, lastReplayedInputValue;

  List<ListItem<Comparable>> mergedDataProvider = <ListItem<Comparable>>[];

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
  Stream<Entity> provideState() => Observable.combineLatest2(
          super.provideState(),
          Observable<String>(_input$ctrl.stream)
              .startWith('')
              .distinct((String vA, String vB) => vA.compareTo(vB) == 0),
          (Entity tuple, String input) {
        final SerializableTuple2<bool, Iterable<ListItem<Comparable>>> cast =
            tuple;

        return SerializableTuple3<bool, Iterable<ListItem<Comparable>>,
            String>()
          ..item1 = cast.item1
          ..item2 = cast.item2
          ..item3 = input;
      });

  @override
  void receiveState(SerializableTuple3 entity, StatePhase phase) {
    final item1 = entity.item1 as bool;
    final item2 = List<Entity>.from(entity.item2 as Iterable<Entity>);
    final item3 = entity.item3 as String;

    if (phase == StatePhase.REPLAY) _focus$ctrl.add(true);

    if (item3 != lastReplayedInputValue) {
      lastReplayedInputValue = inputValue = item3;

      _inputCriteriaMet$ctrl.add(item3.length >= minCharsRequired);

      _input$ctrl.add(item3);
    }

    super.receiveState(
        SerializableTuple2<bool, Iterable<Entity>>()
          ..item1 = item1
          ..item2 = item2,
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
    if (searchInput != null) (searchInput as InputElement).value = value;

    _inputCriteriaMet$ctrl.add(value.length >= minCharsRequired);

    _input$ctrl.add(value);

    setState(() {
      inputValue = value;

      if (value == null || value.trim().isEmpty) {
        mergedDataProvider = <ListItem<Comparable>>[];
        dataProvider = <ListItem<Comparable>>[];
        selectedItems = <ListItem<Comparable>>[];
      }
    });
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
  void setSelectedItems(Iterable<ListItem<Comparable>> value) {
    if (mergedDataProvider == null)
      mergedDataProvider = List<ListItem<Comparable>>.from(value);
    else {
      final clonedList = mergedDataProvider.toList(growable: true);

      value.forEach((listItem) {
        var matchingListItem = mergedDataProvider.firstWhere(
            (existingListItem) => existingListItem.compareTo(listItem) == 0,
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
    _currentHeaderLabelSubscription = Observable(selectedItemsChanged)
        .startWith(const []).map((selectedItems) {
      if (selectedItems != null && selectedItems.isNotEmpty) {
        return (selectedItems.length == 1)
            ? labelHandler(selectedItems.first.data)
            : selectedItems
                .map((listItem) => labelHandler(listItem.data))
                .join(', ');
      }

      return '';
    }).listen((headerLabel) {
      setState(() => currentHeaderLabel = headerLabel);
    });

    _inputChanged$ = Observable(_input$ctrl.stream)
        .debounce(const Duration(milliseconds: 50))
        .where((input) => input.length >= minCharsRequired);

    final mergedDataProviderChanged$ = Observable.combineLatest3(
            Observable(_focus$ctrl.stream)
                .distinct((bA, bB) => bA == bB)
                .startWith(false),
            Observable(_dataProviderChanged$ctrl.stream),
            Observable(selectedItemsChanged).startWith(const []),
            (bool hasBeenFocused, Iterable<ListItem<Comparable>> dataProvider,
                    Iterable<ListItem<Comparable>> selectedItems) =>
                Tuple4(hasBeenFocused, dataProvider, selectedItems, true))
        .asBroadcastStream();

    final mergedSelectedItemsChangedChanged$ = Observable.combineLatest3(
            Observable(_focus$ctrl.stream)
                .distinct((bA, bB) => bA == bB)
                .startWith(false),
            Observable(_input$ctrl.stream).startWith(null),
            Observable(selectedItemsChanged).startWith(null),
            (bool hasBeenFocused, dynamic _,
                    Iterable<ListItem<Comparable>> selectedItems) =>
                Tuple4(hasBeenFocused, null, selectedItems, false))
        .asBroadcastStream();

    final merged$ = Observable.merge(
            [mergedDataProviderChanged$, mergedSelectedItemsChangedChanged$])
        .asBroadcastStream();

    _mergedDataProviderChangedSubscription = Observable(
            _inputCriteriaMet$ctrl.stream)
        .distinct((bA, bB) => bA == bB)
        .switchMap((isCriteriaMet) => merged$
            .where((tuple) => tuple.item4 == isCriteriaMet)
            .map((tuple) =>
                Tuple4(tuple.item1, tuple.item2, tuple.item3, isCriteriaMet)))
        .map(_rebuildMergedDataProvider)
        .doOnData((tuple) {
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

  Tuple2<bool, List<ListItem<Comparable>>> _rebuildMergedDataProvider(
      Tuple4<bool, Iterable<ListItem<Comparable>>,
              Iterable<ListItem<Comparable>>, bool>
          tuple) {
    final list = <ListItem<Comparable>>[];

    if (moveSelectionOnTop && tuple.item3 != null) {
      tuple.item3.forEach((listItem) {
        if (list.firstWhere((item) => listItem.compareTo(item) == 0,
                orElse: () => null) ==
            null) list.add(listItem);
      });
    }

    if (tuple.item4 && tuple.item2 != null) {
      tuple.item2.forEach((listItem) {
        if (list.firstWhere((item) => listItem.compareTo(item) == 0,
                orElse: () => null) ==
            null) list.add(listItem);
      });
    }

    return Tuple2(tuple.item1, list);
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
    final element = event.target as TextInputElement;

    _inputCriteriaMet$ctrl.add(element.value.length >= minCharsRequired);

    _input$ctrl.add(element.value);

    //setSelectedItems(const []);
  }

  @override
  void updateSelectedItemsCast(List<ListItem<Comparable>> items) =>
      super.updateSelectedItems(items?.cast<ListItem<Comparable>>());
}
