library ng2_form_components.components.list_renderer;

import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:rxdart/rxdart.dart' as rx;
import 'package:dorm/dorm.dart';
import 'package:tuple/tuple.dart';
import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';
import 'package:ng2_form_components/src/components/list_item.dart';

import 'package:ng2_form_components/src/components/item_renderers/default_list_item_renderer.dart' show DefaultListItemRenderer;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService, ItemRendererEvent, ListRendererEvent;

import 'package:ng2_state/ng2_state.dart' show SerializableTuple1, StatePhase, StateService;

typedef bool IsSelectedHandler(ListItem<Comparable> listItem);
typedef bool ClearSelectionWhereHandler(ListItem<Comparable> listItem);

@Pipe(name: 'selectedItems')
@Injectable()
class SelectedItemsPipe<T extends Comparable> implements PipeTransform {

  const SelectedItemsPipe();

  List<ListItem<T>> transform(List<ListItem<T>> dataProvider, Function handler, bool moveSelectionOnTop) {
    if (!moveSelectionOnTop) return const [];

    return dataProvider.where((ListItem<T> listItem) => listItem != null && handler(listItem)).toList(growable: false);
  }
}

@Pipe(name: 'unselectedItems')
@Injectable()
class UnselectedItemsPipe<T extends Comparable> implements PipeTransform {

  const UnselectedItemsPipe();

  List<ListItem<T>> transform(List<ListItem<T>> dataProvider, Function handler, bool moveSelectionOnTop) {
    if (!moveSelectionOnTop) return dataProvider;

    return dataProvider.where((ListItem<T> listItem) => listItem != null && !handler(listItem)).toList(growable: false);
  }
}

