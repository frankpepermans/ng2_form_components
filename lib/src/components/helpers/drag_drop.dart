import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';
import 'package:dorm/dorm.dart';

import 'package:ng2_form_components/src/components/list_item.g.dart';
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';

import 'package:ng2_form_components/src/infrastructure/drag_drop_service.dart';

import 'package:ng2_form_components/src/utils/html_helpers.dart';

final SerializerJson<String> _serializer = SerializerJson<String>()
  ..outgoing(const [])
  ..addRule(
      DateTime,
      (int value) => (value != null)
          ? DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
          : null,
      (DateTime value) => value?.millisecondsSinceEpoch);

@Directive(selector: '[ngDragDrop]', providers: <Type>[HtmlHelpers])
class DragDrop implements OnDestroy {
  static const num _OFFSET = 11;

  @Input()
  set ngDragDropHandler(ListDragDropHandler handler) =>
      _handler$ctrl.add(handler);
  @Input()
  set ngDragDrop(ListItem<Comparable> listItem) => _listItem$ctrl.add(listItem);

  @Output()
  Stream<DropResult> get onDrop => _onDrop$ctrl.stream;

  final Element elementRef;
  final ChangeDetectorRef changeDetector;
  final DragDropService dragDropService;
  final HtmlHelpers helpers;

  Observable<bool> dragDetection$;
  Observable<bool> dragOver$;
  Observable<bool> dragOut$;

  final StreamController<ListItem<Comparable>> _listItem$ctrl =
      StreamController<ListItem<Comparable>>();
  final StreamController<ListDragDropHandler> _handler$ctrl =
      StreamController<ListDragDropHandler>();
  final StreamController<DropResult> _onDrop$ctrl =
      StreamController<DropResult>.broadcast();
  final StreamController<bool> _removeAllStyles$ctrl =
      StreamController<bool>.broadcast();

  StreamSubscription<bool> _initSubscription;
  StreamSubscription<MouseEvent> _dropHandlerSubscription;
  StreamSubscription<MouseEvent> _sortHandlerSubscription;
  StreamSubscription<MouseEvent> _dragStartSubscription;
  StreamSubscription<MouseEvent> _dragEndSubscription;
  StreamSubscription<bool> _dragOutSubscription;
  StreamSubscription<ListItem<Comparable>> _swapDropSubscription;
  StreamSubscription<Tuple2<ListItem<Comparable>, int>> _sortDropSubscription;

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
    _initSubscription = Observable.combineLatest3(
            _listItem$ctrl.stream.take(1),
            _handler$ctrl.stream.take(1),
            Observable(_removeAllStyles$ctrl.stream).startWith(false),
            _updateStyles)
        .listen(null);
  }

  bool _updateStyles(ListItem<Comparable> listItem, ListDragDropHandler handler,
      bool removeAllStyles) {
    if (listItem != null && handler != null) {
      if (removeAllStyles) {
        helpers.updateElementClasses(
            elementRef, dragDropService.resolveDropClassName(listItem), false);
        helpers.updateElementClasses(
            elementRef, 'ngDragDrop--drop-inside', false);
        helpers.updateElementClasses(
            elementRef, 'ngDragDrop--sort-handler--above', false);
        helpers.updateElementClasses(
            elementRef, 'ngDragDrop--sort-handler--below', false);
      } else {
        final type = dragDropService.typeHandler(listItem);

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

  void _setupAsDragDrop(ListItem<Comparable> listItem) {
    if (_areStreamsSet) return;

    final Element element = elementRef;

    _areStreamsSet = true;

    dragDetection$ = Observable.merge([
      Observable(element.onDragEnter).doOnData((_) {
        heightOnDragEnter = element.client.height;
      }).map((_) => 1),
      element.onDragLeave.map((_) => -1),
      element.onDrop.map((_) => -1)
    ])
        .asBroadcastStream()
        .scan((int acc, value, _) => acc + value, 0)
        .map((result) => result > 0)
        .distinct();

    dragOver$ = dragDetection$.where((value) => value);

    dragOut$ = dragDetection$.where((value) => !value).map((_) => true);

    _dragStartSubscription = element.onDragStart.listen((event) {
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer
          .setData('text/plain', _serializer.outgoing(<Entity>[listItem]));

      helpers.updateElementClasses(element, 'ngDragDrop--active', true);
    });

    _dragEndSubscription = element.onDragEnd.listen((event) {
      helpers.updateElementClasses(element, 'ngDragDrop--active', false);
    });

    _dragOutSubscription = dragOut$.listen(_removeAllStyles);
  }

  void _createDropHandler(
      ListItem<Comparable> listItem, ListDragDropHandler handler) {
    elementRef.setAttribute('draggable', 'true');

    _sortHandlerSubscription =
        Observable.merge([elementRef.onDragOver, elementRef.onDragLeave])
            .listen((event) {
      event.preventDefault();

      helpers.updateElementClasses(
          elementRef,
          dragDropService.resolveDropClassName(listItem),
          _isWithinDropBounds(event.client.y));
    });

    _swapDropSubscription = elementRef.onDrop
        .map(_dataTransferToListItem)
        .listen((droppedListItem) {
      if (droppedListItem.compareTo(listItem) != 0) {
        handler(droppedListItem, listItem, 0);

        _onDrop$ctrl.add(DropResult(0, listItem));
      }

      _removeAllStyles(null);
    });
  }

  void _createSortHandlers(
      ListItem<Comparable> listItem, ListDragDropHandler handler) {
    elementRef.setAttribute('draggable', 'true');

    _dropHandlerSubscription = elementRef.onDragOver.listen((event) {
      event.preventDefault();

      helpers.updateElementClasses(elementRef,
          'ngDragDrop--sort-handler--above', _isSortAbove(event.client.y));
      helpers.updateElementClasses(elementRef,
          'ngDragDrop--sort-handler--below', _isSortBelow(event.client.y));
    });

    _sortDropSubscription = elementRef.onDrop
        .map((event) =>
            Tuple2(_dataTransferToListItem(event), _getSortOffset(event)))
        .listen((tuple) {
      if (tuple.item1.compareTo(listItem) != 0) {
        handler(tuple.item1, listItem, tuple.item2);

        _onDrop$ctrl.add(
            DropResult(tuple.item2, tuple.item2 == 0 ? listItem : tuple.item1));
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

  ListItem<Comparable> _dataTransferToListItem(MouseEvent event) {
    final transferDataEncoded = event.dataTransfer.getData('text/plain');

    if (transferDataEncoded.isEmpty) return null;

    final factory = EntityFactory<Entity>();
    final result =
        factory.spawn(_serializer.incoming(transferDataEncoded), _serializer);

    return result.first as ListItem<Comparable>;
  }

  void _removeAllStyles(dynamic _) => _removeAllStyles$ctrl.add(true);

  num _getActualOffsetY(Element element, num clientY) =>
      clientY - element.getBoundingClientRect().top;

  bool _isWithinDropBounds(num clientY) {
    final y = _getActualOffsetY(elementRef, clientY);

    return y > _OFFSET && y < heightOnDragEnter - _OFFSET;
  }

  bool _isSortAbove(num clientY) =>
      _getActualOffsetY(elementRef, clientY) <= _OFFSET;

  bool _isSortBelow(num clientY) =>
      _getActualOffsetY(elementRef, clientY) >= heightOnDragEnter - _OFFSET;
}

class DropResult {
  final int type;
  final ListItem<Comparable> listItem;

  DropResult(this.type, this.listItem);
}
