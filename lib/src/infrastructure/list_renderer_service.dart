library ng2_form_components.infrastructure.list_renderer_service;

import 'dart:async';

import 'package:ng2_form_components/src/components/list_renderer.dart';

import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;

class ListRendererService {

  List<ListRendererEvent<dynamic, Comparable<dynamic>>> lastResponders;

  final List<ListRenderer<Comparable<dynamic>>> renderers = <ListRenderer<Comparable<dynamic>>>[];

  Stream<ListItem<Comparable<dynamic>>> get rendererSelection$ => _rendererSelection$ctrl.stream;
  Stream<ItemRendererEvent<dynamic, Comparable<dynamic>>> get event$ => _event$ctrl.stream;
  Stream<List<ListRendererEvent<dynamic, Comparable<dynamic>>>> get responders$ => _responder$ctrl.stream;

  final StreamController<ListItem<Comparable<dynamic>>> _rendererSelection$ctrl = new StreamController<ListItem<Comparable<dynamic>>>.broadcast();
  final StreamController<ItemRendererEvent<dynamic, Comparable<dynamic>>> _event$ctrl = new StreamController<ItemRendererEvent<dynamic, Comparable<dynamic>>>.broadcast();
  final StreamController<List<ListRendererEvent<dynamic, Comparable<dynamic>>>> _responder$ctrl = new StreamController<List<ListRendererEvent<dynamic, Comparable<dynamic>>>>.broadcast();

  ListRendererService();

  void addRenderer(ListRenderer<Comparable<dynamic>> renderer) => renderers.add(renderer);

  bool removeRenderer(ListRenderer<Comparable<dynamic>> renderer) => renderers.remove(renderer);

  void triggerSelection(ListItem<Comparable<dynamic>> listItem) => _rendererSelection$ctrl.add(listItem);

  void triggerEvent(ItemRendererEvent<dynamic, Comparable<dynamic>> event) => _event$ctrl.add(event);

  void respondEvents(List<ListRendererEvent<dynamic, Comparable<dynamic>>> events) {
    _responder$ctrl.add(events);

    lastResponders = events;
  }

  bool isOpen(ListItem<Comparable<dynamic>> listItem) {
    for (int i=0, len=renderers.length; i<len; i++) {
      if (renderers[i].isOpen(listItem)) return true;
    }

    return false;
  }

  void close() {
    /*_rendererSelection$ctrl.close();
    _event$ctrl.close();
    _responder$ctrl.close();*/
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