import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:ng2_form_components/src/components/list_renderer.dart';

import 'package:ng2_form_components/src/components/list_item.g.dart'
    show ListItem;

class ListRendererService {
  List<ListRendererEvent<dynamic, Comparable<dynamic>>> lastResponders;

  final List<ListRenderer> renderers = <ListRenderer>[];

  Stream<ListItem<Comparable<dynamic>>> get rendererSelection$ =>
      _rendererSelection$ctrl.stream;
  Stream<ItemRendererEvent<dynamic, Comparable<dynamic>>> get event$ =>
      _event$ctrl.stream;
  Stream<List<ListRendererEvent<dynamic, Comparable<dynamic>>>>
      get responders$ => _responder$ctrl.stream;
  Stream<bool> get isOpenChange$ => _isOpenChange$ctrl.stream;

  final StreamController<bool> _isOpenChange$ctrl =
      StreamController<bool>.broadcast();
  final StreamController<ListItem<Comparable<dynamic>>>
      _rendererSelection$ctrl =
      StreamController<ListItem<Comparable<dynamic>>>.broadcast();
  final StreamController<ItemRendererEvent<dynamic, Comparable<dynamic>>>
      _event$ctrl =
      BehaviorSubject<ItemRendererEvent<dynamic, Comparable<dynamic>>>();
  final StreamController<List<ListRendererEvent<dynamic, Comparable<dynamic>>>>
      _responder$ctrl = StreamController<
          List<ListRendererEvent<dynamic, Comparable<dynamic>>>>.broadcast();

  ListRendererService();

  void addRenderer(ListRenderer renderer) => renderers.add(renderer);

  bool removeRenderer(ListRenderer renderer) => renderers.remove(renderer);

  void triggerSelection(ListItem<Comparable<dynamic>> listItem) {
    if (!_rendererSelection$ctrl.isClosed)
      _rendererSelection$ctrl.add(listItem);
  }

  void triggerEvent(ItemRendererEvent<dynamic, Comparable<dynamic>> event) {
    if (!_event$ctrl.isClosed) _event$ctrl.add(event);
  }

  void respondEvents(
      List<ListRendererEvent<dynamic, Comparable<dynamic>>> events) {
    if (!_responder$ctrl.isClosed) _responder$ctrl.add(events);

    lastResponders = events;
  }

  bool isOpen(ListItem<Comparable<dynamic>> listItem) {
    for (var i = 0, len = renderers.length; i < len; i++) {
      if (renderers[i].isOpen(listItem)) return true;
    }

    return false;
  }

  void close() {
    _isOpenChange$ctrl.close();
    _rendererSelection$ctrl.close();
    _event$ctrl.close();
    _responder$ctrl.close();
  }

  void notifyIsOpenChange() {
    if (!_isOpenChange$ctrl.isClosed) _isOpenChange$ctrl.add(true);
  }
}

class ListRendererEvent<T, U extends Comparable<dynamic>> {
  final String type;
  final ListItem<U> listItem;
  final T data;

  ListRendererEvent(this.type, this.listItem, this.data);
}

class ItemRendererEvent<T, U extends Comparable<dynamic>> {
  final String type;
  final ListItem<U> listItem;
  final T data;

  ItemRendererEvent(this.type, this.listItem, this.data);
}
