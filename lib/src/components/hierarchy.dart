import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' show Observable;
import 'package:dorm/dorm.dart' show Entity;
import 'package:tuple/tuple.dart' show Tuple2;
import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/interfaces/before_destroy_child.dart'
    show BeforeDestroyChild;

import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart'
    show ListItemRenderer;
import 'package:ng2_form_components/src/components/internal/drag_drop_list_item_renderer.dart'
    show DragDropListItemRenderer;

import 'package:ng2_form_components/src/components/list_renderer.dart'
    show ListRenderer, ClearSelectionWhereHandler, NgForTracker;
import 'package:ng2_form_components/src/components/list_item.g.dart'
    show ListItem;

import 'package:ng2_form_components/src/components/animation/hierarchy_animation.dart'
    show HierarchyAnimation;

import 'package:ng2_form_components/src/components/item_renderers/default_hierarchy_list_item_renderer.template.dart'
    as ir;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart'
    show ItemRendererEvent, ListRendererEvent, ListRendererService;

import 'package:ng2_state/ng2_state.dart'
    show
        State,
        SerializableTuple1,
        SerializableTuple3,
        StatePhase,
        StateService,
        StatefulComponent;

import 'package:ng2_form_components/src/components/internal/form_component.dart'
    show ResolveChildrenHandler, ResolveRendererHandler;

typedef bool ShouldOpenDiffer(
    ListItem<Comparable> itemA, ListItem<Comparable> itemB);

