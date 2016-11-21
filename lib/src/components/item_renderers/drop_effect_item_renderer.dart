library ng2_form_components.components.drop_effect_item_renderer;

import 'dart:async';

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;
import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService, ItemRendererEvent;
import 'package:ng2_form_components/src/components/item_renderers/dynamic_list_item_renderer.dart' show DynamicListItemRenderer;

class DropEffectItemRenderer<T extends Comparable<dynamic>> extends ComponentState implements DynamicListItemRenderer, OnDestroy {

  final ListRendererService listRendererService;
  final ListItem<T> listItem;

  StreamSubscription<ItemRendererEvent<dynamic, Comparable<dynamic>>> _itemRendererEventSubscription;

  bool showDropEffect = false;

  //-----------------------------
  // constructor
  //-----------------------------

  DropEffectItemRenderer(
    @Inject(ListRendererService) this.listRendererService,
    @Inject(ListItem) this.listItem) {
      _initStreams();
    }

  @override void ngOnDestroy() {
    _itemRendererEventSubscription?.cancel();
  }

  void _initStreams() {
    _itemRendererEventSubscription = listRendererService.event$
      .listen((ItemRendererEvent<dynamic, Comparable<dynamic>> event) {
        if (event.type == 'dropEffect') {
          if (!showDropEffect && listItem.compareTo(event.listItem) == 0) {
            //final ItemRendererEvent<int, Comparable<dynamic>> eventCast = event as ItemRendererEvent<int, Comparable<dynamic>>;

            if (!showDropEffect) setState(() => showDropEffect = true);
          }
        }
      });
  }
}