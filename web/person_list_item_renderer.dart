library person_list_item_renderer;

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/item_renderers/dynamic_list_item_renderer.dart' show DynamicListItemRenderer;

import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';
import 'package:ng2_form_components/src/components/list_item.dart';

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService;

import 'person.dart' show Person;

@Component(
    selector: 'person-list-item-renderer',
    template: '''
      <div class="instance" (click)="triggerSelection()">
        <img [src]="listItem.data.image" style="width:40px;height:40px;min-width:40px;min-height:40px;margin-right:6px">
        <label style="flex-grow:1">{{labelHandler(listItem.data)}}</label>
      </div>
    '''
)
class PersonListItemRenderer<T extends Person> implements DynamicListItemRenderer {

  //-----------------------------
  // input
  //-----------------------------

  final ListRendererService listRendererService;
  final ListItem<T> listItem;
  final IsSelectedHandler isSelected;
  final GetHierarchyOffsetHandler getHierarchyOffset;
  final LabelHandler labelHandler;

  //-----------------------------
  // constructor
  //-----------------------------

  PersonListItemRenderer(
      @Inject(ListRendererService) this.listRendererService,
      @Inject(ListItem) this.listItem,
      @Inject(IsSelectedHandler) this.isSelected,
      @Inject(GetHierarchyOffsetHandler) this.getHierarchyOffset,
      @Inject(LabelHandler) this.labelHandler,
      @Inject(ElementRef) ElementRef elementRef);

  void triggerSelection() => listRendererService.triggerSelection(listItem);

}