@Component(
    selector: 'hierarchy',
    templateUrl: 'hierarchy.html',
    directives: <dynamic>[
      coreDirectives,
      State,
      Hierarchy,
      HierarchyAnimation,
      ListItemRenderer,
      DragDropListItemRenderer
    ],
    pipes: <dynamic>[commonPipes],
    providers: <dynamic>[
      StateService,
      ExistingProvider.forToken(OpaqueToken('statefulComponent'), Hierarchy)
    ],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class Hierarchy extends ListRenderer
    implements OnDestroy, AfterViewInit, BeforeDestroyChild {
  Hierarchy _subHierarchy;
  Hierarchy get subHierarchy => _subHierarchy;
  @ViewChild('subHierarchy')
  set subHierarchy(Hierarchy value) {
    _subHierarchy = value;
  }

  @override
  @ViewChild('scrollPane')
  set scrollPane(Element value) {
    super.scrollPane = value;
  }

  //-----------------------------
  // input
  //-----------------------------

  @override
  @Input()
  set dataProvider(List<ListItem<Comparable>> value) {
    if (distinctDataProvider(dataProvider, value)) {
      forceAnimateOnOpen = false;

      _cleanupOpenMap();
      _cleanUpListeners();

      super.dataProvider = value;
    }
  }

  @override
  bool get moveSelectionOnTop => false;

  @override
  @Input()
  set listRendererService(ListRendererService value) {
    if (listRendererService != value) {
      super.listRendererService = value;

      _listRendererService$ctrl.add(value);

      value?.triggerEvent(ItemRendererEvent<Hierarchy, Comparable>(
          'childRegistry', null, this));
    }
  }

  int _level = 0;
  int get level => _level;
  @Input()
  set level(int value) {
    if (_level != value) setState(() => _level = value);
  }

  bool _autoOpenChildren = false;
  bool get autoOpenChildren => _autoOpenChildren;
  @Input()
  set autoOpenChildren(bool value) {
    if (_autoOpenChildren != value) setState(() => _autoOpenChildren = value);
  }

  List<ListItem<Comparable>> _hierarchySelectedItems;
  List<ListItem<Comparable>> get hierarchySelectedItems =>
      _hierarchySelectedItems;
  @Input()
  set hierarchySelectedItems(List<ListItem<Comparable>> value) {
    if (_hierarchySelectedItems != value) {
      setState(() => _hierarchySelectedItems = value);

      if (value != null && value.isNotEmpty) {
        value.forEach((listItem) {
          listRendererService.rendererSelection$
              .take(1)
              .map((_) => ItemRendererEvent<bool, Comparable>(
                  'selection', listItem, true))
              .listen(listRendererService?.triggerEvent);

          listRendererService?.triggerSelection(listItem);
        });
      }
    }
  }

  List<int> _levelsThatBreak = const [];
  List<int> get levelsThatBreak => _levelsThatBreak;
  @Input()
  set levelsThatBreak(List<int> value) {
    if (_levelsThatBreak != value) setState(() => _levelsThatBreak = value);
  }

  ResolveChildrenHandler _resolveChildrenHandler;
  ResolveChildrenHandler get resolveChildrenHandler => _resolveChildrenHandler;
  @Input()
  set resolveChildrenHandler(ResolveChildrenHandler value) {
    if (_resolveChildrenHandler != value)
      setState(() => _resolveChildrenHandler = value);
  }

  bool _allowToggle = false;
  bool get allowToggle => _allowToggle;
  @Input()
  set allowToggle(bool value) {
    if (_allowToggle != value) setState(() => _allowToggle = value);
  }

  ShouldOpenDiffer _shouldOpenDiffer =
      (ListItem<Comparable> itemA, ListItem<Comparable> itemB) =>
          itemA.compareTo(itemB) == 0;
  ShouldOpenDiffer get shouldOpenDiffer => _shouldOpenDiffer;
  @Input()
  set shouldOpenDiffer(ShouldOpenDiffer value) {
    if (_shouldOpenDiffer != value) setState(() => _shouldOpenDiffer = value);
  }

  //-----------------------------
  // output
  //-----------------------------

  @override
  @Output()
  Observable<List<ListItem<Comparable>>> get selectedItemsChanged =>
      Observable<List<ListItem<Comparable>>>(_selection$);
  @override
  @Output()
  Stream<bool> get requestClose => super.requestClose;
  @override
  @Output()
  Stream<bool> get scrolledToBottom => super.scrolledToBottom;
  @override
  @Output()
  Stream<ItemRendererEvent<dynamic, Comparable>> get itemRendererEvent =>
      super.itemRendererEvent;

  @override
  StreamController<int> get beforeDestroyChild => _beforeDestroyChild$ctrl;

  //-----------------------------
  // private properties
  //-----------------------------

  final Map<ListItem<Comparable>, List<ListItem<Comparable>>>
      _resolvedChildren = <ListItem<Comparable>, List<ListItem<Comparable>>>{};

  final StreamController<Tuple2<Hierarchy, bool>> _childHierarchies$ctrl =
      StreamController<Tuple2<Hierarchy, bool>>.broadcast();
  final StreamController<ClearSelectionWhereHandler>
      _clearChildHierarchies$ctrl =
      StreamController<ClearSelectionWhereHandler>.broadcast();
  final StreamController<List<Hierarchy>> _childHierarchyList$ctrl =
      StreamController<List<Hierarchy>>.broadcast();
  final StreamController<Map<Hierarchy, List<ListItem<Comparable>>>>
      _selection$Ctrl =
      StreamController<Map<Hierarchy, List<ListItem<Comparable>>>>.broadcast();
  final StreamController<List<ListItem<Comparable>>> _openListItems$Ctrl =
      StreamController<List<ListItem<Comparable>>>.broadcast();
  final StreamController<int> _beforeDestroyChild$ctrl =
      StreamController<int>.broadcast();
  final StreamController<bool> _domModified$ctrl =
      StreamController<bool>.broadcast();
  final StreamController<ListRendererService> _listRendererService$ctrl =
      StreamController<ListRendererService>();

  Map<ListItem<Comparable>, bool> _isOpenMap = <ListItem<Comparable>, bool>{};

  StreamSubscription<dynamic> _windowMutationListener;
  StreamSubscription<ItemRendererEvent<dynamic, Comparable>> _eventSubscription;
  StreamSubscription<Tuple2<List<Hierarchy>, ClearSelectionWhereHandler>>
      _clearChildHierarchiesSubscription;
  StreamSubscription<Tuple2<Hierarchy, List<Hierarchy>>>
      _registerChildHierarchySubscription;
  StreamSubscription<Map<Hierarchy, List<ListItem<Comparable>>>>
      _selectionBuilderSubscription;

  Stream<List<ListItem<Comparable>>> _selection$;

  bool forceAnimateOnOpen = false;

  List<ListItem<Comparable>> _receivedSelection;

  final Map<ListItem<Comparable>,
          StreamSubscription<Tuple2<Map<ListItem<Comparable>, bool>, int>>>
      _onBeforeDestroyChildSubscriptions = <ListItem<Comparable>,
          StreamSubscription<Tuple2<Map<ListItem<Comparable>, bool>, int>>>{};

  //-----------------------------
  // constructor
  //-----------------------------

  Hierarchy(@Inject(Element) Element element) : super(element) {
    super.resolveRendererHandler =
        (int level, [_]) => ir.DefaultHierarchyListItemRendererNgFactory;

    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override
  Stream<Entity> provideState() => Observable.combineLatest3(
      Observable(super.provideState())
          .startWith(SerializableTuple1<int>()..item1 = 0),
      internalSelectedItemsChanged.startWith(const []),
      Observable(_openListItems$Ctrl.stream).where((_) => !autoOpenChildren),
      (Entity scrollPosition, List<ListItem<Comparable>> selectedItems,
              List<ListItem<Comparable>> openItems) =>
          SerializableTuple3<int, List<ListItem<Comparable>>,
              List<ListItem<Comparable>>>()
            ..item1 = (scrollPosition as SerializableTuple1<int>)?.item1
            ..item2 = selectedItems
            ..item3 = openItems).asBroadcastStream().startWith(
      SerializableTuple3<int, List<ListItem<Comparable>>,
          List<ListItem<Comparable>>>()
        ..item1 = 0
        ..item2 = const []
        ..item3 = const []);

  @override
  void ngAfterViewInit() {
    super.ngAfterViewInit();

    if (hierarchySelectedItems == null || hierarchySelectedItems.isEmpty)
      _processIncomingSelectedState(_receivedSelection);

    if (hierarchySelectedItems != null)
      setState(() => hierarchySelectedItems = null);
  }

  @override
  void receiveState(SerializableTuple3 entity, StatePhase phase) {
    final item1 = entity.item1 as int;
    final item2 = (entity.item2 as List).cast<Entity>(),
        item3 = (entity.item3 as List).cast<Entity>();
    final listCast = <ListItem<Comparable>>[];
    final listCast2 = <ListItem<Comparable>>[];

    item2?.forEach((entity) => listCast.add(entity as ListItem<Comparable>));

    super.receiveState(SerializableTuple1<int>()..item1 = item1, phase);

    _receivedSelection = listCast;

    item3?.forEach((Entity entity) {
      final listItem = entity as ListItem<Comparable>;
      _isOpenMap[listItem] = true;

      listCast2.add(listItem);
    });

    if (listCast2.isNotEmpty) _openListItems$Ctrl.add(listCast2);

    listRendererService.notifyIsOpenChange();

    if (item3 != null && item3.isNotEmpty) deliverStateChanges();
  }

  @override
  Stream<int> ngBeforeDestroyChild([List<dynamic> args]) {
    final argsCast = args as List<int>;

    beforeDestroyChild.add(argsCast.first);

    return Observable.race([
      beforeDestroyChild.stream.where((index) => index == argsCast.first),
      onDestroy.map((_) => 0)
    ]).take(1).map((_) => argsCast.first);
  }

  @override
  void ngOnDestroy() {
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

    _eventSubscription = Observable(_listRendererService$ctrl.stream)
        .switchMap((service) => service.event$)
        .listen(_handleItemRendererEvent);

    _clearChildHierarchiesSubscription = Observable.combineLatest2(
        _childHierarchyList$ctrl.stream,
        _clearChildHierarchies$ctrl.stream,
        (List<Hierarchy> childHierarchies,
                ClearSelectionWhereHandler handler) =>
            Tuple2(childHierarchies, handler)).listen((tuple) => tuple.item1
        .forEach(
            (childHierarchy) => childHierarchy.clearSelection(tuple.item2)));

    _registerChildHierarchySubscription =
        Observable.zip2(
                _childHierarchies$ctrl.stream, _childHierarchyList$ctrl.stream,
                (Tuple2<Hierarchy, bool> childHierarchy,
                    List<Hierarchy> hierarchies) {
      final clone = hierarchies.toList();

      if (childHierarchy.item2)
        clone.add(childHierarchy.item1);
      else
        clone.remove(childHierarchy.item1);

      return Tuple2(childHierarchy, List<Hierarchy>.unmodifiable(clone));
    })
            .doOnData((tuple) => _childHierarchyList$ctrl.add(tuple.item2))
            .where((tuple) => tuple.item1.item2)
            .map((tuple) => Tuple2(tuple.item1.item1, tuple.item2))
            .flatMap((tuple) => tuple.item1.onDestroy.take(1).map((_) => tuple))
            .listen((tuple) =>
                _childHierarchies$ctrl.add(Tuple2(tuple.item1, false)));

    _selectionBuilderSubscription = Observable.zip2(
        Observable(_selection$Ctrl.stream)
            .startWith(<Hierarchy, List<ListItem<Comparable>>>{}),
        Observable(_childHierarchyList$ctrl.stream).switchMap((hierarchies) =>
            Observable.merge((List<Hierarchy>.from(hierarchies)..add(this)).map(
                (hierarchy) => hierarchy.internalSelectedItemsChanged
                    .map((selectedItems) => Tuple2(hierarchy, selectedItems))))),
        (Map<Hierarchy, List<ListItem<Comparable>>> selectedItems,
            Tuple2<Hierarchy, List<ListItem<Comparable>>> tuple) {
      if (tuple.item1.stateGroup != null &&
          tuple.item1.stateGroup.isNotEmpty &&
          tuple.item1.stateId != null &&
          tuple.item1.stateId.isNotEmpty) {
        Hierarchy match;

        selectedItems.forEach((hierarchy, _) {
          if (hierarchy.stateGroup == tuple.item1.stateGroup &&
              hierarchy.stateId == tuple.item1.stateId) match = hierarchy;
        });

        if (match != null && match != tuple.item1) selectedItems.remove(match);
      }

      selectedItems[tuple.item1] = tuple.item2;

      return selectedItems;
    }).where((_) => level == 0).listen(_selection$Ctrl.add);

    _selection$ = _selection$Ctrl.stream.map((map) {
      final fold = <ListItem<Comparable>>[];

      map.values.forEach(fold.addAll);

      return fold;
    });

    _childHierarchyList$ctrl.add(const []);
    _selection$Ctrl.add(<Hierarchy, List<ListItem<Comparable>>>{});
    _listRendererService$ctrl.add(listRendererService);
  }

  void _handleItemRendererEvent(ItemRendererEvent<dynamic, Comparable> event) {
    if (event?.type == 'openRecursively') {
      final eventCast = event as ItemRendererEvent<bool, Comparable>;

      if (eventCast.data != null) {
        for (var i = 0, len = dataProvider.length; i < len; i++) {
          var entry = dataProvider.elementAt(i);

          if (shouldOpenDiffer(eventCast.listItem, entry) && !isOpen(entry))
            toggleChildren(entry, i);
        }
      }

      deliverStateChanges();
    }
  }

  void _handleDomChange(dynamic _) {
    if (!_domModified$ctrl.isClosed) _domModified$ctrl.add(true);
  }

  void _processIncomingSelectedState(List<ListItem<Comparable>> selectedItems) {
    if (selectedItems != null && selectedItems.isNotEmpty) {
      if (level == 0)
        selectedItems.forEach(handleSelection);
      else {
        Observable.race([
          Observable(_domModified$ctrl.stream)
              .asyncMap((_) => window.animationFrame)
              .debounce(const Duration(milliseconds: 50)),
          Stream.periodic(const Duration(milliseconds: 200))
        ]).take(1).listen((dynamic _) {
          selectedItems.forEach((listItem) {
            Observable(listRendererService.rendererSelection$)
                .take(1)
                .map((_) => ItemRendererEvent<bool, Comparable>(
                    'selection', listItem, true))
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
    var index = 0;

    return forEachAsync(dataProvider, (ListItem<Comparable> listItem) async {
      if (!isOpen(listItem)) {
        await maybeToggleChildren(listItem, index);

        if (subHierarchy != null) await subHierarchy.autoOpenChildrenNow();

        deliverStateChanges();
      }

      index++;

      return Future<Null>.value();
    });
  }

  Future<Null> autoCloseChildrenNow() {
    var index = 0;

    return forEachAsync(dataProvider, (ListItem<Comparable> listItem) async {
      if (isOpen(listItem)) {
        if (subHierarchy != null) await subHierarchy.autoCloseChildrenNow();

        await maybeToggleChildren(listItem, index);

        deliverStateChanges();
      }

      index++;

      return Future<Null>.value();
    });
  }

  Future<Null> forEachAsync<T>(
      Iterable<T> list, Future<dynamic> asyncOperation(T current)) {
    if (list == null) return Future<Null>.value();

    final completer = Completer<Null>();
    final len = list.length;
    var index = 0;

    void moveNext() {
      if (index < len) {
        asyncOperation(list.elementAt(index++)).whenComplete(moveNext);
      } else {
        completer.complete();
      }
    }

    moveNext();

    return completer.future;
  }

  bool resolveOpenState(ListItem<Comparable> listItem, int index) {
    if (autoOpenChildren && !_isOpenMap.containsKey(listItem))
      toggleChildren(listItem, index);

    return true;
  }

  @override
  bool isOpen(ListItem<Comparable> listItem) {
    if (listItem.isAlwaysOpen) return true;

    var result = false;

    for (var i = 0, len = _isOpenMap.keys.length; i < len; i++) {
      var item = _isOpenMap.keys.elementAt(i);

      if (item.compareTo(listItem) == 0) {
        result = _isOpenMap[item];

        break;
      }
    }

    return result;
  }

  Future<Null> maybeToggleChildren(ListItem<Comparable> listItem, int index) {
    if (!allowToggle) return toggleChildren(listItem, index);

    return Future<Null>.value();
  }

  Future<Null> toggleChildren(ListItem<Comparable> listItem, int index) async {
    final completer = Completer<Null>();
    final openItems = <ListItem<Comparable>>[];
    final clone = <ListItem<Comparable>, bool>{};
    final existingSubscription = _onBeforeDestroyChildSubscriptions[listItem];
    ListItem<Comparable> match;

    forceAnimateOnOpen = true;

    _isOpenMap.forEach((item, isOpen) => clone[item] = isOpen);

    clone.forEach((item, _) {
      if (item.compareTo(listItem) == 0) match = item;
    });

    if (match != listItem) {
      clone.keys
          .where((item) => item.compareTo(match) == 0)
          .toList(growable: false)
          .forEach(clone.remove);
    }

    var listItemMatch = clone.keys.firstWhere(
        (item) => item.compareTo(listItem) == 0,
        orElse: () => null);

    if (listItemMatch == null)
      clone[listItem] = match == null;
    else
      clone[listItem] = !clone[listItem];

    clone.forEach((listItem, isOpen) {
      if (isOpen) openItems.add(listItem);
    });

    listItemMatch = clone.keys.firstWhere(
        (item) => item.compareTo(listItem) == 0,
        orElse: () => null);

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
        _onBeforeDestroyChildSubscriptions[listItem] =
            ngBeforeDestroyChild([index]).map((i) => Tuple2(clone, i)).listen(
                (tuple) {
          if (tuple.item2 == index) {
            _isOpenMap = tuple.item1;

            if (!_openListItems$Ctrl.isClosed)
              _openListItems$Ctrl.add(openItems);

            listRendererService.notifyIsOpenChange();

            deliverStateChanges();
          }
        }, onDone: completer.complete);
      }
    }

    listRendererService.notifyIsOpenChange();

    return completer.future;
  }

  void _cleanupOpenMap() {
    final removeList = <ListItem<Comparable>>[];

    _isOpenMap.forEach((item, isOpen) {
      if (!isOpen) removeList.add(item);
    });

    removeList.forEach(_isOpenMap.remove);

    listRendererService.notifyIsOpenChange();
  }

  void _cleanUpListeners() {
    _onBeforeDestroyChildSubscriptions.values.forEach((_) => _.cancel());
    _onBeforeDestroyChildSubscriptions.clear();
  }

  List<ListItem<Comparable>> resolveChildren(ListItem<Comparable> listItem) {
    if (_resolvedChildren.containsKey(listItem))
      return _resolvedChildren[listItem];

    final result =
        _resolvedChildren[listItem] = resolveChildrenHandler(level, listItem);

    return result;
  }

  void handleRendererEvent(ItemRendererEvent<dynamic, Comparable> event) {
    if (event.type == 'childRegistry')
      _childHierarchies$ctrl.add(Tuple2(event.data as Hierarchy, true));
    else if (!allowMultiSelection && event.type == 'selection') {
      clearSelection((listItem) => listItem != event.listItem);

      _clearChildHierarchies$ctrl.add((listItem) => listItem != event.listItem);
    }

    listRendererService.triggerEvent(event);
  }

  @override
  void handleSelection(ListItem<Comparable> listItem) {
    super.handleSelection(listItem);

    if (!allowMultiSelection && !_clearChildHierarchies$ctrl.isClosed)
      _clearChildHierarchies$ctrl.add((listItem) => true);
  }

  ComponentFactory listItemRendererHandler(dynamic _,
          [ListItem<Comparable> listItem]) =>
      resolveRendererHandler(level, listItem);
}
