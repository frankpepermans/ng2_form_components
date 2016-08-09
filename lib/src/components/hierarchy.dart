library ng2_form_components.components.hierarchy;

import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx show Observable, observable;
import 'package:dorm/dorm.dart' show Entity;
import 'package:tuple/tuple.dart' show Tuple2;
import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/interfaces/before_destroy_child.dart' show BeforeDestroyChild;

import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart' show ListDragDropHandler;

import 'package:ng2_form_components/src/components/internal/form_component.dart' show LabelHandler;
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart' show ListItemRenderer;

import 'package:ng2_form_components/src/components/list_renderer.dart' show ListRenderer, ClearSelectionWhereHandler;
import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;

import 'package:ng2_form_components/src/components/animation/hierarchy_animation.dart' show HierarchyAnimation;

import 'package:ng2_form_components/src/components/item_renderers/default_hierarchy_list_item_renderer.dart' show DefaultHierarchyListItemRenderer;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ItemRendererEvent, ListRendererEvent, ListRendererService;

import 'package:ng2_state/ng2_state.dart' show State, SerializableTuple1, SerializableTuple3, StatePhase, StateService;

import 'package:ng2_form_components/src/components/internal/form_component.dart' show ResolveChildrenHandler, ResolveRendererHandler;

@Component(
    selector: 'hierarchy',
    templateUrl: 'hierarchy.html',
    directives: const [State, Hierarchy, HierarchyAnimation, ListItemRenderer, NgClass],
    providers: const <Type>[StateService],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class Hierarchy<T extends Comparable> extends ListRenderer<T> implements OnChanges, OnDestroy, AfterViewInit, BeforeDestroyChild {

  @ViewChild('subHierarchy') Hierarchy subHierarchy;

  @override @ViewChild('scrollPane') void set scrollPane(ElementRef value) {
    super.scrollPane = value;
  }

  //-----------------------------
  // input
  //-----------------------------

  @override @Input() void set labelHandler(LabelHandler value) {
    super.labelHandler = value;
  }

  @override @Input() void set dragDropHandler(ListDragDropHandler value) {
    super.dragDropHandler = value;
  }

  @override @Input() void set dataProvider(List<ListItem<T>> value) {
    forceAnimateOnOpen = false;

    super.dataProvider = value;
  }

  @override @Input() void set selectedItems(List<ListItem<T>> value) {
    super.selectedItems = value;
  }

  @override @Input() void set allowMultiSelection(bool value) {
    super.allowMultiSelection = value;
  }

  @override bool get moveSelectionOnTop => false;

  @override @Input() void set childOffset(int value) {
    super.childOffset = value;
  }

  @override @Input() void set rendererEvents(List<ListRendererEvent<dynamic, Comparable>> value) {
    super.rendererEvents = value;
  }

  @override @Input() void set pageOffset(int value) {
    super.pageOffset = value;
  }

  @override @Input() void set listRendererService(ListRendererService value) {
    super.listRendererService = value;
  }

  int _level = 0;
  int get level => _level;
  @Input() void set level(int value) {
    _level = value;
  }

  List<ListItem<Comparable>> _hierarchySelectedItems;
  List<ListItem<Comparable>> get hierarchySelectedItems => _hierarchySelectedItems;
  @Input() void set hierarchySelectedItems(List<ListItem<Comparable>> value) {
    _hierarchySelectedItems = value;
  }

  List<int> _levelsThatBreak = const [];
  List<int> get levelsThatBreak => _levelsThatBreak;
  @Input() void set levelsThatBreak(List<int> value) {
    _levelsThatBreak = value;
  }

  ResolveChildrenHandler _resolveChildrenHandler;
  ResolveChildrenHandler get resolveChildrenHandler => _resolveChildrenHandler;
  @Input() void set resolveChildrenHandler(ResolveChildrenHandler value) {
    _resolveChildrenHandler = value;
  }

  bool _allowToggle = true;
  bool get allowToggle => _allowToggle;
  @Input() void set allowToggle(bool value) {
    _allowToggle = value;

    changeDetector.markForCheck();
  }

  @override @Input() void set resolveRendererHandler(ResolveRendererHandler value) {
    super.resolveRendererHandler = value;
  }

  //-----------------------------
  // output
  //-----------------------------

  @override @Output() rx.Observable<List<ListItem<T>>> get selectedItemsChanged => rx.observable(_selection$) as rx.Observable<List<ListItem<T>>>;
  @override @Output() Stream<bool> get requestClose => super.requestClose;
  @override @Output() Stream<bool> get scrolledToBottom => super.scrolledToBottom;
  @override @Output() Stream<ItemRendererEvent<dynamic, Comparable>> get itemRendererEvent => super.itemRendererEvent;

  @override StreamController get beforeDestroyChild => _beforeDestroyChild$ctrl;

  //-----------------------------
  // private properties
  //-----------------------------

  final Map<ListItem<T>, List<ListItem<T>>> _resolvedChildren = <ListItem<T>, List<ListItem<T>>>{};

  final StreamController<Tuple2<Hierarchy, bool>> _childHierarchies$ctrl = new StreamController<Tuple2<Hierarchy, bool>>.broadcast();
  final StreamController<ClearSelectionWhereHandler> _clearChildHierarchies$ctrl = new StreamController<ClearSelectionWhereHandler>.broadcast();
  final StreamController<List<Hierarchy>> _childHierarchyList$ctrl = new StreamController<List<Hierarchy>>.broadcast();
  final StreamController<Map<Hierarchy, List<ListItem<T>>>> _selection$Ctrl = new StreamController<Map<Hierarchy, List<ListItem<T>>>>.broadcast();
  final StreamController<List<ListItem<T>>> _openListItems$Ctrl = new StreamController<List<ListItem<T>>>.broadcast();
  final StreamController<int> _beforeDestroyChild$ctrl = new StreamController<int>.broadcast();
  final StreamController<bool> _domModified$ctrl = new StreamController<bool>.broadcast();

  Map<ListItem<T>, bool> _isOpenMap = <ListItem<T>, bool>{};

  StreamSubscription<Tuple2<List<Hierarchy>, ClearSelectionWhereHandler>> _clearChildHierarchiesSubscription;
  StreamSubscription<Tuple2<Hierarchy, List<Hierarchy>>> _registerChildHierarchySubscription;
  StreamSubscription<Map<Hierarchy, List<ListItem<T>>>> _selectionBuilderSubscription;
  StreamSubscription<Map<ListItem<T>, bool>> _beforeDestroyChildSubscription;
  StreamSubscription<int> _onBeforeDestroyChildSubscription;

  Stream<List<ListItem>> _selection$;

  bool forceAnimateOnOpen = false;

  List<ListItem<T>> _receivedSelection;

  //-----------------------------
  // constructor
  //-----------------------------

  Hierarchy(
    @Inject(ElementRef) ElementRef element,
    @Inject(ChangeDetectorRef) ChangeDetectorRef changeDetector,
    @Inject(StateService) StateService stateService) : super(element, changeDetector, stateService) {
      super.resolveRendererHandler = (int level, [_]) => DefaultHierarchyListItemRenderer;

      _initStreams();

      listRendererService.triggerEvent(new ItemRendererEvent<Hierarchy, T>('childRegistry', null, this));
    }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<Entity> provideState() {
    final Stream<SerializableTuple1<int>> scroll$ = super.provideState();

    return new rx.Observable.combineLatest([
      rx.observable(scroll$).startWith(<SerializableTuple1<int>>[new SerializableTuple1<int>()..item1 = 0]),
      internalSelectedItemsChanged.startWith(const [const []]),
      rx.observable(_openListItems$Ctrl.stream).startWith(const [const []])
    ], (SerializableTuple1<int> scrollPosition, List<ListItem<T>> selectedItems, List<ListItem<T>> openItems) {
      return new SerializableTuple3<int, List<ListItem<T>>, List<ListItem<T>>>()
        ..item1 = scrollPosition.item1
        ..item2 = selectedItems
        ..item3 = openItems;
    }, asBroadcastStream: true);
  }

  @override void ngAfterViewInit() {
    super.ngAfterViewInit();

    if (hierarchySelectedItems == null || hierarchySelectedItems.isEmpty) _processIncomingSelectedState(_receivedSelection);

    hierarchySelectedItems = null;
  }

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple3<int, List<ListItem<T>>, List<ListItem<T>>> tuple = entity as SerializableTuple3<int, List<ListItem<T>>, List<ListItem<T>>>;

    super.receiveState(new SerializableTuple1<int>()
      ..item1 = tuple.item1, phase);

    _receivedSelection = tuple.item2;

    tuple.item3.forEach((ListItem<T> listItem) => _isOpenMap[listItem] = true);

    _openListItems$Ctrl.add(tuple.item3);

    changeDetector.markForCheck();
  }

  @override void ngOnChanges(Map<String, SimpleChange> changes) {
    super.ngOnChanges(changes);

    if (changes.containsKey('hierarchySelectedItems') && hierarchySelectedItems != null && hierarchySelectedItems.isNotEmpty) {
      hierarchySelectedItems.forEach((ListItem<Comparable> listItem) {
        listRendererService.rendererSelection$
          .take(1)
          .map((_) => new ItemRendererEvent<bool, T>('selection', listItem as ListItem<T>, true))
          .listen(listRendererService.triggerEvent);

        listRendererService.triggerSelection(listItem);
      });

      changeDetector.markForCheck();
    }
  }

  @override Stream<int> ngBeforeDestroyChild([List args]) async* {
    final List<int> argsCast = args as List<int>;
    final Completer<int> completer = new Completer<int>();

    beforeDestroyChild.add(argsCast.first);

    _onBeforeDestroyChildSubscription = new rx.Observable<int>.merge([
      (beforeDestroyChild.stream as Stream<int>)
        .where((int index) => index == argsCast.first),
      onDestroy
        .map((_) => 0)
    ])
      .take(1)
      .listen((_) => completer.complete(argsCast.first));

    await completer.future;

    yield args.first;
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();

    window.removeEventListener('DOMSubtreeModified', _handleDomChange);

    _clearChildHierarchiesSubscription?.cancel();
    _registerChildHierarchySubscription?.cancel();
    _selectionBuilderSubscription?.cancel();
    _beforeDestroyChildSubscription?.cancel();
    _onBeforeDestroyChildSubscription?.cancel();
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initStreams() {
    window.addEventListener('DOMSubtreeModified', _handleDomChange);

    _clearChildHierarchiesSubscription = new rx.Observable<Tuple2<List<Hierarchy>, ClearSelectionWhereHandler>>.combineLatest([
      _childHierarchyList$ctrl.stream,
      _clearChildHierarchies$ctrl.stream
    ], (List<Hierarchy> childHierarchies, ClearSelectionWhereHandler handler) => new Tuple2<List<Hierarchy>, ClearSelectionWhereHandler>(childHierarchies, handler))
      .listen((Tuple2<List<Hierarchy>, ClearSelectionWhereHandler> tuple) => tuple.item1.forEach((Hierarchy childHierarchy) => childHierarchy.clearSelection(tuple.item2)));

    _registerChildHierarchySubscription = new rx.Observable<Tuple2<Tuple2<Hierarchy, bool>, List<Hierarchy>>>.zip([
      _childHierarchies$ctrl.stream,
      _childHierarchyList$ctrl.stream
    ], (Tuple2<Hierarchy, bool> childHierarchy, List<Hierarchy> hierarchies) {
      final List<Hierarchy> clone = hierarchies.toList();

      if (childHierarchy.item2) clone.add(childHierarchy.item1);
      else clone.remove(childHierarchy.item1);

      return new Tuple2<Tuple2<Hierarchy, bool>, List<Hierarchy>>(childHierarchy, new List<Hierarchy>.unmodifiable(clone));
    })
      .tap((Tuple2<Tuple2<Hierarchy, bool>, List<Hierarchy>> tuple) => _childHierarchyList$ctrl.add(tuple.item2))
      .where((Tuple2<Tuple2<Hierarchy, bool>, List<Hierarchy>> tuple) => tuple.item1.item2)
      .map((Tuple2<Tuple2<Hierarchy, bool>, List<Hierarchy>> tuple) => new Tuple2<Hierarchy, List<Hierarchy>>(tuple.item1.item1, tuple.item2))
      .flatMap((Tuple2<Hierarchy, List<Hierarchy>> tuple) => tuple.item1.onDestroy.take(1).map((_) => tuple))
      .listen((Tuple2<Hierarchy, List<Hierarchy>> tuple) => _childHierarchies$ctrl.add(new Tuple2<Hierarchy, bool>(tuple.item1, false)));

    _selectionBuilderSubscription = new rx.Observable<Map<Hierarchy, List<ListItem<T>>>>.zip([
      rx.observable(_selection$Ctrl.stream).startWith(<Map<Hierarchy, List<ListItem<T>>>>[<Hierarchy, List<ListItem<T>>>{}]),
      rx.observable(_childHierarchyList$ctrl.stream)
        .flatMapLatest((List<Hierarchy> hierarchies) => new rx.Observable.merge((new List<Hierarchy>.from(hierarchies)..add(this))
          .map((Hierarchy hierarchy) => hierarchy.internalSelectedItemsChanged
            .map((List<ListItem> selectedItems) => new Tuple2<Hierarchy, List<ListItem>>(hierarchy, selectedItems)))))
    ], (Map<Hierarchy, List<ListItem>> selectedItems, Tuple2<Hierarchy, List<ListItem>> tuple) {
      if (tuple.item1.stateGroup != null && tuple.item1.stateGroup.isNotEmpty && tuple.item1.stateId != null && tuple.item1.stateId.isNotEmpty) {
        Hierarchy match;

        selectedItems.forEach((Hierarchy hierarchy, _) {
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
      .map((Map<Hierarchy, List<ListItem>> map) {
        final List<ListItem> fold = <ListItem>[];

        map.values.forEach(fold.addAll);

        return fold;
      });

    _childHierarchyList$ctrl.add(const []);
    _selection$Ctrl.add(<Hierarchy, List<ListItem<T>>>{});
  }

  void _handleDomChange(Event event) => _domModified$ctrl.add(true);

  void _processIncomingSelectedState(List<ListItem<T>> selectedItems) {
    if (selectedItems != null && selectedItems.isNotEmpty) {
      if (level == 0) selectedItems.forEach(handleSelection);
      else {
        new rx.Observable.merge(<Stream>[
          rx.observable(_domModified$ctrl.stream)
            .flatMapLatest((_) => new Stream<num>.fromFuture(window.animationFrame))
            .debounce(const Duration(milliseconds: 50)),
          new Stream.periodic(const Duration(milliseconds: 200))
        ])
          .take(1)
          .listen((_) {
            selectedItems.forEach((ListItem<Comparable> listItem) {
              rx.observable(listRendererService.rendererSelection$)
                  .take(1)
                  .map((_) => new ItemRendererEvent<bool, T>('selection', listItem, true))
                  .listen(handleRendererEvent);

              listRendererService.triggerSelection(listItem);
            });
          });
      }
    }
  }

  //-----------------------------
  // template methods
  //-----------------------------

  String getStateId(int index) {
    final String id = (stateId != null) ? stateId : index.toString();

    return '${id}_${level}_$index';
  }

  @override bool isOpen(ListItem<T> listItem) {
    if (listItem.isAlwaysOpen) return true;

    bool result = false;

    _isOpenMap.forEach((ListItem<T> item, bool isOpen) {
      if (item.compareTo(listItem) == 0) result = isOpen;
    });

    return result;
  }

  void maybeToggleChildren(ListItem<T> listItem, int index) {
    if (!allowToggle) toggleChildren(listItem, index);
  }

  void toggleChildren(ListItem<T> listItem, int index) {
    final List<ListItem<T>> openItems = <ListItem<T>>[];
    final Map<ListItem<T>, bool> clone = new LinkedHashMap<ListItem<T>, bool>(equals: (ListItem<T> itemA, ListItem<T> itemB) => itemA.compareTo(itemB) == 0);
    ListItem<T> match;

    forceAnimateOnOpen = true;

    _isOpenMap.forEach((ListItem<T> item, bool isOpen) => clone[item] = isOpen);

    clone.forEach((ListItem<T> item, _) {
      if (item.compareTo(listItem) == 0) match = item;
    });

    if (match != listItem) clone.remove(match);

    if (!clone.containsKey(listItem)) clone[listItem] = match == null;
    else clone[listItem] = !clone[listItem];

    clone.forEach((ListItem<T> listItem, bool isOpen) {
      if (isOpen) openItems.add(listItem);
    });

    if (clone.containsKey(listItem) && clone[listItem]) {
      _isOpenMap = clone;

      _openListItems$Ctrl.add(openItems);
    } else {
      _beforeDestroyChildSubscription?.cancel();

      _beforeDestroyChildSubscription = ngBeforeDestroyChild(<int>[index])
        .where((int i) => i == index)
        .take(1)
        .map((_) => clone)
        .listen((Map<ListItem<T>, bool> clone) {
          _isOpenMap = clone;

          _openListItems$Ctrl.add(openItems);

          changeDetector.markForCheck();
        });
    }
  }

  List<ListItem<T>> resolveChildren(ListItem<T> listItem) {
    if (_resolvedChildren.containsKey(listItem)) return _resolvedChildren[listItem];

    final List<ListItem<T>> result = _resolvedChildren[listItem] = resolveChildrenHandler(level, listItem);

    return result;
  }

  void handleRendererEvent(ItemRendererEvent<dynamic, T> event) {
    if (event.type == 'childRegistry') _childHierarchies$ctrl.add(new Tuple2<Hierarchy, bool>(event.data as Hierarchy, true));

    if (!allowMultiSelection && event.type == 'selection') {
      clearSelection((ListItem<Comparable> listItem) => listItem != event.listItem);

      _clearChildHierarchies$ctrl.add((ListItem<Comparable> listItem) => listItem != event.listItem);
    }

    listRendererService.triggerEvent(event);
  }

  @override void handleSelection(ListItem<Comparable> listItem) {
    super.handleSelection(listItem);

    if (!allowMultiSelection) _clearChildHierarchies$ctrl.add((ListItem<Comparable> listItem) => true);
  }

  Type listItemRendererHandler(_, [ListItem<Comparable> listItem]) => resolveRendererHandler(level, listItem);
}