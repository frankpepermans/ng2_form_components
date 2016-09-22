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

typedef bool IsSelectedHandler(ListItem<Comparable<dynamic>> listItem);
typedef bool ClearSelectionWhereHandler(ListItem<Comparable<dynamic>> listItem);
typedef dynamic NgForTracker(int index, ListItem<Comparable<dynamic>> listItem);

@Pipe(name: 'selectedItems')
@Injectable()
class SelectedItemsPipe<T extends Comparable<dynamic>> implements PipeTransform {

  const SelectedItemsPipe();

  List<ListItem<T>> transform(List<ListItem<T>> dataProvider, Function handler, bool moveSelectionOnTop) {
    if (!moveSelectionOnTop) return const [];

    return dataProvider.where((ListItem<T> listItem) => listItem != null && handler(listItem)).toList(growable: false);
  }
}

@Pipe(name: 'unselectedItems')
@Injectable()
class UnselectedItemsPipe<T extends Comparable<dynamic>> implements PipeTransform {

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
    pipes: const <Type>[SelectedItemsPipe, UnselectedItemsPipe],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class ListRenderer<T extends Comparable<dynamic>> extends FormComponent<T> implements OnChanges, OnDestroy, AfterViewInit {

  ElementRef _scrollPane;
  ElementRef get scrollPane => _scrollPane;
  @ViewChild('scrollPane') set scrollPane(ElementRef value) {
    _scrollPane = value;
  }

  //-----------------------------
  // input
  //-----------------------------

  LabelHandler _labelHandler;
  LabelHandler get labelHandler => _labelHandler;
  @Input() set labelHandler(LabelHandler value) {
    _labelHandler = value;
  }

  ListDragDropHandler _dragDropHandler;
  ListDragDropHandler get dragDropHandler => _dragDropHandler;
  @Input() set dragDropHandler(ListDragDropHandler value) {
    _dragDropHandler = value;
  }

  NgForTracker _ngForTracker;
  NgForTracker get ngForTracker => _ngForTracker;
  @Input() set ngForTracker(NgForTracker value) {
    _ngForTracker = value;
  }

  ResolveRendererHandler _resolveRendererHandler = (_, [__]) => DefaultListItemRenderer;
  ResolveRendererHandler get resolveRendererHandler => _resolveRendererHandler;
  @Input() set resolveRendererHandler(ResolveRendererHandler value) {
    _resolveRendererHandler = value;
  }

  List<ListItem<T>> _dataProvider = <ListItem<T>>[];
  List<ListItem<T>> get dataProvider => _dataProvider;
  @Input() set dataProvider(List<ListItem<T>> value) {
    _dataProvider = value;

    _dataProvider$ctrl.add(value);
  }

  List<ListItem<T>> _selectedItems = <ListItem<T>>[];
  List<ListItem<T>> get selectedItems => _selectedItems;
  @Input() set selectedItems(List<ListItem<T>> value) {
    _selectedItems = value;
  }

  bool _allowMultiSelection = false;
  bool get allowMultiSelection => _allowMultiSelection;
  @Input() set allowMultiSelection(bool value) {
    _allowMultiSelection = value;
  }

  bool _moveSelectionOnTop = false;
  bool get moveSelectionOnTop => _moveSelectionOnTop;
  @Input() set moveSelectionOnTop(bool value) {
    _moveSelectionOnTop = value;
  }

  int _childOffset = 20;
  int get childOffset => _childOffset;
  @Input() set childOffset(int value) {
    _childOffset = value;
  }

  List<ListRendererEvent<dynamic, Comparable<dynamic>>> _rendererEvents;
  List<ListRendererEvent<dynamic, Comparable<dynamic>>> get rendererEvents => _rendererEvents;
  @Input() set rendererEvents(List<ListRendererEvent<dynamic, Comparable<dynamic>>> value) {
    _rendererEvents = value;
  }

  int _pageOffset = 0;
  int get pageOffset => _pageOffset;
  @Input() set pageOffset(int value) {
    _pageOffset = value;
  }

  String _className = 'ng2-form-components-list-renderer';
  String get className => _className;
  @Input() set className(String value) {
    _className = value;

    cssMap = <String, bool>{value: true};
  }

  ListRendererService _listRendererService = new ListRendererService();
  ListRendererService get listRendererService => _listRendererService;
  @Input() set listRendererService(ListRendererService value) {
    _listRendererService = value;
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output() rx.Observable<List<ListItem<T>>> get selectedItemsChanged => _selectedItems$;
  @Output() Stream<bool> get requestClose => _requestClose$ctrl.stream;
  @Output() Stream<bool> get scrolledToBottom => _scrolledToBottom$ctrl.stream;
  @Output() Stream<ItemRendererEvent<dynamic, Comparable<dynamic>>> get itemRendererEvent => _itemRendererEvent$ctrl.stream;

  Stream<bool> get domChange$ => _domChange$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  Map<String, bool> cssMap = const <String, bool>{'ng2-form-components-list-renderer': true};
  rx.Observable<List<ListItem<T>>> get internalSelectedItemsChanged => _selectedItems$;
  Iterable<ListItem<T>> internalSelectedItems = new List<ListItem<T>>.unmodifiable(const []);

  final ElementRef element;

  rx.Observable<List<ListItem<T>>> _selectedItems$;

  final StreamController<List<ListItem<T>>> _selectedItems$ctrl = new StreamController<List<ListItem<T>>>.broadcast();
  final StreamController<ListItem<T>> _incomingSelection$ctrl = new StreamController<ListItem<T>>();
  final StreamController<bool> _requestClose$ctrl = new StreamController<bool>();
  final StreamController<int> _scroll$ctrl = new StreamController<int>.broadcast();
  final StreamController<bool> _scrolledToBottom$ctrl = new StreamController<bool>.broadcast();
  final StreamController<ItemRendererEvent<dynamic, Comparable<dynamic>>> _itemRendererEvent$ctrl = new StreamController<ItemRendererEvent<dynamic, Comparable<dynamic>>>.broadcast();
  final StreamController<ClearSelectionWhereHandler> _clearSelection$ctrl = new StreamController<ClearSelectionWhereHandler>.broadcast();
  final StreamController<bool> _domChange$ctrl = new StreamController<bool>.broadcast();
  final StreamController<List<ListItem<T>>> _dataProvider$ctrl = new StreamController<List<ListItem<T>>>.broadcast();

  StreamSubscription<Iterable<ListItem<T>>> _internalSelectedItemsSubscription;
  StreamSubscription<List<ListItem<T>>> _clearSelectionSubscription;
  StreamSubscription<ListItem<Comparable<dynamic>>> _rendererSelectionSubscription;
  StreamSubscription<List<ListItem<T>>> _selectionStateSubscription;
  StreamSubscription<MouseEvent> _domClickSubscription;
  StreamSubscription<bool> _scrollPositionSubscription;
  StreamSubscription<ItemRendererEvent<dynamic, Comparable<dynamic>>> _rendererEventSubscription;
  StreamSubscription<bool> _domChangeSubscription;
  StreamSubscription<int> _scrollAfterDataProviderSubscription;

  MutationObserver observer;
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
          _initStreams();
        }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<Entity> provideState() => _scroll$ctrl.stream
    .map((int scrollTop) => new SerializableTuple1<int>()..item1 = scrollTop);

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple1<int> tuple = entity as SerializableTuple1<int>;

    if (scrollPane != null) {
      if (tuple.item1 > 0) {
        scrollPane.nativeElement.scrollTop = tuple.item1;

        if (scrollPane.nativeElement.scrollTop != tuple.item1) {
          _pendingScrollTop = tuple.item1;

          _initDomChangeListener();
        }
      }
    } else {
      _pendingScrollTop = tuple.item1;
    }
  }

