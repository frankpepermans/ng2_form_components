library ng2_form_components.components.hierarchy;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx show Observable, observable;
import 'package:dorm/dorm.dart' show Entity;
import 'package:tuple/tuple.dart' show Tuple2;
import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/interfaces/before_destroy_child.dart' show BeforeDestroyChild;

import 'package:ng2_form_components/src/components/internal/form_component.dart' show LabelHandler;
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart' show ListItemRenderer, ListDragDropHandler;
import 'package:ng2_form_components/src/components/internal/drag_drop_list_item_renderer.dart' show DragDropListItemRenderer;

import 'package:ng2_form_components/src/components/list_renderer.dart' show ListRenderer, ClearSelectionWhereHandler, NgForTracker;
import 'package:ng2_form_components/src/components/list_item.g.dart' show ListItem;

import 'package:ng2_form_components/src/components/animation/hierarchy_animation.dart' show HierarchyAnimation;

import 'package:ng2_form_components/src/components/item_renderers/default_hierarchy_list_item_renderer.dart' show DefaultHierarchyListItemRenderer;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ItemRendererEvent, ListRendererEvent, ListRendererService;

import 'package:ng2_state/ng2_state.dart' show State, SerializableTuple1, SerializableTuple3, StatePhase, StateService, StatefulComponent;

import 'package:ng2_form_components/src/components/internal/form_component.dart' show ResolveChildrenHandler, ResolveRendererHandler;

typedef bool ShouldOpenDiffer(ListItem<Comparable<dynamic>> itemA, ListItem<Comparable<dynamic>> itemB);

@Component(
    selector: 'hierarchy',
    templateUrl: 'hierarchy.html',
    directives: const <Type>[State, Hierarchy, HierarchyAnimation, ListItemRenderer, DragDropListItemRenderer],
    providers: const <dynamic>[StateService, const Provider(StatefulComponent, useExisting: Hierarchy)],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false
)
class Hierarchy<T extends Comparable<dynamic>> extends ListRenderer<T> implements OnDestroy, AfterViewInit, BeforeDestroyChild {

  @ViewChild('subHierarchy') Hierarchy<Comparable<dynamic>> subHierarchy;

  @override @ViewChild('scrollPane')set scrollPane(ElementRef value) {
    super.scrollPane = value;
  }

  //-----------------------------
  // input
  //-----------------------------

  @override @Input() set labelHandler(LabelHandler value) {
    super.labelHandler = value;
  }

  @override @Input() set dragDropHandler(ListDragDropHandler value) {
    super.dragDropHandler = value;
  }

  @override @Input() set dataProvider(List<ListItem<T>> value) {
    forceAnimateOnOpen = false;

    _cleanupOpenMap();
    _cleanUpListeners();

    super.dataProvider = value;
  }

  @override @Input() set selectedItems(List<ListItem<T>> value) {
    super.selectedItems = value;
  }

  @override @Input() set allowMultiSelection(bool value) {
    super.allowMultiSelection = value;
  }

  @override bool get moveSelectionOnTop => false;

  @override @Input() set childOffset(int value) {
    super.childOffset = value;
  }

  @override @Input() set rendererEvents(List<ListRendererEvent<dynamic, Comparable<dynamic>>> value) {
    super.rendererEvents = value;
  }

  @override @Input() set pageOffset(int value) {
    super.pageOffset = value;
  }

  @override @Input() set listRendererService(ListRendererService value) {
    super.listRendererService = value;

    _listRendererService$ctrl.add(value);

    value?.triggerEvent(new ItemRendererEvent<Hierarchy<Comparable<dynamic>>, T>('childRegistry', null, this));
  }

  int _level = 0;
  int get level => _level;
  @Input() set level(int value) {
    setState(() => _level = value);
  }

  bool _autoOpenChildren = false;
  bool get autoOpenChildren => _autoOpenChildren;
  @Input() set autoOpenChildren(bool value) {
    setState(() => _autoOpenChildren = value);
  }