@Component(
    selector: 'list-renderer',
    templateUrl: 'list_renderer.html',
    directives: const <Type>[ListItemRenderer],
    providers: const <Type>[StateService],
    pipes: const [SelectedItemsPipe, UnselectedItemsPipe],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class ListRenderer<T extends Comparable> extends FormComponent<T> implements OnChanges, OnDestroy, AfterViewInit {

  ElementRef _scrollPane;
  ElementRef get scrollPane => _scrollPane;
  @ViewChild('scrollPane') void set scrollPane(ElementRef value) {
    _scrollPane = value;
  }

  //-----------------------------
  // input
  //-----------------------------

  LabelHandler _labelHandler;
  LabelHandler get labelHandler => _labelHandler;
  @Input() void set labelHandler(LabelHandler value) {
    _labelHandler = value;
  }

  ListDragDropHandler _dragDropHandler;
  ListDragDropHandler get dragDropHandler => _dragDropHandler;
  @Input() void set dragDropHandler(ListDragDropHandler value) {
    _dragDropHandler = value;
  }

  ResolveRendererHandler _resolveRendererHandler = (_, [__]) => DefaultListItemRenderer;
  ResolveRendererHandler get resolveRendererHandler => _resolveRendererHandler;
  @Input() void set resolveRendererHandler(ResolveRendererHandler value) {
    _resolveRendererHandler = value;
  }

  List<ListItem<T>> _dataProvider = <ListItem<T>>[];
  List<ListItem<T>> get dataProvider => _dataProvider;
  @Input() void set dataProvider(List<ListItem<T>> value) {
    _dataProvider = value;
  }

  List<ListItem<T>> _selectedItems = <ListItem<T>>[];
  List<ListItem<T>> get selectedItems => _selectedItems;
  @Input() void set selectedItems(List<ListItem<T>> value) {
    _selectedItems = value;
  }

  bool _allowMultiSelection = false;
  bool get allowMultiSelection => _allowMultiSelection;
  @Input() void set allowMultiSelection(bool value) {
    _allowMultiSelection = value;
  }

  bool _moveSelectionOnTop = false;
  bool get moveSelectionOnTop => _moveSelectionOnTop;
  @Input() void set moveSelectionOnTop(bool value) {
    _moveSelectionOnTop = value;
  }

  int _childOffset = 20;
  int get childOffset => _childOffset;
  @Input() void set childOffset(int value) {
    _childOffset = value;
  }

  List<ListRendererEvent> _rendererEvents;
  List<ListRendererEvent> get rendererEvents => _rendererEvents;
  @Input() void set rendererEvents(List<ListRendererEvent<dynamic, Comparable>> value) {
    _rendererEvents = value;
  }

  int _pageOffset = 0;
  int get pageOffset => _pageOffset;
  @Input() void set pageOffset(int value) {
    _pageOffset = value;
  }

  String _className = 'ng2-form-components-list-renderer';
  String get className => _className;
  @Input() void set className(String value) {
    _className = value;

    cssMap = <String, bool>{value: true};
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output() rx.Observable<List<ListItem<T>>> get selectedItemsChanged => _selectedItems$;
  @Output() Stream<bool> get requestClose => _requestClose$ctrl.stream;
  @Output() Stream<bool> get scrolledToBottom => _scrolledToBottom$ctrl.stream;
  @Output() Stream<ItemRendererEvent> get itemRendererEvent => _itemRendererEvent$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  Map<String, bool> cssMap = const <String, bool>{'ng2-form-components-list-renderer': true};
  rx.Observable<List<ListItem<T>>> get internalSelectedItemsChanged => _selectedItems$;
  Iterable<ListItem<T>> internalSelectedItems = new List<ListItem<T>>.unmodifiable(const []);

  final ElementRef element;

  rx.Observable<List<ListItem<T>>> _selectedItems$;

  final ListRendererService listRendererService = new ListRendererService();
  final StreamController<List<ListItem<T>>> _selectedItems$ctrl = new StreamController<List<ListItem<T>>>.broadcast();
  final StreamController<ListItem<T>> _incomingSelection$ctrl = new StreamController<ListItem<T>>();
  final StreamController<bool> _requestClose$ctrl = new StreamController<bool>();
  final StreamController<int> _scroll$ctrl = new StreamController<int>.broadcast();
  final StreamController<bool> _scrolledToBottom$ctrl = new StreamController<bool>.broadcast();
  final StreamController<ItemRendererEvent> _itemRendererEvent$ctrl = new StreamController<ItemRendererEvent>.broadcast();
  final StreamController<ClearSelectionWhereHandler> _clearSelection$ctrl = new StreamController<ClearSelectionWhereHandler>.broadcast();

  StreamSubscription<Iterable<ListItem<T>>> _internalSelectedItemsSubscription;
  StreamSubscription<List<ListItem<T>>> _clearSelectionSubscription;
  StreamSubscription<ListItem> _rendererSelectionSubscription;
  StreamSubscription<List<ListItem<T>>> _selectionStateSubscription;
  StreamSubscription<MouseEvent> _domClickSubscription;
  StreamSubscription<bool> _scrollPositionSubscription;
  StreamSubscription<ItemRendererEvent> _rendererEventSubscription;

  int _pendingScrollTop = 0;

  //-----------------------------
  // constructor
  //-----------------------------

  ListRenderer(
    @Inject(ElementRef) ElementRef elementRef,
    @Inject(ChangeDetectorRef) ChangeDetectorRef changeDetector,
    @Inject(StateService) StateService stateService) :
      this.element = elementRef,
        super(changeDetector, elementRef, stateService) {
          listRendererService.setRenderer(this);

          _initStreams();
        }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<Entity> provideState() => rx.observable(_scroll$ctrl.stream)
    .map((int scrollTop) => new SerializableTuple1<int>()..item1 = scrollTop);

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple1<int> tuple = entity as SerializableTuple1<int>;

    if (scrollPane != null) {
      scrollPane.nativeElement.scrollTop = tuple.item1;

      if (scrollPane.nativeElement.scrollTop != tuple.item1) {
        _pendingScrollTop = tuple.item1;

        _nextAnimationFrame();
      }
    } else {
      _pendingScrollTop = tuple.item1;
    }
  }

  @override void ngOnChanges(Map<String, SimpleChange> changes) {
    if (changes.containsKey('dataProvider')) changeDetector.markForCheck();

    if (changes.containsKey('selectedItems')) {
      internalSelectedItems.forEach(handleSelection);

      if (selectedItems != null) selectedItems.forEach(handleSelection);

      changeDetector.markForCheck();
    }

    if (changes.containsKey('pageOffset')) {
      if (pageOffset == 0) {
        if (scrollPane != null) scrollPane.nativeElement.scrollTop = 0;

        _initScrollPositionStream();
      }
    }

    if (changes.containsKey('rendererEvents')) listRendererService.respondEvents(rendererEvents);
  }

  @override
  void ngOnDestroy() {
    super.ngOnDestroy();

    _internalSelectedItemsSubscription?.cancel();
    _rendererSelectionSubscription?.cancel();
    _selectionStateSubscription?.cancel();
    _domClickSubscription?.cancel();
    _rendererEventSubscription?.cancel();
    _clearSelectionSubscription?.cancel();
  }

  @override void ngAfterViewInit() {
    _domClickSubscription = window.onMouseDown.listen((MouseEvent event) {
      Node target = event.target as Node;

      while (target != null && target.parentNode != window) {
        if (target is Element && target == element.nativeElement) return;

        target = target.parentNode;
      }

      _requestClose$ctrl.add(true);
    });

    scrollPane.nativeElement.scrollTop = _pendingScrollTop;

    if (scrollPane != null) _nextAnimationFrame();

    _initScrollPositionStream();
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initScrollPositionStream() {
    if (scrollPane != null) {
      if (_scrollPositionSubscription != null) _scrollPositionSubscription.cancel();

      _scrollPositionSubscription = rx.observable(scrollPane.nativeElement.onScroll)
        .map((_) => scrollPane.nativeElement.scrollTop)
        .tap(_scroll$ctrl.add)
        .map((int scrollTop) => new Tuple2<int, bool>(scrollPane.nativeElement.scrollHeight, scrollTop >= scrollPane.nativeElement.scrollHeight - scrollPane.nativeElement.clientHeight - 20))
        .where((Tuple2<int, bool> tuple) => tuple.item2)
        .max((Tuple2<int, bool> tA, Tuple2<int, bool> tB) => (tA.item1 > tB.item1) ? 1 : -1)
        .map((Tuple2<int, bool> tuple) => tuple.item2)
        .listen(_scrolledToBottom$ctrl.add);
    }
  }

  void _initStreams() {
    _internalSelectedItemsSubscription = _selectedItems$ctrl.stream.listen((Iterable<ListItem<T>> items) {
      internalSelectedItems = items;

      listRendererService.respondEvents(<ListRendererEvent<Iterable<ListItem<T>>, Comparable>>[new ListRendererEvent<Iterable<ListItem<T>>, Comparable>('selectionChanged', null, items)]);

      changeDetector.markForCheck();
    });

    _selectedItems$ = new rx.Observable<List<ListItem<T>>>.zip(<Stream>[
      _incomingSelection$ctrl.stream,
      rx.observable(_selectedItems$ctrl.stream)
        .startWith(<Iterable<ListItem<T>>>[internalSelectedItems])
    ], (ListItem<T> incoming, Iterable<ListItem<T>> currentList) {
      if (incoming == null) return new List<ListItem<T>>.unmodifiable(const []);

      List<ListItem<T>> newList = currentList.toList(growable: true);

      final ListItem<T> match = newList.firstWhere((ListItem<T> listItem) => listItem.compareTo(incoming) == 0, orElse: () => null);

      if (allowMultiSelection) {
        if (match != null) newList.remove(match);
        else newList.add(incoming);
      } else {
        if (match != null) newList = <ListItem<T>>[];
        else newList = <ListItem<T>>[incoming];
      }

      return new List<ListItem<T>>.unmodifiable(newList);
    }, asBroadcastStream: true);

    _clearSelectionSubscription = new rx.Observable<Iterable<ListItem<T>>>.combineLatest([
      _clearSelection$ctrl.stream,
      _selectedItems$.startWith(const [])
    ], (ClearSelectionWhereHandler handler, List<ListItem<T>> selectedItems) => selectedItems.where(handler))
      .where((Iterable<ListItem<T>> items) => items.isNotEmpty)
      .listen((Iterable<ListItem<T>> items) => items.forEach(_incomingSelection$ctrl.add)) as StreamSubscription<List<ListItem<T>>>;

    _rendererSelectionSubscription = listRendererService.rendererSelection$
      .listen((ListItem listItem) => handleSelection(listItem as ListItem<T>));

    _selectionStateSubscription = _selectedItems$.listen(_selectedItems$ctrl.add);

    _rendererEventSubscription = listRendererService.event$
      .listen(_itemRendererEvent$ctrl.add);
  }

  void _nextAnimationFrame() {
    window.animationFrame.then((num time) {
      final int scrollTop = math.min(scrollPane.nativeElement.scrollHeight - scrollPane.nativeElement.clientHeight, _pendingScrollTop);

      scrollPane.nativeElement.scrollTop = scrollTop;

      changeDetector.markForCheck();

      if (scrollPane.nativeElement.scrollTop != _pendingScrollTop) _nextAnimationFrame();
    });
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void clearSelection(ClearSelectionWhereHandler clearSelectionWhereHandler) => _clearSelection$ctrl.add(clearSelectionWhereHandler);

  bool isSelected(ListItem<T> listItem) {
    if (listItem == null || internalSelectedItems == null) return false;

    for (int i=0, len=internalSelectedItems.length; i<len; i++) {
      final ListItem<T> item  = internalSelectedItems.elementAt(i);

      if (item != null && listItem.compareTo(item) == 0) return true;
    }

    return false;
  }

  void handleSelection(ListItem<Comparable> listItem) {
    _clearSelection$ctrl.add((ListItem listItem) => false);
    _incomingSelection$ctrl.add(listItem);
  }

  String getHierarchyOffset(ListItem<T> listItem) {
    int offset = 0;

    while (listItem.parent != null) {
      listItem = listItem.parent;

      offset += childOffset;
    }

    return '${offset}px';
  }

}