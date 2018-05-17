library ng2_form_components.components.list_renderer;

import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:rxdart/rxdart.dart' as rx;
import 'package:dorm/dorm.dart';
import 'package:tuple/tuple.dart';
import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';
import 'package:ng2_form_components/src/components/internal/drag_drop_list_item_renderer.dart'
    show DragDropListItemRenderer;
import 'package:ng2_form_components/src/components/list_item.g.dart';

import 'package:ng2_form_components/src/components/item_renderers/default_list_item_renderer.dart'
    show DefaultListItemRenderer;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart'
    show ListRendererService, ItemRendererEvent, ListRendererEvent;

import 'package:ng2_state/ng2_state.dart'
    show SerializableTuple1, StatePhase, StateService, StatefulComponent;

typedef bool IsSelectedHandler(ListItem<Comparable<dynamic>> listItem);
typedef bool ClearSelectionWhereHandler(ListItem<Comparable<dynamic>> listItem);
typedef dynamic NgForTracker(int index, ListItem<Comparable<dynamic>> listItem);
typedef bool SelectedItemsTest(ListItem<Comparable<dynamic>> listItem);

@Pipe('selectedItems')
@Injectable()
class SelectedItemsPipe<T extends Comparable<dynamic>>
    implements PipeTransform {
  const SelectedItemsPipe();

  List<ListItem<T>> transform(List<ListItem<T>> dataProvider,
      SelectedItemsTest handler, bool moveSelectionOnTop) {
    if (!moveSelectionOnTop) return const [];

    return dataProvider
        .where((ListItem<T> listItem) => listItem != null && handler(listItem))
        .toList(growable: false);
  }
}

@Pipe('unselectedItems')
@Injectable()
class UnselectedItemsPipe<T extends Comparable<dynamic>>
    implements PipeTransform {
  const UnselectedItemsPipe();

  List<ListItem<T>> transform(List<ListItem<T>> dataProvider,
      SelectedItemsTest handler, bool moveSelectionOnTop) {
    if (!moveSelectionOnTop) return dataProvider;

    return dataProvider
        .where((ListItem<T> listItem) => listItem != null && !handler(listItem))
        .toList(growable: false);
  }
}

