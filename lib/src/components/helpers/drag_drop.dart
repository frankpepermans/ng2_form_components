import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';
import 'package:dorm/dorm.dart';

import 'package:ng2_form_components/src/components/list_item.g.dart';
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';

import 'package:ng2_form_components/src/infrastructure/drag_drop_service.dart';

import 'package:ng2_form_components/src/utils/html_helpers.dart';

final SerializerJson<String> _serializer =
    new SerializerJson<String>()
      ..outgoing(const <dynamic>[])
      ..addRule(
          DateTime,
          (int value) => (value != null)
              ? new DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
              : null,
          (DateTime value) => value?.millisecondsSinceEpoch);

@Directive(selector: '[ngDragDrop]', providers: const <Type>[HtmlHelpers])
class DragDrop implements OnDestroy {
  static const num _OFFSET = 11;

  @Input()
  set ngDragDropHandler(ListDragDropHandler handler) =>
      _handler$ctrl.add(handler);
  @Input()
  set ngDragDrop(ListItem<Comparable<dynamic>> listItem) =>
      _listItem$ctrl.add(listItem);

  @Output()
  Stream<DropResult> get onDrop => _onDrop$ctrl.stream;

  final Element elementRef;
  final ChangeDetectorRef changeDetector;
  final DragDropService dragDropService;
  final HtmlHelpers helpers;

  rx.Observable<bool> dragDetection$;
  rx.Observable<bool> dragOver$;
  rx.Observable<bool> dragOut$;

  final StreamController<ListItem<Comparable<dynamic>>> _listItem$ctrl =
      new StreamController<ListItem<Comparable<dynamic>>>();
  final StreamController<ListDragDropHandler> _handler$ctrl =
      new StreamController<ListDragDropHandler>();
  final StreamController<DropResult> _onDrop$ctrl =
      new StreamController<DropResult>.broadcast();
  final StreamController<bool> _removeAllStyles$ctrl =
      new StreamController<bool>.broadcast();

  StreamSubscription<bool> _initSubscription;
  StreamSubscription<MouseEvent> _dropHandlerSubscription;
  StreamSubscription<MouseEvent> _sortHandlerSubscription;
  StreamSubscription<MouseEvent> _dragStartSubscription;
  StreamSubscription<MouseEvent> _dragEndSubscription;
  StreamSubscription<bool> _dragOutSubscription;
  StreamSubscription<ListItem<Comparable<dynamic>>> _swapDropSubscription;
  StreamSubscription<Tuple2<ListItem<Comparable<dynamic>>, int>>
      _sortDropSubscription;

  bool _areStreamsSet = false;
  num heightOnDragEnter = 0;

  DragDrop(
      @Inject(Element) this.elementRef,
      @Inject(ChangeDetectorRef) this.changeDetector,
      @Inject(DragDropService) this.dragDropService,
      @Inject(HtmlHelpers) this.helpers) {
    _initStreams();
  }

  @override
  void ngOnDestroy() {
    _initSubscription?.cancel();
    _dropHandlerSubscription?.cancel();
    _sortHandlerSubscription?.cancel();
    _dragStartSubscription?.cancel();
    _dragEndSubscription?.cancel();
    _dragOutSubscription?.cancel();
    _swapDropSubscription?.cancel();
    _sortDropSubscription?.cancel();

    _listItem$ctrl.close();
    _handler$ctrl.close();
    _onDrop$ctrl.close();
    _removeAllStyles$ctrl.close();
  }

  void _initStreams() {
    _initSubscription = rx.Observable
        .combineLatest3(
            _listItem$ctrl.stream.take(1),
            _handler$ctrl.stream.take(1),
            new rx.Observable<bool>(_removeAllStyles$ctrl.stream)
                .startWith(false),
            _updateStyles)
        .listen(null);
  }

  bool _updateStyles(ListItem<Comparable<dynamic>> listItem,
      ListDragDropHandler handler, bool removeAllStyles) {
    if (listItem != null && handler != null) {
      if (removeAllStyles) {
        final Element element = elementRef;

        helpers.updateElementClasses(
            element, dragDropService.resolveDropClassName(listItem), false);
        helpers.updateElementClasses(element, 'ngDragDrop--drop-inside', false);
        helpers.updateElementClasses(
            element, 'ngDragDrop--sort-handler--above', false);
        helpers.updateElementClasses(
            element, 'ngDragDrop--sort-handler--below', false);
      } else {
        final ListDragDropHandlerType type =
            dragDropService.typeHandler(listItem);

        if (type != ListDragDropHandlerType.NONE) _setupAsDragDrop(listItem);

        if (type == ListDragDropHandlerType.SORT ||
            type == ListDragDropHandlerType.ALL)
          _createSortHandlers(listItem, handler);
        if (type == ListDragDropHandlerType.SWAP ||
            type == ListDragDropHandlerType.ALL)
          _createDropHandler(listItem, handler);
      }
    }

    return true;
  }

