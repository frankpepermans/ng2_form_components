library ng2_form_components.components.drop_down;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:dorm/dorm.dart';

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/list_renderer.dart';
import 'package:ng2_form_components/src/components/item_renderers/default_list_item_renderer.dart';
import 'package:ng2_form_components/src/components/list_item.dart';
import 'package:ng2_form_components/src/components/animation/tween.dart';
import 'package:ng2_form_components/src/components/interfaces/before_destroy_child.dart';

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart';

import 'package:ng2_state/ng2_state.dart' show SerializableTuple2, StatePhase;

@Component(
    selector: 'drop-down',
    templateUrl: 'drop_down.html',
    directives: const [ListRenderer, Tween],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class DropDown<T extends Comparable> extends FormComponent<T> implements OnChanges, OnDestroy, AfterViewInit, BeforeDestroyChild {

  //-----------------------------
  // input
  //-----------------------------

  LabelHandler _labelHandler;
  LabelHandler get labelHandler => _labelHandler;
  @Input() void set labelHandler(LabelHandler value) {
    _labelHandler = value;
  }

  Iterable<ListItem<T>> _dataProvider;
  Iterable<ListItem<T>> get dataProvider => _dataProvider;
  @Input() void set dataProvider(Iterable<ListItem<T>> value) {
    _dataProvider = value;
  }

  bool _updateHeaderLabelWithSelection = true;
  bool get updateHeaderLabelWithSelection => _updateHeaderLabelWithSelection;
  @Input() void set updateHeaderLabelWithSelection(bool value) {
    _updateHeaderLabelWithSelection = value;
  }

  Iterable<ListItem<T>> _selectedItems = <ListItem<T>>[];
  Iterable<ListItem<T>> get selectedItems => _selectedItems;
  @Input() void set selectedItems(Iterable<ListItem<T>> value) {
    _selectedItems = value;
  }

  String _headerLabel;
  String get headerLabel => _headerLabel;
  @Input() void set headerLabel(String value) {
    _headerLabel = value;
  }

  String _className = 'ng2-form-components-drop-down';
  String get className => _className;
  @Input() void set className(String value) {
    _className = value;

    cssMap = <String, bool>{value: true};
  }

  Map<String, bool> cssMap = const <String, bool>{'ng2-form-components-drop-down': true};

  bool _allowMultiSelection = false;
  bool get allowMultiSelection => _allowMultiSelection;
  @Input() void set allowMultiSelection(bool value) {
    _allowMultiSelection = value;
  }

  int _childOffset = 20;
  int get childOffset => _childOffset;
  @Input() void set childOffset(int value) {
    _childOffset = value;
  }

  ResolveRendererHandler _resolveRendererHandler = (_, [__]) => DefaultListItemRenderer;
  ResolveRendererHandler get resolveRendererHandler => _resolveRendererHandler;
  @Input() void set resolveRendererHandler(ResolveRendererHandler value) {
    _resolveRendererHandler = value;
  }

  Function _defaultHandler;
  Function get defaultHandler => _defaultHandler;
  @Input() void set defaultHandler(Function value) {
    _defaultHandler = value;
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output() Stream<Iterable<ListItem<T>>> get selectedItemsChanged => _selectedItems$ctrl.stream
    .distinct(_distinctSelectedItems);

  @override StreamController<bool> get beforeDestroyChild => _beforeDestroyChild$ctrl;

  @Output() Stream<ItemRendererEvent> get itemRendererEvent => _itemRendererEvent$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  final StreamController<Iterable<ListItem<T>>> _selectedItems$ctrl = new StreamController<Iterable<ListItem<T>>>.broadcast();
  final StreamController<String> _headerLabel$ctrl = new StreamController<String>();
  final StreamController<bool> _openClose$ctrl = new StreamController<bool>.broadcast();
  final StreamController<bool> _beforeDestroyChild$ctrl = new StreamController<bool>.broadcast();
  final StreamController<ItemRendererEvent> _itemRendererEvent$ctrl = new StreamController<ItemRendererEvent>.broadcast();

  StreamSubscription<String> _currentHeaderLabelSubscription;
  StreamSubscription<bool> _openCloseSubscription;
  StreamSubscription<Iterable<ListItem<T>>> _selectedItemsSubscription;
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

  DropDown(@Inject(ChangeDetectorRef) ChangeDetectorRef changeDetector) : super(changeDetector) {
    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<Entity> provideState() => new rx.Observable<SerializableTuple2<bool, Iterable<ListItem<T>>>>.combineLatest([
      rx.observable(_selectedItems$ctrl.stream)
        .startWith(<Iterable<ListItem<T>>>[selectedItems]),
      rx.observable(_openClose$ctrl.stream)
        .startWith(<bool>[isOpen])
        .distinct((bool vA, bool vB) => vA == vB)
    ], (Iterable<ListItem<T>> items, bool isOpen) => new SerializableTuple2<bool, Iterable<ListItem<T>>>()
      ..item1 = isOpen
      ..item2 = items);

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple2<bool, Iterable<ListItem<T>>> tuple = entity as SerializableTuple2<bool, Iterable<ListItem<T>>>;

    _selectedItems$ctrl.add(tuple.item2);

    if (phase == StatePhase.REPLAY) scheduleMicrotask(() => _openClose$ctrl.add(tuple.item1));

    setSelectedItems(tuple.item2);
  }

  @override void ngOnChanges(Map<String, SimpleChange> changes) {
    if (changes.containsKey('headerLabel')) {
      _headerLabel$ctrl.add(headerLabel);
      _selectedItems$ctrl.add(const []);
    }

    if (changes.containsKey('selectedItems')) _selectedItems$ctrl.add(selectedItems);
  }

  @override void ngAfterViewInit() => FormComponent.openFormComponents.add(this);

  @override Stream<bool> ngBeforeDestroyChild([List args]) async* {
    final Completer<bool> completer = new Completer<bool>();

    _beforeDestroyChildSubscription = new rx.Observable<bool>.merge([
      beforeDestroyChild.stream
        .where((bool isDone) => isDone),
      onDestroy
        .map((_) => true)
    ])
      .take(1)
      .listen((bool value) => completer.complete(value));

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
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void setSelectedItems(Iterable<ListItem<T>> value) {
    selectedItems = value;

    changeDetector.markForCheck();
  }

  void setOpenOrClosed(bool value) {
    isOpen = value;

    changeDetector.markForCheck();
  }

  void _initStreams() {
    _currentHeaderLabelSubscription = new rx.Observable.combineLatest(<Stream>[
      rx.observable(_headerLabel$ctrl.stream).startWith(const <String>['']),
      rx.observable(_selectedItems$ctrl.stream).startWith(const [])
    ], (String label, Iterable<ListItem<T>> selectedItems) {
      if (updateHeaderLabelWithSelection && selectedItems != null && selectedItems.isNotEmpty) {
        return (selectedItems.length == 1) ?
          labelHandler(selectedItems.first.data) :
          selectedItems.map((ListItem<T> listItem) => labelHandler(listItem.data)).join(', ');
      }

      return label;
    }).listen((String headerLabel) {
      currentHeaderLabel = headerLabel;

      changeDetector.markForCheck();
    }) as StreamSubscription<String>;

    _openCloseSubscription = rx.observable(_openClose$ctrl.stream)
      .distinct((bool vA, bool vB) => vA == vB)
      .flatMapLatest(_awaitCloseAnimation)
      .listen((bool isOpen) {
        setOpenOrClosed(isOpen);

        if (isOpen) {
          FormComponent.openFormComponents
            .where((FormComponent component) => (component != this && component is DropDown && component.isOpen))
            .forEach((FormComponent component) => (component as DropDown).openOrClose());
        }
      });

    _selectedItemsSubscription = new rx.Observable<Iterable<ListItem<T>>>.combineLatest([
      rx.observable(_openClose$ctrl.stream)
        .startWith(<bool>[isOpen])
        .distinct((bool vA, bool vB) => vA == vB)
        .flatMapLatest(_awaitCloseAnimation),
      rx.observable(_selectedItems$ctrl.stream).startWith(<ListItem<T>>[])
    ], (bool isOpen, Iterable<ListItem<T>> selectedItems) {
      if (!isOpen) return selectedItems;

      return null;
    })
      .where((Iterable<ListItem<T>> selectedItems) => selectedItems != null)
      .listen(setSelectedItems);
  }

  Stream<bool> _awaitCloseAnimation(bool isOpen) {
    if (isOpen) {
      final StreamController<bool> ctrl = new StreamController<bool>();

      ctrl.onListen = () => ctrl.add(true);

      return ctrl.stream;
    }

    return ngBeforeDestroyChild().map((_) => isOpen);
  }

  bool _distinctSelectedItems(Iterable<ListItem<T>> sA, Iterable<ListItem<T>> sB) {
    if (sA == null && sB == null) return true;

    if (sA == null || sB == null) return false;

    if (sA.length != sB.length) return false;

    for (int i=0, len = sA.length; i<len; i++) {
      final ListItem<T> iA = sA.elementAt(i), iB = sB.elementAt(i);

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
    if (defaultHandler != null && event.offset.x < (event.target as Element).client.width - 40) {
      defaultHandler();
    } else {
      if (_isClosedFromList) _isClosedFromList = false;
      else openOrClose();
    }
  }

  void closeFromList() {
    _isClosedFromList = true;

    new Timer(const Duration(milliseconds: 200), () {
      _isClosedFromList = false;
    });

    openOrClose();
  }

  String getHierarchyOffset(ListItem<T> listItem) {
    int offset = 0;

    while (listItem.parent != null) {
      listItem = listItem.parent;

      offset += childOffset;
    }

    return '${offset}px';
  }

  void updateSelectedItems(Iterable<ListItem<T>> items) => _selectedItems$ctrl.add(items);

  void handleItemRendererEvent(ItemRendererEvent event) => _itemRendererEvent$ctrl.add(event);

}