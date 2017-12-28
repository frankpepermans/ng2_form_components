library ng2_form_components.components.drag_drop_list_item_renderer;

import 'dart:html';

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart' show LabelHandler;
import 'package:ng2_form_components/src/components/list_item.g.dart' show ListItem;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService, ItemRendererEvent;

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:ng2_form_components/src/components/helpers/drag_drop.dart';

import 'package:ng2_form_components/src/infrastructure/drag_drop_service.dart';

import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';

import 'package:ng2_form_components/src/utils/html_helpers.dart';

@Component(
    selector: 'drag-drop-list-item-renderer',
    template: '''
      <div [ngDragDrop]="listItem" [ngDragDropHandler]="dragDropHandler" (onDrop)="handleDrop(\$event)">
        <div #renderType></div>
      </div>
    ''',
    directives: const <Type>[DragDrop],
    providers: const <Type>[HtmlHelpers],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false
)
class DragDropListItemRenderer<T extends Comparable<dynamic>> extends ListItemRenderer<T> implements OnInit {

  @override @ViewChild('renderType', read: ViewContainerRef) set renderTypeTarget(ViewContainerRef value) {
    super.renderTypeTarget = value;
  }

  final HtmlHelpers helpers;

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
    @Inject(HtmlHelpers) this.helpers,
    @Inject(SlowComponentLoader) SlowComponentLoader dynamicComponentLoader,
    @Inject(DragDropService) DragDropService dragDropService) : super(injector, dynamicComponentLoader, dragDropService);

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
        helpers.updateElementClasses(ref.location, 'ngDragDrop--target', true);

        ref.location.style.order = '1';
      }
    }

    super.ngOnComponentLoaded(ref);
  }
}