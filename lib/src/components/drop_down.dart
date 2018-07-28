library ng2_form_components.components.drop_down;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;
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
    directives: const <dynamic>[ListRenderer, Tween, coreDirectives],
    pipes: const <dynamic>[commonPipes],
    providers: const <dynamic>[StateService],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class DropDown extends FormComponent
    implements OnDestroy, AfterViewInit, BeforeDestroyChild {
  //-----------------------------
  // input
  //-----------------------------

  LabelHandler<Comparable<dynamic>> _labelHandler;
  LabelHandler<Comparable<dynamic>> get labelHandler => _labelHandler;
  @Input()
  set labelHandler(LabelHandler<Comparable<dynamic>> value) {
    if (_labelHandler != value) setState(() => _labelHandler = value);
  }

  List<ListItem<Comparable<dynamic>>> get dataProviderCast =>
      dataProvider?.toList()?.cast<ListItem<Comparable<dynamic>>>();

  Iterable<ListItem<Comparable<dynamic>>> _dataProvider;
  Iterable<ListItem<Comparable<dynamic>>> get dataProvider => _dataProvider;
  @Input()
  set dataProvider(Iterable<ListItem<Comparable<dynamic>>> value) {
    if (_dataProvider != value) setState(() => _dataProvider = value);
  }

  bool _updateHeaderLabelWithSelection = true;
  bool get updateHeaderLabelWithSelection => _updateHeaderLabelWithSelection;
  @Input()
  set updateHeaderLabelWithSelection(bool value) {
    if (_updateHeaderLabelWithSelection != value)
      setState(() => _updateHeaderLabelWithSelection = value);
  }

  List<ListItem<Comparable<dynamic>>> get selectedItemsCast =>
      selectedItems?.toList()?.cast<ListItem<Comparable<dynamic>>>();

  Iterable<ListItem<Comparable<dynamic>>> _selectedItems =
      <ListItem<Comparable<dynamic>>>[];
  Iterable<ListItem<Comparable<dynamic>>> get selectedItems => _selectedItems;
  @Input()
  set selectedItems(Iterable<ListItem<Comparable<dynamic>>> value) {
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
  Stream<Iterable<ListItem<Comparable<dynamic>>>> get selectedItemsChanged =>
      _selectedItems$ctrl.stream.distinct(_distinctSelectedItems);

  @override
  StreamController<bool> get beforeDestroyChild => _beforeDestroyChild$ctrl;

  @Output()
  Stream<ItemRendererEvent<dynamic, Comparable<dynamic>>>
      get itemRendererEvent => _itemRendererEvent$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  final StreamController<Iterable<ListItem<Comparable<dynamic>>>>
      _selectedItems$ctrl =
      new StreamController<Iterable<ListItem<Comparable<dynamic>>>>.broadcast();
  final StreamController<String> _headerLabel$ctrl =
      new StreamController<String>();
  final StreamController<bool> _openClose$ctrl =
      new StreamController<bool>.broadcast();
  final StreamController<bool> _beforeDestroyChild$ctrl =
      new StreamController<bool>.broadcast();
  final StreamController<ItemRendererEvent<dynamic, Comparable<dynamic>>>
      _itemRendererEvent$ctrl = new StreamController<
          ItemRendererEvent<dynamic, Comparable<dynamic>>>.broadcast();

  StreamSubscription<String> _currentHeaderLabelSubscription;
  StreamSubscription<bool> _openCloseSubscription;
  StreamSubscription<Iterable<ListItem<Comparable<dynamic>>>>
      _selectedItemsSubscription;
  StreamSubscription<bool> _beforeDestroyChildSubscription;

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
  Stream<Entity> provideState() => rx.Observable.combineLatest2(
      new rx.Observable<Iterable<ListItem<Comparable<dynamic>>>>(
              _selectedItems$ctrl.stream)
          .startWith(selectedItems),
      new rx.Observable<bool>(_openClose$ctrl.stream)
          .startWith(isOpen)
          .distinct((bool vA, bool vB) => vA == vB),
      (Iterable<ListItem<Comparable<dynamic>>> items, bool isOpen) =>
          new SerializableTuple2<bool,
              Iterable<ListItem<Comparable<dynamic>>>>()
            ..item1 = isOpen
            ..item2 = items);

  @override
  void receiveState(covariant Entity entity, StatePhase phase) {
    final SerializableTuple2 tuple = entity as SerializableTuple2;
    final bool item1 = tuple.item1;
    final Iterable<Entity> item2 = new List<Entity>.from(tuple.item2);

    final List<ListItem<Comparable<dynamic>>> listCast =
        <ListItem<Comparable<dynamic>>>[];

    if (phase == StatePhase.REPLAY)
      scheduleMicrotask(() => _openClose$ctrl.add(item1));

    item2?.forEach((Entity entity) =>
        listCast.add(entity as ListItem<Comparable<dynamic>>));

    scheduleMicrotask(() {
      _selectedItems$ctrl.add(listCast);

      setSelectedItems(listCast);
    });
  }

  @override
  void ngAfterViewInit() => FormComponent.openFormComponents.add(this);

  @override
  Stream<bool> ngBeforeDestroyChild([List<dynamic> args]) async* {
    final Completer<bool> completer = new Completer<bool>();

    _beforeDestroyChildSubscription =
        new rx.Observable<bool>.race(<Stream<bool>>[
      beforeDestroyChild.stream.where((bool isDone) => isDone),
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

  void updateSelectedItemsCast(List<ListItem<Comparable<dynamic>>> items) =>
      updateSelectedItems(items?.cast<ListItem<Comparable<dynamic>>>());

  void setSelectedItems(Iterable<ListItem<Comparable<dynamic>>> value) =>
      setState(() => selectedItems = value);

  void setOpenOrClosed(bool value) {
    if (isOpen != value) setState(() => isOpen = value);
  }

  void _initStreams() {
    _currentHeaderLabelSubscription = rx.Observable.combineLatest2(
        new rx.Observable<String>(_headerLabel$ctrl.stream).startWith(''),
        new rx.Observable<Iterable<ListItem<Comparable<dynamic>>>>(
                _selectedItems$ctrl.stream)
            .startWith(const []),
        (String label, Iterable<ListItem<Comparable<dynamic>>> selectedItems) =>
            new Tuple2<String, Iterable<ListItem<Comparable<dynamic>>>>(
                label, selectedItems)).switchMap(
        (Tuple2<String, Iterable<ListItem<Comparable<dynamic>>>> tuple) {
      Stream<String> returnValue;

      if (updateHeaderLabelWithSelection &&
          tuple.item2 != null &&
          tuple.item2.isNotEmpty) {
        if (tuple.item2.length == 1) {
          if (labelHandler != null)
            return new rx.Observable<String>.just(
                labelHandler(tuple.item2.first.data));

          return new rx.Observable<String>.just(null);
        } else {
          returnValue = new rx.Observable<ListItem<Comparable<dynamic>>>(
                  new Stream<ListItem<Comparable<dynamic>>>.fromIterable(
                      tuple.item2))
              .flatMap((ListItem<Comparable<dynamic>> listItem) {
                if (labelHandler != null)
                  return rx.Observable<String>.just(
                      labelHandler(listItem.data));

                return new rx.Observable<String>.just(null);
              })
              .bufferCount(tuple.item2.length)
              .map((Iterable<String> list) => list.join(', '));
        }
      }

      return returnValue ??= new rx.Observable<String>.just(tuple.item1);
    }).listen((String headerLabel) {
      if (currentHeaderLabel != headerLabel)
        setState(() => currentHeaderLabel = headerLabel);
    });

    _openCloseSubscription = new rx.Observable<bool>(_openClose$ctrl.stream)
        .distinct((bool vA, bool vB) => vA == vB)
        .switchMap(_awaitCloseAnimation)
        .listen((bool isOpen) {
      setOpenOrClosed(isOpen);

      if (isOpen) {
        FormComponent.openFormComponents
            .where((FormComponent component) =>
                component != this && component is DropDown)
            .map((FormComponent component) => component as DropDown)
            .where((DropDown component) => component.isOpen)
            .forEach((FormComponent component) =>
                (component as DropDown).openOrClose());
      }
    });

    _selectedItemsSubscription =
        rx.Observable.combineLatest2(
                new rx.Observable<bool>(_openClose$ctrl.stream)
                    .startWith(isOpen)
                    .distinct((bool vA, bool vB) => vA == vB)
                    .switchMap(_awaitCloseAnimation),
                new rx.Observable<Iterable<ListItem<Comparable<dynamic>>>>(
                        _selectedItems$ctrl.stream)
                    .startWith(const []),
                (bool isOpen,
                    Iterable<ListItem<Comparable<dynamic>>> selectedItems) {
      if (!isOpen) return selectedItems;

      return null;
    })
            .where((Iterable<ListItem<Comparable<dynamic>>> selectedItems) =>
                selectedItems != null)
            .listen(setSelectedItems);
  }

  Stream<bool> _awaitCloseAnimation(bool isOpen) {
    if (isOpen) {
      final StreamController<bool> ctrl = new StreamController<bool>();

      ctrl.onListen = () {
        ctrl.add(true);

        ctrl.close();
      };

      return ctrl.stream;
    }

    return ngBeforeDestroyChild().map((_) => isOpen);
  }

  bool _distinctSelectedItems(Iterable<ListItem<Comparable<dynamic>>> sA,
      Iterable<ListItem<Comparable<dynamic>>> sB) {
    if (sA == null && sB == null) return true;

    if (sA == null || sB == null) return false;

    if (sA.length != sB.length) return false;

    for (int i = 0, len = sA.length; i < len; i++) {
      final ListItem<Comparable<dynamic>> iA = sA.elementAt(i),
          iB = sB.elementAt(i);

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

    new Timer(const Duration(milliseconds: 200), () {
      _isClosedFromList = false;
    });

    openOrClose();
  }

  String getHierarchyOffset(ListItem<Comparable<dynamic>> listItem) {
    int offset = 0;
    ListItem<Comparable<dynamic>> current = listItem;

    while (current.parent != null) {
      current = current.parent;

      offset += childOffset;
    }

    return '${offset}px';
  }

  void updateSelectedItems(Iterable<ListItem<Comparable<dynamic>>> items) {
    _selectedItems$ctrl.add(items);

    if (resetAfterSelection)
      window.animationFrame.whenComplete(() {
        if (!_selectedItems$ctrl.isClosed) _selectedItems$ctrl.add(const []);
      });
  }

  void handleItemRendererEvent(
          ItemRendererEvent<dynamic, Comparable<dynamic>> event) =>
      _itemRendererEvent$ctrl.add(event);
}