  @override void ngOnChanges(Map<String, SimpleChange> changes) {
    //bool doMarkForCheck = false;

    //if (changes.containsKey('dataProvider')) doMarkForCheck = true;

    if (changes.containsKey('selectedItems')) {
      internalSelectedItems.forEach(handleSelection);

      if (selectedItems != null) selectedItems.forEach(handleSelection);

      //doMarkForCheck = true;
    }

    if (changes.containsKey('pageOffset')) {
      if (pageOffset == 0) {
        if (scrollPane != null) scrollPane.nativeElement.scrollTop = 0;

        _initScrollPositionStream();
      }
    }

    if (changes.containsKey('rendererEvents')) listRendererService.respondEvents(rendererEvents);

    //if (doMarkForCheck) changeDetector.markForCheck();
  }

  @override
  void ngOnDestroy() {
    super.ngOnDestroy();

    observer.disconnect();

    _internalSelectedItemsSubscription?.cancel();
    _rendererSelectionSubscription?.cancel();
    _selectionStateSubscription?.cancel();
    _domClickSubscription?.cancel();
    _rendererEventSubscription?.cancel();
    _clearSelectionSubscription?.cancel();
    _domChangeSubscription?.cancel();
    _scrollAfterDataProviderSubscription.cancel();

    listRendererService.removeRenderer(this);

    _selectedItems$ctrl.close();
    _incomingSelection$ctrl.close();
    _requestClose$ctrl.close();
    _scroll$ctrl.close();
    _scrolledToBottom$ctrl.close();
    _itemRendererEvent$ctrl.close();
    _clearSelection$ctrl.close();
    _domChange$ctrl.close();
    _dataProvider$ctrl.close();
  }

