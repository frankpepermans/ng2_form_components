import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart';
import 'package:dorm/dorm.dart';
import 'package:tuple/tuple.dart';

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/list_renderer.dart';
import 'package:ng2_form_components/src/components/item_renderers/default_list_item_renderer.template.dart'
    as lr;
import 'package:ng2_form_components/src/components/list_item.g.dart';
import 'package:ng2_form_components/src/components/animation/tween.dart';
import 'package:ng2_form_components/src/components/interfaces/before_destroy_child.dart';

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart';

import 'package:ng2_state/ng2_state.dart'
    show SerializableTuple2, StatePhase, StateService, StatefulComponent;

@Component(
    selector: 'drop-down',
    templateUrl: 'drop_down.html',
    directives: <dynamic>[ListRenderer, Tween, coreDirectives],
    pipes: <dynamic>[commonPipes],
    providers: <dynamic>[StateService],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class DropDown extends FormComponent
    implements OnDestroy, AfterViewInit, BeforeDestroyChild {
  //-----------------------------
  // input
  //-----------------------------

  LabelHandler<Comparable> _labelHandler;
  LabelHandler<Comparable> get labelHandler => _labelHandler;
  @Input()
  set labelHandler(LabelHandler<Comparable> value) {
    if (_labelHandler != value) setState(() => _labelHandler = value);
  }

  List<ListItem<Comparable>> get dataProviderCast =>
      dataProvider?.toList()?.cast<ListItem<Comparable>>();

  Iterable<ListItem<Comparable>> _dataProvider;
  Iterable<ListItem<Comparable>> get dataProvider => _dataProvider;
  @Input()
  set dataProvider(Iterable<ListItem<Comparable>> value) {
    if (_dataProvider != value) setState(() => _dataProvider = value);
  }

  bool _updateHeaderLabelWithSelection = true;
  bool get updateHeaderLabelWithSelection => _updateHeaderLabelWithSelection;
  @Input()
  set updateHeaderLabelWithSelection(bool value) {
    if (_updateHeaderLabelWithSelection != value)
      setState(() => _updateHeaderLabelWithSelection = value);
  }

  List<ListItem<Comparable>> get selectedItemsCast =>
      selectedItems?.toList()?.cast<ListItem<Comparable>>();

  Iterable<ListItem<Comparable>> _selectedItems = <ListItem<Comparable>>[];
  Iterable<ListItem<Comparable>> get selectedItems => _selectedItems;
  @Input()
  set selectedItems(Iterable<ListItem<Comparable>> value) {
    if (_selectedItems != value)
      setState(() {
        _selectedItems = value;

        _selectedItems$ctrl.add(selectedItems);
      });
  }

  String _headerLabel;
  String get headerLabel => _headerLabel;
  @Input()
  set headerLabel(String value) {
    if (_headerLabel != value)
      setState(() {
        _headerLabel = value;

        _headerLabel$ctrl.add(headerLabel);
        _selectedItems$ctrl.add(selectedItems);
      });
  }

  String _className = 'ng2-form-components-drop-down';
  String get className => _className;
  @Input()
  set className(String value) {
    if (_className != value) {
      _className = value;

      cssMap = <String, bool>{value: true};
    }
  }

  Map<String, bool> cssMap = const <String, bool>{
    'ng2-form-components-drop-down': true
  };

  bool _allowMultiSelection = false;
  bool get allowMultiSelection => _allowMultiSelection;
  @Input()
  set allowMultiSelection(bool value) {
    if (_allowMultiSelection != value)
      setState(() => _allowMultiSelection = value);
  }

  int _childOffset = 20;
  int get childOffset => _childOffset;
  @Input()
  set childOffset(int value) {
    if (_childOffset != value) setState(() => _childOffset = value);
  }

  ResolveRendererHandler _resolveRendererHandler =
      (_, [__]) => lr.DefaultListItemRendererNgFactory;
  ResolveRendererHandler get resolveRendererHandler => _resolveRendererHandler;
  @Input()
  set resolveRendererHandler(ResolveRendererHandler value) {
    if (_resolveRendererHandler != value)
      setState(() => _resolveRendererHandler = value);
  }

  Function _defaultHandler;
  Function get defaultHandler => _defaultHandler;
  @Input()
  set defaultHandler(Function value) {
    if (_defaultHandler != value) setState(() => _defaultHandler = value);
  }

  bool _resetAfterSelection = false;
  bool get resetAfterSelection => _resetAfterSelection;
  @Input()
  set resetAfterSelection(bool value) {
    if (_resetAfterSelection != value)
      setState(() => _resetAfterSelection = value);
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output()
  Stream<Iterable<ListItem<Comparable>>> get selectedItemsChanged =>
      _selectedItems$ctrl.stream.distinct(_distinctSelectedItems);

  @override
  StreamController<bool> get beforeDestroyChild => _beforeDestroyChild$ctrl;

  @Output()
  Stream<ItemRendererEvent<dynamic, Comparable>> get itemRendererEvent =>
      _itemRendererEvent$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  final StreamController<Iterable<ListItem<Comparable>>> _selectedItems$ctrl =
      StreamController<Iterable<ListItem<Comparable>>>.broadcast();
  final StreamController<String> _headerLabel$ctrl = StreamController<String>();
  final StreamController<bool> _openClose$ctrl =
      StreamController<bool>.broadcast();
  final StreamController<bool> _beforeDestroyChild$ctrl =
      StreamController<bool>.broadcast();
  final StreamController<ItemRendererEvent<dynamic, Comparable>>
      _itemRendererEvent$ctrl =
      StreamController<ItemRendererEvent<dynamic, Comparable>>.broadcast();

  StreamSubscription<String> _currentHeaderLabelSubscription;
  StreamSubscription<bool> _openCloseSubscription;
  StreamSubscription<Iterable<ListItem<Comparable>>> _selectedItemsSubscription;
  StreamSubscription<bool> _beforeDestroyChildSubscription;
  StreamSubscription<Iterable<ListItem<Comparable>>>
      _selectFirstElementOnEnterKeySubscription;

  bool _isClosedFromList = false;

  //-----------------------------
  // public properties
  //-----------------------------

  bool isOpen = false, isDropDownListShown = false;
  String currentHeaderLabel;

  //-----------------------------
  // constructor
  //-----------------------------

  DropDown(@Inject(Element) Element elementRef) : super(elementRef) {
    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override
  Stream<Entity> provideState() => Observable.combineLatest2(
      Observable(_selectedItems$ctrl.stream).startWith(selectedItems),
      Observable(_openClose$ctrl.stream)
          .startWith(isOpen)
          .distinct((vA, vB) => vA == vB),
      (Iterable<ListItem<Comparable>> items, bool isOpen) =>
          SerializableTuple2<bool, Iterable<ListItem<Comparable>>>()
            ..item1 = isOpen
            ..item2 = items);

  @override
  void receiveState(covariant Entity entity, StatePhase phase) {
    final tuple = entity as SerializableTuple2;
    final item1 = tuple.item1 as bool;
    final item2 = List<Entity>.from(tuple.item2 as Iterable<Entity>);
    final listCast = <ListItem<Comparable>>[];

    if (phase == StatePhase.REPLAY)
      scheduleMicrotask(() => _openClose$ctrl.add(item1));

    item2?.forEach((entity) => listCast.add(entity as ListItem<Comparable>));

    scheduleMicrotask(() {
      _selectedItems$ctrl.add(listCast);

      setSelectedItems(listCast);
    });
  }

  @override
  void ngAfterViewInit() => FormComponent.openFormComponents.add(this);

  @override
  Stream<bool> ngBeforeDestroyChild([List<dynamic> args]) async* {
    final completer = Completer<bool>();

    _beforeDestroyChildSubscription = Observable.race([
      beforeDestroyChild.stream.where((isDone) => isDone),
      onDestroy.map((_) => true)
    ]).take(1).listen(completer.complete);

    beforeDestroyChild.add(false);

    await completer.future;

    yield true;
  }

  @override
  void ngOnDestroy() {
    super.ngOnDestroy();

    _currentHeaderLabelSubscription?.cancel();
    _openCloseSubscription?.cancel();
    _selectedItemsSubscription?.cancel();
    _beforeDestroyChildSubscription?.cancel();
    _selectFirstElementOnEnterKeySubscription?.cancel();

    FormComponent.openFormComponents.remove(this);

    _selectedItems$ctrl.close();
    _headerLabel$ctrl.close();
    _openClose$ctrl.close();
    _beforeDestroyChild$ctrl.close();
    _itemRendererEvent$ctrl.close();
  }

  void clear() {
    _selectedItems$ctrl.add(const []);

    setSelectedItems(const []);
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void updateSelectedItemsCast(List<ListItem<Comparable>> items) =>
      updateSelectedItems(items?.cast<ListItem<Comparable>>());

  void setSelectedItems(Iterable<ListItem<Comparable>> value) =>
      setState(() => selectedItems = value);

  void setOpenOrClosed(bool value) {
    if (isOpen != value) setState(() => isOpen = value);
  }

  void _initStreams() {
    _currentHeaderLabelSubscription = Observable.combineLatest2(
        Observable(_headerLabel$ctrl.stream).startWith(''),
        Observable(_selectedItems$ctrl.stream).startWith(const []),
        (String label, Iterable<ListItem<Comparable>> selectedItems) =>
            Tuple2(label, selectedItems)).switchMap((tuple) {
      Stream<String> returnValue;

      if (updateHeaderLabelWithSelection &&
          tuple.item2 != null &&
          tuple.item2.isNotEmpty) {
        if (tuple.item2.length == 1) {
          if (labelHandler != null)
            return Observable.just(labelHandler(tuple.item2.first.data));

          return Observable<String>.just(null);
        } else {
          returnValue = Observable(Stream.fromIterable(tuple.item2))
              .flatMap((listItem) {
                if (labelHandler != null)
                  return Observable.just(labelHandler(listItem.data as String));

                return Observable<String>.just(null);
              })
              .bufferCount(tuple.item2.length)
              .map((list) => list.join(', '));
        }
      }

      return returnValue ??= Observable.just(tuple.item1);
    }).listen((headerLabel) {
      if (currentHeaderLabel != headerLabel)
        setState(() => currentHeaderLabel = headerLabel);
    });

    _openCloseSubscription = Observable(_openClose$ctrl.stream)
        .distinct((vA, vB) => vA == vB)
        .switchMap(_awaitCloseAnimation)
        .listen((isOpen) {
      setOpenOrClosed(isOpen);

      if (isOpen) {
        FormComponent.openFormComponents
            .where((component) => component != this && component is DropDown)
            .cast<DropDown>()
            .where((component) => component.isOpen)
            .forEach((component) => component.openOrClose());
      }
    });

    _selectedItemsSubscription = Observable.combineLatest2(
        Observable(_openClose$ctrl.stream)
            .startWith(isOpen)
            .distinct((vA, vB) => vA == vB)
            .switchMap(_awaitCloseAnimation),
        Observable(_selectedItems$ctrl.stream).startWith(const []),
        (bool isOpen, Iterable<ListItem<Comparable>> selectedItems) {
      if (!isOpen) return selectedItems;

      return null;
    }).where((selectedItems) => selectedItems != null).listen(setSelectedItems);

    _selectFirstElementOnEnterKeySubscription = elementRef.onKeyPress
        .where((_) => hasSelectableItems())
        .where((event) => event.keyCode == KeyCode.ENTER)
        .map((_) => [dataProvider.first])
        .listen(updateSelectedItems);
  }

  Stream<bool> _awaitCloseAnimation(bool isOpen) {
    if (isOpen) {
      final ctrl = StreamController<bool>();

      ctrl.onListen = () {
        ctrl.add(true);

        ctrl.close();
      };

      return ctrl.stream;
    }

    return ngBeforeDestroyChild().map((_) => isOpen);
  }

  bool _distinctSelectedItems(
      Iterable<ListItem<Comparable>> sA, Iterable<ListItem<Comparable>> sB) {
    if (sA == null && sB == null) return true;

    if (sA == null || sB == null) return false;

    if (sA.length != sB.length) return false;

    for (var i = 0, len = sA.length; i < len; i++) {
      final iA = sA.elementAt(i), iB = sB.elementAt(i);

      if (iA.data.compareTo(iB.data) != 0) return false;
    }

    return true;
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void close() {
    if (isOpen) openOrClose();
  }

  void openOrClose() => _openClose$ctrl.add(!isOpen);

  void openOrCloseFromHeader(MouseEvent event) {
    if (defaultHandler != null &&
        event.offset.x < (event.target as Element).client.width - 40) {
      defaultHandler();
    } else {
      if (_isClosedFromList)
        _isClosedFromList = false;
      else
        openOrClose();
    }
  }

  void closeFromList() {
    _isClosedFromList = true;

    Timer(const Duration(milliseconds: 200), () {
      _isClosedFromList = false;
    });

    openOrClose();
  }

  String getHierarchyOffset(ListItem<Comparable> listItem) {
    var offset = 0;
    var current = listItem;

    while (current.parent != null) {
      current = current.parent;

      offset += childOffset;
    }

    return '${offset}px';
  }

  void updateSelectedItems(Iterable<ListItem<Comparable>> items) {
    _selectedItems$ctrl.add(items);

    if (resetAfterSelection)
      window.animationFrame.whenComplete(() {
        if (!_selectedItems$ctrl.isClosed) _selectedItems$ctrl.add(const []);
      });
  }

  void handleItemRendererEvent(ItemRendererEvent<dynamic, Comparable> event) =>
      _itemRendererEvent$ctrl.add(event);

  bool hasSelectableItems() =>
      isOpen && dataProvider != null && dataProvider.isNotEmpty;
}