  void _setupAsDragDrop(ListItem<Comparable<dynamic>> listItem) {
    if (_areStreamsSet) return;

    final Element element = elementRef;

    _areStreamsSet = true;

    dragDetection$ = new rx.Observable<int>.merge(<Stream<int>>[
      new rx.Observable<MouseEvent>(element.onDragEnter).doOnData((_) {
        heightOnDragEnter = element.client.height;
      }).map((_) => 1),
      element.onDragLeave.map((_) => -1),
      element.onDrop.map((_) => -1)
    ])
        .asBroadcastStream()
        .scan((int acc, int value, _) => acc + value, 0)
        .map((int result) => result > 0)
        .distinct();

    dragOver$ = dragDetection$.where((bool value) => value);

    dragOut$ = dragDetection$.where((bool value) => !value).map((_) => true);

    _dragStartSubscription = element.onDragStart.listen((MouseEvent event) {
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer
          .setData('text/plain', _serializer.outgoing(<Entity>[listItem]));

      helpers.updateElementClasses(element, 'ngDragDrop--active', true);
    });

    _dragEndSubscription = element.onDragEnd.listen((MouseEvent event) {
      helpers.updateElementClasses(element, 'ngDragDrop--active', false);
    });

    _dragOutSubscription = dragOut$.listen(_removeAllStyles);
  }

  void _createDropHandler(
      ListItem<Comparable<dynamic>> listItem, ListDragDropHandler handler) {
    final Element element = elementRef;

    element.setAttribute('draggable', 'true');

    _sortHandlerSubscription = new rx.Observable<MouseEvent>.merge(
            <Stream<MouseEvent>>[element.onDragOver, element.onDragLeave])
        .listen((MouseEvent event) {
      event.preventDefault();

      helpers.updateElementClasses(
          element,
          dragDropService.resolveDropClassName(listItem),
          _isWithinDropBounds(event.client.y));
    });

    _swapDropSubscription = element.onDrop
        .map(_dataTransferToListItem)
        .listen((ListItem<Comparable<dynamic>> droppedListItem) {
      if (droppedListItem.compareTo(listItem) != 0) {
        handler(droppedListItem, listItem, 0);

        _onDrop$ctrl.add(new DropResult(0, listItem));
      }

      _removeAllStyles(null);
    });
  }

  void _createSortHandlers(
      ListItem<Comparable<dynamic>> listItem, ListDragDropHandler handler) {
    final Element element = elementRef;

    element.setAttribute('draggable', 'true');

    _dropHandlerSubscription = element.onDragOver.listen((MouseEvent event) {
      event.preventDefault();

      helpers.updateElementClasses(element, 'ngDragDrop--sort-handler--above',
          _isSortAbove(event.client.y));
      helpers.updateElementClasses(element, 'ngDragDrop--sort-handler--below',
          _isSortBelow(event.client.y));
    });

    _sortDropSubscription = element.onDrop
        .map((MouseEvent event) =>
            new Tuple2<ListItem<Comparable<dynamic>>, int>(
                _dataTransferToListItem(event), _getSortOffset(event)))
        .listen((Tuple2<ListItem<Comparable<dynamic>>, int> tuple) {
      if (tuple.item1.compareTo(listItem) != 0) {
        handler(tuple.item1, listItem, tuple.item2);

        _onDrop$ctrl.add(new DropResult(
            tuple.item2, tuple.item2 == 0 ? listItem : tuple.item1));
      }

      _removeAllStyles(null);
    });
  }

  int _getSortOffset(MouseEvent event) {
    if (_isSortAbove(event.client.y))
      return -1;
    else if (_isSortBelow(event.client.y)) return 1;

    return 0;
  }

  ListItem<Comparable<dynamic>> _dataTransferToListItem(MouseEvent event) {
    final String transferDataEncoded = event.dataTransfer.getData('text/plain');

    if (transferDataEncoded.isEmpty) return null;

    final EntityFactory<Entity> factory = new EntityFactory<Entity>();
    final List<dynamic> result =
        factory.spawn(_serializer.incoming(transferDataEncoded), _serializer);

    return result.first as ListItem<Comparable<dynamic>>;
  }

  void _removeAllStyles(dynamic _) => _removeAllStyles$ctrl.add(true);

  num _getActualOffsetY(Element element, num clientY) => clientY - element.getBoundingClientRect().top;

  bool _isWithinDropBounds(num clientY) {
    final num y =
        _getActualOffsetY(elementRef, clientY);

    return y > _OFFSET && y < heightOnDragEnter - _OFFSET;
  }

  bool _isSortAbove(num clientY) =>
      _getActualOffsetY(elementRef, clientY) <=
      _OFFSET;

  bool _isSortBelow(num clientY) =>
      _getActualOffsetY(elementRef, clientY) >=
      heightOnDragEnter - _OFFSET;
}

class DropResult {
  final int type;
  final ListItem<Comparable<dynamic>> listItem;

  DropResult(this.type, this.listItem);
}