@Component(
    selector: 'list-renderer',
    templateUrl: 'list_renderer.html',
    directives: const <dynamic>[coreDirectives, ListItemRenderer, DragDropListItemRenderer],
    providers: const <dynamic>[
      StateService,
      const Provider<Type>(StatefulComponent, useExisting: ListRenderer)
    ],
    pipes: const <dynamic>[commonPipes, SelectedItemsPipe, UnselectedItemsPipe],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class ListRenderer<T extends Comparable<dynamic>> extends FormComponent<T>
    implements OnDestroy, AfterViewInit {
  Element _scrollPane;
  Element get scrollPane => _scrollPane;
  @ViewChild('scrollPane')
  set scrollPane(Element value) {
    _scrollPane = value;
  }

  //-----------------------------
  // input
  //-----------------------------

  LabelHandler _labelHandler;
  LabelHandler get labelHandler => _labelHandler;
  @Input()
  set labelHandler(LabelHandler value) {
    setState(() => _labelHandler = value);
  }

  ListDragDropHandler _dragDropHandler;
  ListDragDropHandler get dragDropHandler => _dragDropHandler;
  @Input()
  set dragDropHandler(ListDragDropHandler value) {
    setState(() => _dragDropHandler = value);
  }

  NgForTracker _ngForTracker;
  NgForTracker get ngForTracker => _ngForTracker;
  @Input()
  set ngForTracker(NgForTracker value) {
    setState(() => _ngForTracker = value);
  }

  ResolveRendererHandler _resolveRendererHandler =
      (_, [__]) => DefaultListItemRenderer;
  ResolveRendererHandler get resolveRendererHandler => _resolveRendererHandler;
  @Input()
  set resolveRendererHandler(ResolveRendererHandler value) {
    setState(() => _resolveRendererHandler = value);
  }

  List<ListItem<T>> _dataProvider = <ListItem<T>>[];
  List<ListItem<T>> get dataProvider => _dataProvider;
  @Input()
  set dataProvider(List<ListItem<T>> value) {
    _dataProvider$ctrl.add(value);
  }

  List<ListItem<T>> _selectedItems = <ListItem<T>>[];
  List<ListItem<T>> get selectedItems => _selectedItems;
  @Input()
  set selectedItems(List<ListItem<T>> value) {
    setState(() => _selectedItems = value);

    internalSelectedItems?.forEach(handleSelection);
    selectedItems?.forEach(handleSelection);
  }

  bool _allowMultiSelection = false;
  bool get allowMultiSelection => _allowMultiSelection;
  @Input()
  set allowMultiSelection(bool value) {
    setState(() => _allowMultiSelection = value);
  }

  bool _moveSelectionOnTop = false;
  bool get moveSelectionOnTop => _moveSelectionOnTop;
  @Input()
  set moveSelectionOnTop(bool value) {
    setState(() => _moveSelectionOnTop = value);
  }

  int _childOffset = 20;
  int get childOffset => _childOffset;
  @Input()
  set childOffset(int value) {
    setState(() => _childOffset = value);
  }

  List<ListRendererEvent<dynamic, Comparable<dynamic>>> _rendererEvents;
  List<ListRendererEvent<dynamic, Comparable<dynamic>>> get rendererEvents =>
      _rendererEvents;
  @Input()
  set rendererEvents(
      List<ListRendererEvent<dynamic, Comparable<dynamic>>> value) {
    setState(() => _rendererEvents = value);

    listRendererService?.respondEvents(rendererEvents);
  }

  int _pageOffset = 0;
  int get pageOffset => _pageOffset;
  @Input()
  set pageOffset(int value) {
    setState(() => _pageOffset = value);

    if (value == 0) {
      scrollPane?.scrollTop = 0;

      _initScrollPositionStream();
    }
  }

  String _className = 'ng2-form-components-list-renderer';
  String get className => _className;
  @Input()
  set className(String value) {
    _className = value;

    cssMap = <String, bool>{value: true};
  }

  bool _closeListRendererService = true;
  ListRendererService _listRendererService = new ListRendererService();
  ListRendererService get listRendererService => _listRendererService;
  @Input()
  set listRendererService(ListRendererService value) {
    _listRendererService?.close();

    if (value != null) _closeListRendererService = false;

    setState(() => _listRendererService = value);
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output()
  rx.Observable<List<ListItem<T>>> get selectedItemsChanged => _selectedItems$;
  @Output()
  Stream<bool> get requestClose => _requestClose$ctrl.stream;
  @Output()
  Stream<bool> get scrolledToBottom => _scrolledToBottom$ctrl.stream;
  @Output()
  Stream<ItemRendererEvent<dynamic, Comparable<dynamic>>>
      get itemRendererEvent => _itemRendererEvent$ctrl.stream;
  @Output()
  Stream<bool> get willUpdate => _willUpdateController.stream;

  Stream<bool> get domChange$ => _domChange$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  Map<String, bool> cssMap = const <String, bool>{
    'ng2-form-components-list-renderer': true
  };
  rx.Observable<List<ListItem<T>>> get internalSelectedItemsChanged =>
      _selectedItems$;
  Iterable<ListItem<T>> internalSelectedItems =
      new List<ListItem<T>>.unmodifiable(const <ListItem<Comparable<dynamic>>>[]);

  final Element element;

  rx.Observable<List<ListItem<T>>> _selectedItems$;

  final StreamController<List<ListItem<T>>> _selectedItems$ctrl =
      new StreamController<List<ListItem<T>>>.broadcast();
  final StreamController<ListItem<T>> _incomingSelection$ctrl =
      new StreamController<ListItem<T>>();
  final StreamController<bool> _requestClose$ctrl =
          new StreamController<bool>(),
      _willUpdateController = new StreamController<bool>.broadcast(),
      _scrolledToBottom$ctrl = new StreamController<bool>.broadcast(),
      _domChange$ctrl = new StreamController<bool>.broadcast();
  final StreamController<int> _scroll$ctrl =
      new StreamController<int>.broadcast();
  final StreamController<ItemRendererEvent<dynamic, Comparable<dynamic>>>
      _itemRendererEvent$ctrl = new StreamController<
          ItemRendererEvent<dynamic, Comparable<dynamic>>>.broadcast();
  final StreamController<ClearSelectionWhereHandler> _clearSelection$ctrl =
      new StreamController<ClearSelectionWhereHandler>.broadcast();
  final StreamController<List<ListItem<T>>> _dataProvider$ctrl =
      new StreamController<List<ListItem<T>>>.broadcast();
  final StreamController<ItemRendererEvent<int, Comparable<dynamic>>>
      _dropEffect$ctrl = new StreamController<
          ItemRendererEvent<int, Comparable<dynamic>>>.broadcast();

  StreamSubscription<List<ListItem<T>>> _dataProviderSubscription;
  StreamSubscription<Iterable<ListItem<T>>> _internalSelectedItemsSubscription;
  StreamSubscription<Iterable<ListItem<T>>> _clearSelectionSubscription;
  StreamSubscription<ListItem<Comparable<dynamic>>>
      _rendererSelectionSubscription;
  StreamSubscription<Iterable<ListItem<T>>> _selectionStateSubscription;
  StreamSubscription<MouseEvent> _domClickSubscription;
  StreamSubscription<bool> _scrollPositionSubscription;
  StreamSubscription<ItemRendererEvent<dynamic, Comparable<dynamic>>>
      _rendererEventSubscription;
  StreamSubscription<dynamic> _domChangeSubscription;
  StreamSubscription<int> _scrollAfterDataProviderSubscription;
  StreamSubscription<ItemRendererEvent<dynamic, Comparable<dynamic>>>
      _itemRendererEventSubscription;
  StreamSubscription<ItemRendererEvent<int, Comparable<dynamic>>>
      _dropEffectSubscription;

  MutationObserver observer;
  int _pendingScrollTop = 0;

  //-----------------------------
  // constructor
  //-----------------------------

  ListRenderer(@Inject(Element) Element elementRef)
      : this.element = elementRef,
        super(elementRef) {
    _initStreams();
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override
  Stream<Entity> provideState() => _scroll$ctrl.stream
      .map((int scrollTop) => new SerializableTuple1<int>()..item1 = scrollTop);

  @override
  void receiveState(covariant Entity entity, StatePhase phase) {
    final SerializableTuple1<int> tuple = entity as SerializableTuple1<int>;

    if (scrollPane != null) {
      if (tuple.item1 > 0) {
        scrollPane.scrollTop = tuple.item1;

        if (scrollPane.scrollTop != tuple.item1) {
          _pendingScrollTop = tuple.item1;

          _initDomChangeListener();
        }
      }
    } else {
      _pendingScrollTop = tuple.item1;
    }
  }

  @override
  void ngOnDestroy() {
    super.ngOnDestroy();

    observer?.disconnect();

    listRendererService.removeRenderer(this);

    if (_closeListRendererService) _listRendererService.close();

    _dataProviderSubscription?.cancel();
    _internalSelectedItemsSubscription?.cancel();
    _rendererSelectionSubscription?.cancel();
    _selectionStateSubscription?.cancel();
    _domClickSubscription?.cancel();
    _rendererEventSubscription?.cancel();
    _clearSelectionSubscription?.cancel();
    _domChangeSubscription?.cancel();
    _scrollAfterDataProviderSubscription.cancel();
    _itemRendererEventSubscription?.cancel();
    _dropEffectSubscription?.cancel();

    _selectedItems$ctrl.close();
    _incomingSelection$ctrl.close();
    _requestClose$ctrl.close();
    _scroll$ctrl.close();
    _scrolledToBottom$ctrl.close();
    _itemRendererEvent$ctrl.close();
    _clearSelection$ctrl.close();
    _domChange$ctrl.close();
    _dataProvider$ctrl.close();
    _dropEffect$ctrl.close();
    _willUpdateController.close();
  }

  @override
  void ngAfterViewInit() {
    listRendererService.addRenderer(this);

    observer = new MutationObserver(notifyDomChanged)
      ..observe(element,
          subtree: true, childList: true, attributes: false);

    _domClickSubscription = window.onMouseDown.listen((MouseEvent event) {
      Node target = event.target as Node;

      while (target != null && target.parentNode != window) {
        if (target is Element && target == element) return;

        target = target.parentNode;
      }

      _requestClose$ctrl.add(true);
    });

    if (_pendingScrollTop > 0)
      scrollPane.scrollTop = _pendingScrollTop;

    if (scrollPane != null) _initDomChangeListener();

    _initScrollPositionStream();
  }

  //-----------------------------
  // private methods
  //-----------------------------

  void _initDomChangeListener() {
    _domChangeSubscription?.cancel();

    _domChangeSubscription = null;

    if (_pendingScrollTop > 0 && scrollPane != null)
      _domChangeSubscription = new rx.Observable<bool>(_domChange$ctrl.stream)
          .timeout(const Duration(seconds: 3), onTimeout: (_) {
            _domChangeSubscription?.cancel();
            observer.disconnect();

            _domChangeSubscription = null;
          })
          .asyncMap((_) => window.animationFrame)
          .listen(_attemptRequiredScrollPosition);
  }

  void scrollIntoView(T entry) {
    listRendererService.respondEvents(<ListRendererEvent<T, T>>[
      new ListRendererEvent<T, T>('scrollIntoView', null, entry)
    ]);
  }

  void _initScrollPositionStream() {
    if (scrollPane != null) {
      if (_scrollPositionSubscription != null)
        _scrollPositionSubscription.cancel();

      final Element scrollPaneElement = scrollPane;

      _scrollPositionSubscription =
          new rx.Observable<Event>(scrollPaneElement.onScroll)
              .map((_) => scrollPaneElement.scrollTop)
              .doOnData((int scrollTop) {
                if (!_scroll$ctrl.isClosed) _scroll$ctrl.add(scrollTop);
              })
              .map((int scrollTop) => new Tuple2<int, bool>(
                  scrollPaneElement.scrollHeight,
                  scrollTop >=
                      scrollPaneElement.scrollHeight -
                          scrollPaneElement.clientHeight -
                          20))
              .where((Tuple2<int, bool> tuple) => tuple.item2)
              .max((Tuple2<int, bool> tA, Tuple2<int, bool> tB) =>
                  (tA.item1 > tB.item1) ? 1 : -1)
              .asStream()
              .map((Tuple2<int, bool> tuple) => tuple.item2)
              .listen((bool value) {
                if (!_scrolledToBottom$ctrl.isClosed)
                  _scrolledToBottom$ctrl.add(value);
              });
    }
  }

  void _initStreams() {
    _dataProviderSubscription =
        _dataProvider$ctrl.stream.listen((List<ListItem<T>> dataProvider) {
      if (dataProvider != _dataProvider) {
        setState(() {
          _willUpdateController.add(true);

          _dataProvider = dataProvider;
        });
      }
    });

    _internalSelectedItemsSubscription =
        _selectedItems$ctrl.stream.listen((Iterable<ListItem<T>> items) {
      listRendererService.respondEvents(<
          ListRendererEvent<Iterable<ListItem<T>>, Comparable<dynamic>>>[
        new ListRendererEvent<Iterable<ListItem<T>>, Comparable<dynamic>>(
            'selectionChanged', null, items)
      ]);

      setState(() {
        internalSelectedItems = items;

        listRendererService.respondEvents(<ListRendererEvent<T, T>>[
          new ListRendererEvent<T, T>('selectionChanged', null, null)
        ]);
      });
    });

    _selectedItems$ = rx.Observable.zip2(
        _incomingSelection$ctrl.stream,
        new rx.Observable<List<ListItem<T>>>(_selectedItems$ctrl.stream)
            .startWith(internalSelectedItems as List<ListItem<T>>),
        (ListItem<T> incoming, Iterable<ListItem<T>> currentList) {
      if (incoming == null)
        return new List<ListItem<T>>.unmodifiable(const <ListItem<Comparable<dynamic>>>[]);

      List<ListItem<T>> newList = currentList.toList(growable: true);

      final ListItem<T> match = newList.firstWhere(
          (ListItem<T> listItem) => listItem.compareTo(incoming) == 0,
          orElse: () => null);

      if (allowMultiSelection) {
        if (match != null)
          newList.remove(match);
        else
          newList.add(incoming);
      } else {
        if (match != null)
          newList = <ListItem<T>>[];
        else
          newList = <ListItem<T>>[incoming];
      }

      return new List<ListItem<T>>.unmodifiable(newList);
    }).asBroadcastStream();

    _clearSelectionSubscription = rx.Observable
        .combineLatest2(
            _clearSelection$ctrl.stream,
            _selectedItems$.startWith(const []),
            (ClearSelectionWhereHandler handler,
                    List<ListItem<T>> selectedItems) =>
                selectedItems.where(handler))
        .where((Iterable<ListItem<T>> items) => items.isNotEmpty)
        .listen((Iterable<ListItem<T>> items) =>
            items.forEach(_incomingSelection$ctrl.add));

    _rendererSelectionSubscription = listRendererService.rendererSelection$
        .listen((ListItem<Comparable<dynamic>> listItem) =>
            handleSelection(listItem as ListItem<T>));

    _selectionStateSubscription =
        _selectedItems$.listen(_selectedItems$ctrl.add);

    _rendererEventSubscription =
        listRendererService.event$.listen(_itemRendererEvent$ctrl.add);

    _scrollAfterDataProviderSubscription =
        new rx.Observable<int>(_scroll$ctrl.stream)
            .switchMap((int scrollTop) =>
                _dataProvider$ctrl.stream.map((_) => scrollTop))
            .listen((int scrollTop) {
      scrollPane.scrollTop = scrollTop;

      if (scrollPane.scrollTop != scrollTop) {
        _pendingScrollTop = scrollTop;

        _initDomChangeListener();
      }
    });

    _itemRendererEventSubscription =
        _itemRendererEvent$ctrl.stream.listen(_handleItemRendererEvent);

    _dropEffectSubscription = rx.Observable
        .combineLatest3(
            _dataProvider$ctrl.stream,
            _dropEffect$ctrl.stream,
            _domChange$ctrl.stream,
            (dynamic _,
                    ItemRendererEvent<int, Comparable<dynamic>> dropEffectEvent,
                    dynamic __) =>
                dropEffectEvent)
        .listen(listRendererService.triggerEvent);
  }

  void _handleItemRendererEvent(
      ItemRendererEvent<dynamic, Comparable<dynamic>> event) {
    if (event.type == 'dropEffectRequest')
      _dropEffect$ctrl.add(new ItemRendererEvent<int, Comparable<dynamic>>(
          'dropEffect', event.listItem, event.data as int));
  }

  void notifyDomChanged(List<MutationRecord> records, dynamic _) {
    if (!_domChange$ctrl.isClosed) _domChange$ctrl.add(true);
  }

  void _attemptRequiredScrollPosition(dynamic _) {
    final Element scrollPaneElement = scrollPane;
    final num targetPosition = math.min(
        scrollPaneElement.scrollHeight - scrollPaneElement.clientHeight,
        _pendingScrollTop);

    scrollPane.scrollTop = targetPosition;

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
    if (!_clearSelection$ctrl.isClosed)
      _clearSelection$ctrl.add(clearSelectionWhereHandler);
  }

  bool isSelected(ListItem<T> listItem) {
    if (listItem == null || internalSelectedItems == null) return false;

    for (int i = 0, len = internalSelectedItems.length; i < len; i++) {
      final ListItem<T> item = internalSelectedItems.elementAt(i);

      if (item != null && listItem.compareTo(item) == 0) {
        return true;
      }
    }

    return false;
  }

  void handleSelection(ListItem<T> listItem) {
    if (!_clearSelection$ctrl.isClosed) _clearSelection$ctrl.add((_) => false);
    if (!_incomingSelection$ctrl.isClosed)
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
