library ng2_form_components.infrastructure.list_renderer_service;

import 'dart:async';
import 'dart:html';

import 'package:ng2_form_components/src/components/list_renderer.dart';

import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;

class ListRendererService {

  List<ListRendererEvent> lastResponders;
  ListRenderer renderer;

  Stream<ListItem> get rendererSelection$ => _rendererSelection$ctrl.stream;
  Stream<ItemRendererEvent<dynamic, Comparable>> get event$ => _event$ctrl.stream;
  Stream<List<ListRendererEvent<dynamic, Comparable>>> get responders$ => _responder$ctrl.stream;

  final List<Map<Element, ListItem<Comparable>>> dragDropElements = <Map<Element, ListItem<Comparable>>>[];

  final StreamController<ListItem> _rendererSelection$ctrl = new StreamController<ListItem>.broadcast();
  final StreamController<ItemRendererEvent> _event$ctrl = new StreamController<ItemRendererEvent>.broadcast();
  final StreamController<List<ListRendererEvent>> _responder$ctrl = new StreamController<List<ListRendererEvent>>.broadcast();

  ListRendererService();

  void setRenderer(ListRenderer renderer) {
    this.renderer = renderer;
  }

  void triggerSelection(ListItem listItem) => _rendererSelection$ctrl.add(listItem);

  void triggerEvent(ItemRendererEvent event) => _event$ctrl.add(event);

  void respondEvents(List<ListRendererEvent> events) {
    _responder$ctrl.add(events);

    lastResponders = events;
  }

}

class ListRendererEvent<T, U extends Comparable> {

  final String type;
  final ListItem<U> listItem;
  final T data;

  ListRendererEvent(this.type, this.listItem, this.data);

}

class ItemRendererEvent<T, U extends Comparable> {

  final String type;
  final ListItem<U> listItem;
  final T data;

  ItemRendererEvent(this.type, this.listItem, this.data);

}