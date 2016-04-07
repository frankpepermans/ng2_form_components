library ng2_form_components.components.default_hierarchy_list_item_renderer;

import 'dart:async';

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/item_renderers/dynamic_list_item_renderer.dart' show DynamicListItemRenderer;

import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';
import 'package:ng2_form_components/src/components/list_item.dart';

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart';

@Component(
    selector: 'default-list-item-renderer',
    template: '''
      <div class="instance" (click)="triggerSelection()" style="padding:5px">
        <label [ngStyle]="{'margin-left': getHierarchyOffset(listItem), 'word-wrap': 'break-word', 'width': '100%'}">{{labelHandler(listItem.data)}}</label>
        <i *ngIf="isSelected(listItem)" class="fa fa-check" style="float:right"></i>
      </div>
    ''',
    changeDetection: ChangeDetectionStrategy.OnPush
)
class DefaultHierarchyListItemRenderer<T extends Comparable> implements DynamicListItemRenderer, OnDestroy {

  //-----------------------------
  // input
  //-----------------------------

  final ListRendererService listRendererService;
  final ChangeDetectorRef changeDetector;
  final ListItem listItem;
  final IsSelectedHandler isSelected;
  final GetHierarchyOffsetHandler getHierarchyOffset;
  final LabelHandler labelHandler;

  StreamSubscription<List<ListRendererEvent>> _eventSubscription;

  //-----------------------------
  // constructor
  //-----------------------------

  DefaultHierarchyListItemRenderer(
      @Inject(ListRendererService) this.listRendererService,
      @Inject(ChangeDetectorRef) this.changeDetector,
      @Inject(ListItem) this.listItem,
      @Inject(IsSelectedHandler) this.isSelected,
      @Inject(GetHierarchyOffsetHandler) this.getHierarchyOffset,
      @Inject(LabelHandler) this.labelHandler,
      @Inject(ElementRef) ElementRef elementRef) {
    _initStreams();
  }

  void ngOnDestroy() {
    _eventSubscription?.cancel();
  }

  void _initStreams() {
    _eventSubscription = listRendererService.responders$
      .where((List<ListRendererEvent> events) => events.firstWhere((ListRendererEvent event) => event.type == 'selectionChanged', orElse: () => null) != null)
      .listen((_) => changeDetector.markForCheck());
  }

  void triggerSelection() {
    listRendererService.rendererSelection$
      .take(1)
      .listen((_) {
        listRendererService.triggerEvent(new ItemRendererEvent<bool, T>(
            'selection',
            listItem as ListItem<T>,
            true)
        );
      });

    listRendererService.triggerSelection(listItem);
  }

}