  List<ListItem<Comparable<dynamic>>> _hierarchySelectedItems;
  List<ListItem<Comparable<dynamic>>> get hierarchySelectedItems => _hierarchySelectedItems;
  @Input() set hierarchySelectedItems(List<ListItem<Comparable<dynamic>>> value) {
    setState(() => _hierarchySelectedItems = value);

    if (value != null && value.isNotEmpty) {
      value.forEach((ListItem<Comparable<dynamic>> listItem) {
        listRendererService.rendererSelection$
            .take(1)
            .map((_) => new ItemRendererEvent<bool, T>('selection', listItem as ListItem<T>, true))
            .listen(listRendererService?.triggerEvent);

        listRendererService?.triggerSelection(listItem);
      });
    }
  }

  List<int> _levelsThatBreak = const [];
  List<int> get levelsThatBreak => _levelsThatBreak;
  @Input() set levelsThatBreak(List<int> value) {
    setState(() => _levelsThatBreak = value);
  }

  @override @Input() set ngForTracker(NgForTracker value) {
    super.ngForTracker = value;
  }

  ResolveChildrenHandler _resolveChildrenHandler;
  ResolveChildrenHandler get resolveChildrenHandler => _resolveChildrenHandler;
  @Input() set resolveChildrenHandler(ResolveChildrenHandler value) {
    setState(() => _resolveChildrenHandler = value);
  }

  bool _allowToggle = false;
  bool get allowToggle => _allowToggle;
  @Input() set allowToggle(bool value) {
    if (_allowToggle != value) setState(() => _allowToggle = value);
  }

  ShouldOpenDiffer _shouldOpenDiffer = (ListItem<Comparable<dynamic>> itemA, ListItem<Comparable<dynamic>> itemB) => itemA.compareTo(itemB) == 0;
  ShouldOpenDiffer get shouldOpenDiffer => _shouldOpenDiffer;
  @Input() set shouldOpenDiffer(ShouldOpenDiffer value) {
    setState(() => _shouldOpenDiffer = value);
  }

  @override @Input() set resolveRendererHandler(ResolveRendererHandler value) {
    super.resolveRendererHandler = value;
  }

  //-----------------------------
  // output
  //-----------------------------

  @override @Output() rx.Observable<List<ListItem<T>>> get selectedItemsChanged => rx.observable(_selection$) as rx.Observable<List<ListItem<T>>>;
  @override @Output() Stream<bool> get requestClose => super.requestClose;
  @override @Output() Stream<bool> get scrolledToBottom => super.scrolledToBottom;
  @override @Output() Stream<ItemRendererEvent<dynamic, Comparable<dynamic>>> get itemRendererEvent => super.itemRendererEvent;

  @override StreamController<int> get beforeDestroyChild => _beforeDestroyChild$ctrl;

  //-----------------------------
  // private properties
  //-----------------------------

  final Map<ListItem<T>, List<ListItem<T>>> _resolvedChildren = <ListItem<T>, List<ListItem<T>>>{};

  final StreamController<Tuple2<Hierarchy<Comparable<dynamic>>, bool>> _childHierarchies$ctrl = new StreamController<Tuple2<Hierarchy<Comparable<dynamic>>, bool>>.broadcast();
  final StreamController<ClearSelectionWhereHandler> _clearChildHierarchies$ctrl = new StreamController<ClearSelectionWhereHandler>.broadcast();
  final StreamController<List<Hierarchy<Comparable<dynamic>>>> _childHierarchyList$ctrl = new StreamController<List<Hierarchy<Comparable<dynamic>>>>.broadcast();
  final StreamController<Map<Hierarchy<Comparable<dynamic>>, List<ListItem<Comparable<dynamic>>>>> _selection$Ctrl = new StreamController<Map<Hierarchy<Comparable<dynamic>>, List<ListItem<Comparable<dynamic>>>>>.broadcast();
  final StreamController<List<ListItem<T>>> _openListItems$Ctrl = new StreamController<List<ListItem<T>>>.broadcast();
  final StreamController<int> _beforeDestroyChild$ctrl = new StreamController<int>.broadcast();
  final StreamController<bool> _domModified$ctrl = new StreamController<bool>.broadcast();
  final StreamController<ListRendererService> _listRendererService$ctrl = new StreamController<ListRendererService>();