  @override void ngAfterViewInit() {
    listRendererService.addRenderer(this);

    _domClickSubscription = window.onMouseDown.listen((MouseEvent event) {
      Node target = event.target as Node;

      while (target != null && target.parentNode != window) {
        if (target is Element && target == element.nativeElement) return;

        target = target.parentNode;
      }

      _requestClose$ctrl.add(true);
    });

    if (_pendingScrollTop > 0) scrollPane.nativeElement.scrollTop = _pendingScrollTop;

    if (scrollPane != null) _initDomChangeListener();

    _initScrollPositionStream();
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initDomChangeListener() {
    _domChangeSubscription?.cancel();

    _domChangeSubscription = null;

    if (_pendingScrollTop > 0 && scrollPane != null) _domChangeSubscription = rx.observable(_domChange$ctrl.stream)
      .timeout(const Duration(seconds: 3), onTimeout: (_) {
        _domChangeSubscription?.cancel();
        observer.disconnect();

        _domChangeSubscription = null;
      })
      .flatMapLatest((bool value) => _animationFrame().take(1).map((_) => value))
      .listen(_attemptRequiredScrollPosition);
  }

  Stream<num> _animationFrame() async* {
    yield await window.animationFrame;
  }

  void scrollIntoView(T entry) {
    listRendererService.respondEvents(
      <ListRendererEvent<T, T>>[
        new ListRendererEvent<T, T>('scrollIntoView', null, entry)
      ]);
  }

  void _initScrollPositionStream() {
    if (scrollPane != null) {
      if (_scrollPositionSubscription != null) _scrollPositionSubscription.cancel();

      _scrollPositionSubscription = rx.observable(scrollPane.nativeElement.onScroll)
        .map((_) => (scrollPane.nativeElement as Element).scrollTop)
        .tap((int scrollTop) {
          if (!_scroll$ctrl.isClosed) _scroll$ctrl.add(scrollTop);
        })
        .map((int scrollTop) => new Tuple2<int, bool>(scrollPane.nativeElement.scrollHeight, scrollTop >= scrollPane.nativeElement.scrollHeight - scrollPane.nativeElement.clientHeight - 20))
        .where((Tuple2<int, bool> tuple) => tuple.item2)
        .max((Tuple2<int, bool> tA, Tuple2<int, bool> tB) => (tA.item1 > tB.item1) ? 1 : -1)
        .map((Tuple2<int, bool> tuple) => tuple.item2)
        .listen((bool value) {
          if (!_scrolledToBottom$ctrl.isClosed) _scrolledToBottom$ctrl.add(value);
        });
    }
  }

  void _initStreams() {
    _internalSelectedItemsSubscription = _selectedItems$ctrl.stream.listen((Iterable<ListItem<T>> items) {
      internalSelectedItems = items;

      listRendererService.respondEvents(<ListRendererEvent<Iterable<ListItem<T>>, Comparable<dynamic>>>[new ListRendererEvent<Iterable<ListItem<T>>, Comparable<dynamic>>('selectionChanged', null, items)]);

      changeDetector.markForCheck();
    });

    _selectedItems$ = new rx.Observable<List<ListItem<T>>>.zip(<Stream<dynamic>>[
      _incomingSelection$ctrl.stream,
      rx.observable(_selectedItems$ctrl.stream)
        .startWith(<List<ListItem<T>>>[internalSelectedItems as List<ListItem<T>>])
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

    _clearSelectionSubscription = new rx.Observable<Iterable<ListItem<T>>>.combineLatest(<Stream<dynamic>>[
      _clearSelection$ctrl.stream,
      _selectedItems$.startWith(const [const []])
    ], (ClearSelectionWhereHandler handler, List<ListItem<T>> selectedItems) => selectedItems.where(handler))
      .where((Iterable<ListItem<T>> items) => items.isNotEmpty)
      .listen((Iterable<ListItem<T>> items) => items.forEach(_incomingSelection$ctrl.add)) as StreamSubscription<List<ListItem<T>>>;

    _rendererSelectionSubscription = listRendererService.rendererSelection$
      .listen((ListItem<Comparable<dynamic>> listItem) => handleSelection(listItem as ListItem<T>));

    _selectionStateSubscription = _selectedItems$.listen(_selectedItems$ctrl.add);

    _rendererEventSubscription = listRendererService.event$
      .listen(_itemRendererEvent$ctrl.add);

    _scrollAfterDataProviderSubscription = rx.observable(_scroll$ctrl.stream)
      .flatMapLatest((int scrollTop) => _dataProvider$ctrl.stream.map((_) => scrollTop))
      .listen((int scrollTop) {
        scrollPane.nativeElement.scrollTop = scrollTop;

        if (scrollPane.nativeElement.scrollTop != scrollTop) {
          _pendingScrollTop = scrollTop;

          _initDomChangeListener();
        }
    });

    observer = new MutationObserver(notifyDomChanged)
      ..observe(element.nativeElement, subtree: true, childList: true);
  }

  void notifyDomChanged(List<MutationRecord> records, _) {
    if (!_domChange$ctrl.isClosed) _domChange$ctrl.add(true);
  }

  void _attemptRequiredScrollPosition(bool _) {
    final num targetPosition = math.min(scrollPane.nativeElement.scrollHeight - scrollPane.nativeElement.clientHeight, _pendingScrollTop);

    scrollPane.nativeElement.scrollTop = targetPosition;

    if (targetPosition >= _pendingScrollTop) {
      _domChangeSubscription?.cancel();

      _domChangeSubscription = null;
    }
  }

  //-----------------------------
  // template methods
  //-----------------------------

  bool isOpen(ListItem<T> listItem) => false;

  void clearSelection(ClearSelectionWhereHandler clearSelectionWhereHandler) {
    if (!_clearSelection$ctrl.isClosed) _clearSelection$ctrl.add(clearSelectionWhereHandler);
  }

  bool isSelected(ListItem<T> listItem) {
    if (listItem == null || internalSelectedItems == null) return false;

    for (int i=0, len=internalSelectedItems.length; i<len; i++) {
      final ListItem<T> item  = internalSelectedItems.elementAt(i);

      if (item != null && listItem.compareTo(item) == 0) {
        return true;
      }
    }

    return false;
  }

  void handleSelection(ListItem<T> listItem) {
    _clearSelection$ctrl.add((_) => false);
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