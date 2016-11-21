library ng2_form_components.components.drag_drop_list_item_renderer;

import 'dart:html';

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart' show LabelHandler;
import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService, ItemRendererEvent;

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:ng2_form_components/src/components/helpers/drag_drop.dart';

import 'package:ng2_form_components/src/infrastructure/drag_drop_service.dart';

import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';

@Component(
    selector: 'drag-drop-list-item-renderer',
    template: '''
      <div [ngDragDrop]="listItem" [ngDragDropHandler]="dragDropHandler" (onDrop)="handleDrop(\$event)">
        <div #renderType></div>
      </div>
    ''',
    directives: const <Type>[DragDrop],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false
)
class DragDropListItemRenderer<T extends Comparable<dynamic>> extends ListItemRenderer<T> implements OnInit {

  @ViewChild('renderType', read: ViewContainerRef) set renderTypeTarget(ViewContainerRef value) {
    super.renderTypeTarget = value;
  }

  //-----------------------------
  // input
  //-----------------------------

  @override @Input() set listRendererService(ListRendererService value) {
    super.listRendererService = value;
  }

  @override @Input() set index(int value) {
    super.index = value;
  }

  @override @Input() set labelHandler(LabelHandler value) {
    super.labelHandler = value;
  }

  @override @Input() set listItem(ListItem<T> value) {
    super.listItem = value;
  }

  @override @Input() set isSelected(IsSelectedHandler value) {
    super.isSelected = value;
  }

  @override @Input() set getHierarchyOffset(GetHierarchyOffsetHandler value) {
    super.getHierarchyOffset = value;
  }

  @override @Input() set resolveRendererHandler(ResolveRendererHandler value) {
    super.resolveRendererHandler = value;
  }

  @Input() ListDragDropHandler dragDropHandler;

  //-----------------------------
  // public properties
  //-----------------------------

  //-----------------------------
  // constructor
  //-----------------------------

  DragDropListItemRenderer(
      @Inject(Injector) Injector injector,
      @Inject(DynamicComponentLoader) DynamicComponentLoader dynamicComponentLoader,
      @Inject(Renderer) Renderer renderer,
      @Inject(DragDropService) DragDropService dragDropService) : super(injector, dynamicComponentLoader, renderer, dragDropService);

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  void handleDrop(DropResult dropResult) {
    listRendererService.triggerEvent(new ItemRendererEvent<int, Comparable<dynamic>>('dropEffectRequest', dropResult.listItem, dropResult.type));
  }

  @override void ngOnComponentLoaded(ComponentRef ref) {
    if (dragDropHandler != null) {
      final ListDragDropHandlerType dragDropType = dragDropService.typeHandler(listItem);

      if (dragDropType != ListDragDropHandlerType.NONE) {
        renderer.setElementClass(ref.location.nativeElement, 'ngDragDrop--target', true);

        (ref.location.nativeElement as Element).style.order = '1';
      }
    }

    super.ngOnComponentLoaded(ref);
  }
}