  Map<ListItem<T>, bool> _isOpenMap = <ListItem<T>, bool>{};

  StreamSubscription<dynamic> _windowMutationListener;
  StreamSubscription<ItemRendererEvent<dynamic, Comparable<dynamic>>> _eventSubscription;
  StreamSubscription<Tuple2<List<Hierarchy<Comparable<dynamic>>>, ClearSelectionWhereHandler>> _clearChildHierarchiesSubscription;
  StreamSubscription<Tuple2<Hierarchy<Comparable<dynamic>>, List<Hierarchy<Comparable<dynamic>>>>> _registerChildHierarchySubscription;
  StreamSubscription<Map<Hierarchy<Comparable<dynamic>>, List<ListItem<T>>>> _selectionBuilderSubscription;

  Stream<List<ListItem<Comparable<dynamic>>>> _selection$;

  bool forceAnimateOnOpen = false;

  List<ListItem<T>> _receivedSelection;

  final Map<ListItem<T>, StreamSubscription<Tuple2<Map<ListItem<T>, bool>, int>>> _onBeforeDestroyChildSubscriptions = <ListItem<T>, StreamSubscription<Tuple2<Map<ListItem<T>, bool>, int>>>{};

  //-----------------------------
  // constructor
  //-----------------------------

  Hierarchy(
    @Inject(ElementRef) ElementRef element) : super(element) {
      super.resolveRendererHandler = (int level, [_]) => DefaultHierarchyListItemRenderer;

      _initStreams();
    }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<Entity> provideState() {
    return rx.Observable.combineLatest3(
      rx.observable(super.provideState())
          .startWith(new SerializableTuple1<int>()..item1 = 0),
      internalSelectedItemsChanged.startWith(const []),
      rx.observable(_openListItems$Ctrl.stream)
        .where((_) => !autoOpenChildren)
    , (Entity scrollPosition, List<ListItem<T>> selectedItems, List<ListItem<T>> openItems) =>
      new SerializableTuple3<int, List<ListItem<T>>, List<ListItem<T>>>()
        ..item1 = (scrollPosition as SerializableTuple1<int>)?.item1
        ..item2 = selectedItems
        ..item3 = openItems).asBroadcastStream()
    .startWith(new SerializableTuple3<int, List<ListItem<T>>, List<ListItem<T>>>()
      ..item1 = 0
      ..item2 = const []
      ..item3 = const []);
  }

  @override void ngAfterViewInit() {
    super.ngAfterViewInit();

    if (hierarchySelectedItems == null || hierarchySelectedItems.isEmpty) _processIncomingSelectedState(_receivedSelection);

    if (hierarchySelectedItems != null) setState(() => hierarchySelectedItems = null);
  }

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple3<int, List<Entity>, List<Entity>> tuple = entity as SerializableTuple3<int, List<Entity>, List<Entity>>;
    final List<ListItem<T>> listCast = <ListItem<T>>[];
    final List<ListItem<T>> listCast2 = <ListItem<T>>[];

    tuple.item2?.forEach((Entity entity) => listCast.add(entity as ListItem<T>));

    super.receiveState(new SerializableTuple1<int>()
      ..item1 = tuple.item1, phase);

    _receivedSelection = listCast;

    tuple.item3?.forEach((Entity entity) {
      final ListItem<T> listItem = entity as ListItem<T>;
      _isOpenMap[listItem] = true;

      listCast2.add(listItem);
    });

    if (listCast2.isNotEmpty) _openListItems$Ctrl.add(listCast2);

