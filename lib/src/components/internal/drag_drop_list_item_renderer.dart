import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart'
    show ItemRendererEvent;

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
    preserveWhitespace: false)
class DragDropListItemRenderer<T extends Comparable<dynamic>>
    extends ListItemRenderer<T> implements OnInit {
  final HtmlHelpers helpers;

  //-----------------------------
  // input
  //-----------------------------

  ListDragDropHandler _dragDropHandler;
  ListDragDropHandler get dragDropHandler => _dragDropHandler;
  @Input()
  set dragDropHandler(ListDragDropHandler value) {
    if (_dragDropHandler != value) setState(() => _dragDropHandler = value);
  }

  //-----------------------------
  // public properties
  //-----------------------------

  //-----------------------------
  // constructor
  //-----------------------------

  DragDropListItemRenderer(
      @Inject(Injector) Injector injector,
      @Inject(HtmlHelpers) this.helpers,
      @Inject(ComponentLoader) ComponentLoader dynamicComponentLoader,
      @Inject(DragDropService) DragDropService dragDropService)
      : super(injector, dynamicComponentLoader, dragDropService);

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  void handleDrop(DropResult dropResult) {
    listRendererService.triggerEvent(
        new ItemRendererEvent<int, Comparable<dynamic>>(
            'dropEffectRequest', dropResult.listItem, dropResult.type));
  }

  @override
  void ngOnComponentLoaded(ComponentRef ref) {
    if (dragDropHandler != null) {
      final ListDragDropHandlerType dragDropType =
          dragDropService.typeHandler(listItem);

      if (dragDropType != ListDragDropHandlerType.NONE) {
        helpers.updateElementClasses(ref.location, 'ngDragDrop--target', true);

        ref.location.style.order = '1';
      }
    }

    super.ngOnComponentLoaded(ref);
  }
}
