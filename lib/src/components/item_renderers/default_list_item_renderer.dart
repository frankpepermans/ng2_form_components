library ng2_form_components.components.default_list_item_renderer;

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/item_renderers/dynamic_list_item_renderer.dart' show DynamicListItemRenderer;

import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';
import 'package:ng2_form_components/src/components/list_item.dart';

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService;

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
class DefaultListItemRenderer<T extends Comparable> implements DynamicListItemRenderer {

  //-----------------------------
  // input
  //-----------------------------

  final ListRendererService listRendererService;
  final ListItem listItem;
  final IsSelectedHandler isSelected;
  final GetHierarchyOffsetHandler getHierarchyOffset;
  final LabelHandler labelHandler;

  //-----------------------------
  // constructor
  //-----------------------------

  DefaultListItemRenderer(
    @Inject(ListRendererService) this.listRendererService,
    @Inject(ListItem) this.listItem,
    @Inject(IsSelectedHandler) this.isSelected,
    @Inject(GetHierarchyOffsetHandler) this.getHierarchyOffset,
    @Inject(LabelHandler) this.labelHandler,
    @Inject(ElementRef) ElementRef elementRef);

  void triggerSelection() => listRendererService.triggerSelection(listItem);

}