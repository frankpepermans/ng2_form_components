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

import 'package:ng2_form_components/src/components/item_renderers/default_list_item_renderer.template.dart'
    as ir;

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
class SelectedItemsPipe
    implements PipeTransform {
  const SelectedItemsPipe();

  List<ListItem<Comparable<dynamic>>> transform(List<ListItem<Comparable<dynamic>>> dataProvider,
      SelectedItemsTest handler, bool moveSelectionOnTop) {
    if (!moveSelectionOnTop) return const [];

    return dataProvider
        .where((ListItem<Comparable<dynamic>> listItem) => listItem != null && handler(listItem))
        .toList(growable: false);
  }
}

@Pipe('unselectedItems')
@Injectable()
class UnselectedItemsPipe
    implements PipeTransform {
  const UnselectedItemsPipe();

  List<ListItem<Comparable<dynamic>>> transform(List<ListItem<Comparable<dynamic>>> dataProvider,
      SelectedItemsTest handler, bool moveSelectionOnTop) {
    if (!moveSelectionOnTop) return dataProvider;

    return dataProvider
        .where((ListItem<Comparable<dynamic>> listItem) => listItem != null && !handler(listItem))
        .toList(growable: false);
  }
}

@Component(
    selector: 'list-renderer',
    templateUrl: 'list_renderer.html',
    directives: const <dynamic>[
      coreDirectives,
      ListItemRenderer,
      DragDropListItemRenderer
    ],
    providers: const <dynamic>[
      StateService,
      const ExistingProvider.forToken(
          const OpaqueToken('statefulComponent'), ListRenderer)
    ],
    pipes: const <dynamic>[commonPipes, SelectedItemsPipe, UnselectedItemsPipe],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class ListRenderer extends FormComponent
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

  LabelHandler<Comparable<dynamic>> _labelHandler;
  LabelHandler<Comparable<dynamic>> get labelHandler => _labelHandler;
  @Input()
  set labelHandler(LabelHandler<Comparable<dynamic>> value) {
    if (_labelHandler != value) setState(() => _labelHandler = value);
  }

  ListDragDropHandler _dragDropHandler;
  ListDragDropHandler get dragDropHandler => _dragDropHandler;
  @Input()
  set dragDropHandler(ListDragDropHandler value) {
    if (_dragDropHandler != value) setState(() => _dragDropHandler = value);
  }

  NgForTracker _ngForTracker;
  NgForTracker get ngForTracker => _ngForTracker;
  @Input()
  set ngForTracker(NgForTracker value) {
    if (_ngForTracker != value) setState(() => _ngForTracker = value);
  }

  ResolveRendererHandler _resolveRendererHandler =
      (_, [__]) => ir.DefaultListItemRendererNgFactory;
  ResolveRendererHandler get resolveRendererHandler => _resolveRendererHandler;
  @Input()
  set resolveRendererHandler(ResolveRendererHandler value) {
    if (_resolveRendererHandler != value)
      setState(() => _resolveRendererHandler = value);
  }

  List<ListItem<Comparable<dynamic>>> _dataProvider = <ListItem<Comparable<dynamic>>>[];
  List<ListItem<Comparable<dynamic>>> get dataProvider => _dataProvider;
  @Input()
  set dataProvider(List<ListItem<Comparable<dynamic>>> value) {
    if (distinctDataProvider(_dataProvider$ctrl.value, value)) {
      _dataProvider$ctrl.add(value);
    }
  }

  List<ListItem<Comparable<dynamic>>> _selectedItems = <ListItem<Comparable<dynamic>>>[];
  List<ListItem<Comparable<dynamic>>> get selectedItems => _selectedItems;
  @Input()
  set selectedItems(List<ListItem<Comparable<dynamic>>> value) {
    if (distinctDataProvider(_selectedItems, value)) {
      setState(() => _selectedItems = value);

      internalSelectedItems?.forEach(handleSelection);
      selectedItems?.forEach(handleSelection);
    }
  }

  bool _allowMultiSelection = false;
  bool get allowMultiSelection => _allowMultiSelection;
  @Input()
  set allowMultiSelection(bool value) {
    if (_allowMultiSelection != value)
      setState(() => _allowMultiSelection = value);
  }

  bool _moveSelectionOnTop = false;
  bool get moveSelectionOnTop => _moveSelectionOnTop;
  @Input()
  set moveSelectionOnTop(bool value) {
    if (_moveSelectionOnTop != value)
      setState(() => _moveSelectionOnTop = value);
  }

  int _childOffset = 20;
  int get childOffset => _childOffset;
  @Input()
  set childOffset(int value) {
    if (_childOffset != value) setState(() => _childOffset = value);
  }

  List<ListRendererEvent<dynamic, Comparable<dynamic>>> _rendererEvents;
  List<ListRendererEvent<dynamic, Comparable<dynamic>>> get rendererEvents =>
      _rendererEvents;
  @Input()
  set rendererEvents(
      List<ListRendererEvent<dynamic, Comparable<dynamic>>> value) {
    if (_rendererEvents != value) {
      setState(() => _rendererEvents = value);

      listRendererService?.respondEvents(rendererEvents);
    }
  }

  int _pageOffset = 0;
  int get pageOffset => _pageOffset;
  @Input()
  set pageOffset(int value) {
    if (_pageOffset != value) {
      setState(() => _pageOffset = value);

      if (value == 0) {
        scrollPane?.scrollTop = 0;

        _initScrollPositionStream();
      }
    }
  }

  String _className = 'ng2-form-components-list-renderer';
  String get className => _className;
  @Input()
  set className(String value) {
    if (_className != value) {
      _className = value;

      cssMap = <String, bool>{value: true};
    }
  }

  bool _closeListRendererService = true;
  ListRendererService _listRendererService = new ListRendererService();
  ListRendererService get listRendererService => _listRendererService;
  @Input()
  set listRendererService(ListRendererService value) {
    if (_listRendererService != value) {
      _listRendererService?.close();

      if (value != null) _closeListRendererService = false;

      setState(() => _listRendererService = value);
    }
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output()
  rx.Observable<List<ListItem<Comparable<dynamic>>>> get selectedItemsChanged => _selectedItems$;
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
  rx.Observable<List<ListItem<Comparable<dynamic>>>> get internalSelectedItemsChanged =>
      _selectedItems$;
  Iterable<ListItem<Comparable<dynamic>>> internalSelectedItems =
      new List<ListItem<Comparable<dynamic>>>.unmodifiable(
          const <ListItem<Comparable<dynamic>>>[]);

  final Element element;

  rx.Observable<List<ListItem<Comparable<dynamic>>>> _selectedItems$;

  final StreamController<List<ListItem<Comparable<dynamic>>>> _selectedItems$ctrl =
      new StreamController<List<ListItem<Comparable<dynamic>>>>.broadcast();
  final StreamController<ListItem<Comparable<dynamic>>> _incomingSelection$ctrl =
      new StreamController<ListItem<Comparable<dynamic>>>();
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
  final rx.BehaviorSubject<List<ListItem<Comparable<dynamic>>>> _dataProvider$ctrl =
      new rx.BehaviorSubject<List<ListItem<Comparable<dynamic>>>>();
  final StreamController<ItemRendererEvent<int, Comparable<dynamic>>>
      _dropEffect$ctrl = new StreamController<
          ItemRendererEvent<int, Comparable<dynamic>>>.broadcast();

  StreamSubscription<List<ListItem<Comparable<dynamic>>>> _dataProviderSubscription;
  StreamSubscription<Iterable<ListItem<Comparable<dynamic>>>> _internalSelectedItemsSubscription;
  StreamSubscription<Iterable<ListItem<Comparable<dynamic>>>> _clearSelectionSubscription;
  StreamSubscription<ListItem<Comparable<dynamic>>>
      _rendererSelectionSubscription;
  StreamSubscription<Iterable<ListItem<Comparable<dynamic>>>> _selectionStateSubscription;
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

  ListRenderer(@Inject(Element) this.element) : super(element) {
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
    final SerializableTuple1 tuple = entity as SerializableTuple1;
    final int item1 = tuple.item1;

    if (scrollPane != null) {
      if (item1 > 0) {
        scrollPane.scrollTop = item1;

        if (scrollPane.scrollTop != item1) {
          _pendingScrollTop = item1;

          _initDomChangeListener();
        }
      }
    } else {
      _pendingScrollTop = item1;
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
      ..observe(element, subtree: true, childList: true, attributes: false);

    _domClickSubscription = window.onMouseDown.listen((MouseEvent event) {
      Node target = event.target as Node;

      while (target != null && target.parentNode != window) {
        if (target is Element && target == element) return;

        target = target.parentNode;
      }

      _requestClose$ctrl.add(true);
    });

    if (_pendingScrollTop > 0) scrollPane.scrollTop = _pendingScrollTop;

    if (scrollPane != null) _initDomChangeListener();

    _initScrollPositionStream();
  }

  //-----------------------------
  // private methods
  //-----------------------------

  bool distinctDataProvider(List<ListItem<Comparable<dynamic>>> current, List<ListItem<Comparable<dynamic>>> next) {
    if (current == null && next == null) return false;
    if (current == null || next == null) return true;
    if (current.length != next.length) return true;

    for (int i = 0, len = next.length; i < len; i++) {
      if (current[i].data != next[i].data) return true;
    }

    return false;
  }

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

  void scrollIntoView(Comparable<dynamic> entry) {
    listRendererService.respondEvents(<ListRendererEvent<Comparable<dynamic>, Comparable<dynamic>>>[
      new ListRendererEvent<Comparable<dynamic>, Comparable<dynamic>>('scrollIntoView', null, entry)
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
              .bufferCount(2, 1)
              .map((List<Tuple2<int, bool>> list) =>
                  (list.first.item1 > list.last.item1) ? list.first : list.last)
              .map((Tuple2<int, bool> tuple) => tuple.item2)
              .debounce(const Duration(milliseconds: 500))
              .listen((bool value) {
                if (!_scrolledToBottom$ctrl.isClosed)
                  _scrolledToBottom$ctrl.add(value);
              });
    }
  }

  void _initStreams() {
    _dataProviderSubscription =
        _dataProvider$ctrl.stream.listen((List<ListItem<Comparable<dynamic>>> dataProvider) {
      if (dataProvider != _dataProvider) {
        setState(() {
          _willUpdateController.add(true);

          _dataProvider = dataProvider;
        });
      }
    });

    _internalSelectedItemsSubscription =
        _selectedItems$ctrl.stream.listen((Iterable<ListItem<Comparable<dynamic>>> items) {
      listRendererService.respondEvents(<
          ListRendererEvent<Iterable<ListItem<Comparable<dynamic>>>, Comparable<dynamic>>>[
        new ListRendererEvent<Iterable<ListItem<Comparable<dynamic>>>, Comparable<dynamic>>(
            'selectionChanged', null, items)
      ]);

      setState(() {
        internalSelectedItems = items;

        listRendererService.respondEvents(<ListRendererEvent<Comparable<dynamic>, Comparable<dynamic>>>[
          new ListRendererEvent<Comparable<dynamic>, Comparable<dynamic>>('selectionChanged', null, null)
        ]);
      });
    });

    _selectedItems$ = rx.Observable.zip2(
        _incomingSelection$ctrl.stream,
        new rx.Observable<List<ListItem<Comparable<dynamic>>>>(_selectedItems$ctrl.stream)
            .startWith(internalSelectedItems as List<ListItem<Comparable<dynamic>>>),
        (ListItem<Comparable<dynamic>> incoming, Iterable<ListItem<Comparable<dynamic>>> currentList) {
      if (incoming == null)
        return new List<ListItem<Comparable<dynamic>>>.unmodifiable(
            const <ListItem<Comparable<dynamic>>>[]);

      List<ListItem<Comparable<dynamic>>> newList = currentList.toList(growable: true);

      final ListItem<Comparable<dynamic>> match = newList.firstWhere(
          (ListItem<Comparable<dynamic>> listItem) => listItem.compareTo(incoming) == 0,
          orElse: () => null);

      if (allowMultiSelection) {
        if (match != null)
          newList.remove(match);
        else
          newList.add(incoming);
      } else {
        if (match != null)
          newList = <ListItem<Comparable<dynamic>>>[];
        else
          newList = <ListItem<Comparable<dynamic>>>[incoming];
      }

      return new List<ListItem<Comparable<dynamic>>>.unmodifiable(newList);
    }).asBroadcastStream();

    _clearSelectionSubscription = rx.Observable
        .combineLatest2(
            _clearSelection$ctrl.stream,
            _selectedItems$.startWith(const []),
            (ClearSelectionWhereHandler handler,
                    List<ListItem<Comparable<dynamic>>> selectedItems) =>
                selectedItems.where(handler))
        .where((Iterable<ListItem<Comparable<dynamic>>> items) => items.isNotEmpty)
        .listen((Iterable<ListItem<Comparable<dynamic>>> items) =>
            items.forEach(_incomingSelection$ctrl.add));

    _rendererSelectionSubscription = listRendererService.rendererSelection$
        .listen((ListItem<Comparable<dynamic>> listItem) =>
            handleSelection(listItem as ListItem<Comparable<dynamic>>));

    _selectionStateSubscription = _selectedItems$.listen((_) {
      _selectedItems$ctrl.add(_);
    });

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

  void notifyDomChanged(List<dynamic> records, dynamic _) {
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

  bool isOpen(ListItem<Comparable<dynamic>> listItem) => false;

  void clearSelection(ClearSelectionWhereHandler clearSelectionWhereHandler) {
    if (!_clearSelection$ctrl.isClosed)
      _clearSelection$ctrl.add(clearSelectionWhereHandler);
  }

  bool isSelected(ListItem<Comparable<dynamic>> listItem) {
    if (listItem == null || internalSelectedItems == null) return false;

    for (int i = 0, len = internalSelectedItems.length; i < len; i++) {
      final ListItem<Comparable<dynamic>> item = internalSelectedItems.elementAt(i);

      if (item != null && listItem.compareTo(item) == 0) {
        return true;
      }
    }

    return false;
  }

  void handleSelection(ListItem<Comparable<dynamic>> listItem) {
    if (!_clearSelection$ctrl.isClosed) _clearSelection$ctrl.add((_) => false);
    if (!_incomingSelection$ctrl.isClosed)
      _incomingSelection$ctrl.add(listItem);
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
}