    listRendererService.notifyIsOpenChange();

    if (tuple.item3 != null && tuple.item3.isNotEmpty) deliverStateChanges();
  }

  @override Stream<int> ngBeforeDestroyChild([List<dynamic> args]) {
    final List<int> argsCast = args as List<int>;

    beforeDestroyChild.add(argsCast.first);

    return new rx.Observable<int>.amb(<Stream<int>>[
      beforeDestroyChild.stream
        .where((int index) => index == argsCast.first),
      onDestroy
        .map((_) => 0)
    ])
      .take(1)
      .map((_) => argsCast.first);
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();

    _windowMutationListener?.cancel();
    _eventSubscription?.cancel();
    _clearChildHierarchiesSubscription?.cancel();
    _registerChildHierarchySubscription?.cancel();
    _selectionBuilderSubscription?.cancel();

    _cleanUpListeners();

    _childHierarchies$ctrl.close();
    _clearChildHierarchies$ctrl.close();
    _childHierarchyList$ctrl.close();
    _selection$Ctrl.close();
    _openListItems$Ctrl.close();
    _beforeDestroyChild$ctrl.close();
    _domModified$ctrl.close();
    _listRendererService$ctrl.close();
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initStreams() {
    _windowMutationListener = domChange$
      .asyncMap((_) => window.animationFrame)
      .listen(_handleDomChange);

    _eventSubscription = rx.observable(_listRendererService$ctrl.stream)
      .flatMapLatest((ListRendererService service) => service.event$)
      .listen(_handleItemRendererEvent);

    _clearChildHierarchiesSubscription = rx.Observable.combineLatest2(
      _childHierarchyList$ctrl.stream,
      _clearChildHierarchies$ctrl.stream
    , (List<Hierarchy<Comparable<dynamic>>> childHierarchies, ClearSelectionWhereHandler handler) => new Tuple2<List<Hierarchy<Comparable<dynamic>>>, ClearSelectionWhereHandler>(childHierarchies, handler))
      .listen((Tuple2<List<Hierarchy<Comparable<dynamic>>>, ClearSelectionWhereHandler> tuple) => tuple.item1.forEach((Hierarchy<Comparable<dynamic>> childHierarchy) => childHierarchy.clearSelection(tuple.item2)));

    _registerChildHierarchySubscription = rx.Observable.zip2(
      _childHierarchies$ctrl.stream,
      _childHierarchyList$ctrl.stream
    , (Tuple2<Hierarchy<Comparable<dynamic>>, bool> childHierarchy, List<Hierarchy<Comparable<dynamic>>> hierarchies) {
      final List<Hierarchy<Comparable<dynamic>>> clone = hierarchies.toList();

      if (childHierarchy.item2) clone.add(childHierarchy.item1);
      else clone.remove(childHierarchy.item1);

      return new Tuple2<Tuple2<Hierarchy<Comparable<dynamic>>, bool>, List<Hierarchy<Comparable<dynamic>>>>(childHierarchy, new List<Hierarchy<Comparable<dynamic>>>.unmodifiable(clone));
    })
      .call(onData:(Tuple2<Tuple2<Hierarchy<Comparable<dynamic>>, bool>, List<Hierarchy<Comparable<dynamic>>>> tuple) => _childHierarchyList$ctrl.add(tuple.item2))
      .where((Tuple2<Tuple2<Hierarchy<Comparable<dynamic>>, bool>, List<Hierarchy<Comparable<dynamic>>>> tuple) => tuple.item1.item2)
      .map((Tuple2<Tuple2<Hierarchy<Comparable<dynamic>>, bool>, List<Hierarchy<Comparable<dynamic>>>> tuple) => new Tuple2<Hierarchy<Comparable<dynamic>>, List<Hierarchy<Comparable<dynamic>>>>(tuple.item1.item1, tuple.item2))
      .flatMap((Tuple2<Hierarchy<Comparable<dynamic>>, List<Hierarchy<Comparable<dynamic>>>> tuple) => tuple.item1.onDestroy.take(1).map((_) => tuple))
      .listen((Tuple2<Hierarchy<Comparable<dynamic>>, List<Hierarchy<Comparable<dynamic>>>> tuple) => _childHierarchies$ctrl.add(new Tuple2<Hierarchy<Comparable<dynamic>>, bool>(tuple.item1, false)));

    _selectionBuilderSubscription = rx.Observable.zip2(
      rx.observable(_selection$Ctrl.stream).startWith(<Hierarchy<Comparable<dynamic>>, List<ListItem<T>>>{}),
      rx.observable(_childHierarchyList$ctrl.stream)
        .flatMapLatest((List<Hierarchy<Comparable<dynamic>>> hierarchies) => new rx.Observable<Tuple2<Hierarchy<Comparable<dynamic>>, List<ListItem<Comparable<dynamic>>>>>
          .merge((new List<Hierarchy<Comparable<dynamic>>>.from(hierarchies)..add(this))
          .map((Hierarchy<Comparable<dynamic>> hierarchy) => hierarchy.internalSelectedItemsChanged
            .map((List<ListItem<Comparable<dynamic>>> selectedItems) => new Tuple2<Hierarchy<Comparable<dynamic>>, List<ListItem<Comparable<dynamic>>>>(hierarchy, selectedItems)))))
    , (Map<Hierarchy<Comparable<dynamic>>, List<ListItem<Comparable<dynamic>>>> selectedItems, Tuple2<Hierarchy<Comparable<dynamic>>, List<ListItem<Comparable<dynamic>>>> tuple) {
      if (tuple.item1.stateGroup != null && tuple.item1.stateGroup.isNotEmpty && tuple.item1.stateId != null && tuple.item1.stateId.isNotEmpty) {
        Hierarchy<Comparable<dynamic>> match;

        selectedItems.forEach((Hierarchy<Comparable<dynamic>> hierarchy, _) {
          if (hierarchy.stateGroup == tuple.item1.stateGroup && hierarchy.stateId == tuple.item1.stateId) match = hierarchy;
        });

        if (match != null && match != tuple.item1) selectedItems.remove(match);
      }

      selectedItems[tuple.item1] = tuple.item2;

      return selectedItems;
    })
      .where((_) => level == 0)
      .listen(_selection$Ctrl.add);

    _selection$ = _selection$Ctrl.stream
      .map((Map<Hierarchy<Comparable<dynamic>>, List<ListItem<Comparable<dynamic>>>> map) {
        final List<ListItem<Comparable<dynamic>>> fold = <ListItem<Comparable<dynamic>>>[];

        map.values.forEach(fold.addAll);

        return fold;
      });

    _childHierarchyList$ctrl.add(const []);
    _selection$Ctrl.add(<Hierarchy<Comparable<dynamic>>, List<ListItem<T>>>{});
    _listRendererService$ctrl.add(listRendererService);
  }

  void _handleItemRendererEvent(ItemRendererEvent<dynamic, Comparable<dynamic>> event) {
    if (event?.type == 'openRecursively') {
      final ItemRendererEvent<bool, Comparable<dynamic>> eventCast = event as ItemRendererEvent<bool, Comparable<dynamic>>;

      if (eventCast.data != null) {
        for (int i=0, len=dataProvider.length; i<len; i++) {
          ListItem<T> entry = dataProvider.elementAt(i);

          if (shouldOpenDiffer(eventCast.listItem, entry) && !isOpen(entry)) toggleChildren(entry, i);
        }
      }

      deliverStateChanges();
    }
  }

  void _handleDomChange(dynamic _) {
    if (!_domModified$ctrl.isClosed) _domModified$ctrl.add(true);
  }

  void _processIncomingSelectedState(List<ListItem<T>> selectedItems) {
    if (selectedItems != null && selectedItems.isNotEmpty) {
      if (level == 0) selectedItems.forEach(handleSelection);
      else {
        new rx.Observable<dynamic>.amb(<Stream<dynamic>>[
          rx.observable(_domModified$ctrl.stream)
            .asyncMap((_) => window.animationFrame)
            .debounce(const Duration(milliseconds: 50)),
          new Stream<dynamic>.periodic(const Duration(milliseconds: 200))
        ])
          .take(1)
          .listen((_) {
            selectedItems.forEach((ListItem<Comparable<dynamic>> listItem) {
              rx.observable(listRendererService.rendererSelection$)
                  .take(1)
                  .map((_) => new ItemRendererEvent<bool, T>('selection', listItem, true))
                  .listen(handleRendererEvent);

              listRendererService.triggerSelection(listItem);
            });

            observer.disconnect();
          });
      }
    }
  }

  //-----------------------------
  // template methods
  //-----------------------------

  String getStateId(int index) {
    if (stateId != null) return '${stateId}_${level}_$index';

    return '${index}_$level';
  }

  Future<Null> autoOpenChildrenNow() {
    int index = 0;

    return forEachAsync(dataProvider, (ListItem<T> listItem) async {
      if (!isOpen(listItem)) {
        await maybeToggleChildren(listItem, index);

        if (subHierarchy != null) await subHierarchy.autoOpenChildrenNow();

        deliverStateChanges();
      }

      index++;

      return new Future<Null>.value();
    });
  }

  Future<Null> autoCloseChildrenNow() {
    int index = 0;

    return forEachAsync(dataProvider, (ListItem<T> listItem) async {
      if (isOpen(listItem)) {
        if (subHierarchy != null) await subHierarchy.autoCloseChildrenNow();

        await maybeToggleChildren(listItem, index);

        deliverStateChanges();
      }

      index++;

      return new Future<Null>.value();
    });
  }

  Future<Null> forEachAsync/*<T>*/(Iterable/*<T>*/ list, Future<dynamic> asyncOperation(/*=T*/ current)) {
    if (list == null) return new Future<Null>.value();

    final Completer<Null> completer = new Completer<Null>();
    final int len = list.length;
    int index = 0;

    void moveNext() {
      if (index < len) {
        asyncOperation(list.elementAt(index++))
            .whenComplete(moveNext);
      } else {
        completer.complete();
      }
    }

    moveNext();

    return completer.future;
  }

  bool resolveOpenState(ListItem<T> listItem, int index) {
    if (autoOpenChildren && !_isOpenMap.containsKey(listItem)) toggleChildren(listItem, index);

    return true;
  }

  @override bool isOpen(ListItem<T> listItem) {
    if (listItem.isAlwaysOpen) return true;

    bool result = false;

    for (int i=0, len=_isOpenMap.keys.length; i<len; i++) {
      ListItem<T> item = _isOpenMap.keys.elementAt(i);

      if (item.compareTo(listItem) == 0) {
        result = _isOpenMap[item];

        break;
      }
    }

    return result;
  }

  Future<Null> maybeToggleChildren(ListItem<T> listItem, int index) {
    if (!allowToggle) return toggleChildren(listItem, index);

    return new Future<Null>.value();
  }

  Future<Null> toggleChildren(ListItem<T> listItem, int index) async {
    final Completer<Null> completer = new Completer<Null>();
    final List<ListItem<T>> openItems = <ListItem<T>>[];
    final Map<ListItem<T>, bool> clone = <ListItem<T>, bool>{};
    final StreamSubscription<Tuple2<Map<ListItem<T>, bool>, int>> existingSubscription = _onBeforeDestroyChildSubscriptions[listItem];
    ListItem<T> match;

    forceAnimateOnOpen = true;

    _isOpenMap.forEach((ListItem<T> item, bool isOpen) => clone[item] = isOpen);

    clone.forEach((ListItem<T> item, _) {
      if (item.compareTo(listItem) == 0) match = item;
    });

    if (match != listItem) {
      clone.keys
        .where((ListItem<T> item) => item.compareTo(match) == 0)
        .toList(growable: false)
        .forEach(clone.remove);
    }

    ListItem<T> listItemMatch = clone.keys.firstWhere((ListItem<T> item) => item.compareTo(listItem) == 0, orElse: () => null);

    if (listItemMatch == null) clone[listItem] = (match == null);
    else clone[listItem] = !clone[listItem];

    clone.forEach((ListItem<T> listItem, bool isOpen) {
      if (isOpen) openItems.add(listItem);
    });

    listItemMatch = clone.keys.firstWhere((ListItem<T> item) => item.compareTo(listItem) == 0, orElse: () => null);

    if (existingSubscription != null) await existingSubscription.cancel();

    if (listItemMatch != null && clone[listItem]) {
      _isOpenMap = clone;

      if (!_openListItems$Ctrl.isClosed) _openListItems$Ctrl.add(openItems);

      completer.complete();
    } else {
      if (resolveChildren(listItem).isEmpty) {
        _isOpenMap = clone;

        if (!_openListItems$Ctrl.isClosed) _openListItems$Ctrl.add(openItems);

        completer.complete();
      } else {
        _onBeforeDestroyChildSubscriptions[listItem] = ngBeforeDestroyChild(<int>[index])
            .map((int i) => new Tuple2<Map<ListItem<T>, bool>, int>(clone, i))
            .listen((Tuple2<Map<ListItem<T>, bool>, int> tuple) {
          if (tuple.item2 == index) {
            _isOpenMap = tuple.item1;

            if (!_openListItems$Ctrl.isClosed) _openListItems$Ctrl.add(openItems);

            listRendererService.notifyIsOpenChange();

            deliverStateChanges();
          }
        }, onDone: () => completer.complete());
      }
    }

    listRendererService.notifyIsOpenChange();

    return completer.future;
  }

  void _cleanupOpenMap() {
    final List<ListItem<T>> removeList = <ListItem<T>>[];

    _isOpenMap.forEach((ListItem<T> item, bool isOpen) {
      if (!isOpen) removeList.add(item);
    });

    removeList.forEach(_isOpenMap.remove);

    listRendererService.notifyIsOpenChange();
  }

  void _cleanUpListeners() {
    _onBeforeDestroyChildSubscriptions.values.forEach((_) => _.cancel());
    _onBeforeDestroyChildSubscriptions.clear();
  }

  List<ListItem<T>> resolveChildren(ListItem<T> listItem) {
    if (_resolvedChildren.containsKey(listItem)) return _resolvedChildren[listItem];

    final List<ListItem<T>> result = _resolvedChildren[listItem] = resolveChildrenHandler(level, listItem);

    return result;
  }

  void handleRendererEvent(ItemRendererEvent<dynamic, T> event) {
    if (event.type == 'childRegistry') _childHierarchies$ctrl.add(new Tuple2<Hierarchy<Comparable<dynamic>>, bool>(event.data as Hierarchy<Comparable<dynamic>>, true));
    else if (!allowMultiSelection && event.type == 'selection') {
      clearSelection((ListItem<Comparable<dynamic>> listItem) => listItem != event.listItem);

      _clearChildHierarchies$ctrl.add((ListItem<Comparable<dynamic>> listItem) => listItem != event.listItem);
    }

    listRendererService.triggerEvent(event);
  }

  @override void handleSelection(ListItem<Comparable<dynamic>> listItem) {
    super.handleSelection(listItem);

    if (!allowMultiSelection && !_clearChildHierarchies$ctrl.isClosed) _clearChildHierarchies$ctrl.add((ListItem<Comparable<dynamic>> listItem) => true);
  }

  Type listItemRendererHandler(_, [ListItem<Comparable<dynamic>> listItem]) => resolveRendererHandler(level, listItem);
}