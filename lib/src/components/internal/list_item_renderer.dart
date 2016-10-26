library ng2_form_components.components.list_item_renderer;

import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';

import 'package:tuple/tuple.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart' show LabelHandler;
import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService, ItemRendererEvent;

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:ng2_form_components/src/components/helpers/drag_drop.dart';

import 'package:ng2_form_components/src/infrastructure/drag_drop_service.dart';

enum ListDragDropHandlerType {
  NONE,
  SORT,
  SWAP,
  ALL
}

typedef void ListDragDropHandler(ListItem<Comparable<dynamic>> dragListItem, ListItem<Comparable<dynamic>> dropListItem, int offset);
typedef bool IsSelectedHandler (ListItem<Comparable<dynamic>> listItem);
typedef String GetHierarchyOffsetHandler(ListItem<Comparable<dynamic>> listItem);

@Component(
    selector: 'list-item-renderer',
    template: '''
      <div [ngDragDrop]="listItem" [ngDragDropHandler]="dragDropHandler" (onDrop)="handleDrop(\$event)">
        <div #renderType></div>
      </div>
    ''',
    directives: const <Type>[DragDrop],
    changeDetection: ChangeDetectionStrategy.OnPush,
    preserveWhitespace: false
)
class ListItemRenderer<T extends Comparable<dynamic>> implements OnDestroy, OnInit {

  @ViewChild('renderType', read: ViewContainerRef) ViewContainerRef renderTypeTarget;

  //-----------------------------
  // input
  //-----------------------------

  @Input() ListRendererService listRendererService;
  @Input() int index;
  @Input() LabelHandler labelHandler;
  @Input() ListItem<T> listItem;
  @Input() IsSelectedHandler isSelected;
  @Input() GetHierarchyOffsetHandler getHierarchyOffset;
  @Input() ResolveRendererHandler resolveRendererHandler;
  @Input() ListDragDropHandler dragDropHandler;

  //-----------------------------
  // public properties
  //-----------------------------

  final DynamicComponentLoader dynamicComponentLoader;
  final ElementRef elementRef;
  final ChangeDetectorRef changeDetector;
  final Injector injector;
  final Renderer renderer;
  final DragDropService dragDropService;

  StreamSubscription<Tuple2<Element, List<bool>>> _shiftSubscription;
  StreamSubscription<MouseEvent> _showHooksSubscription;

  bool _isChildComponentInjected = false;

  //-----------------------------
  // constructor
  //-----------------------------

  ListItemRenderer(
    @Inject(Injector) this.injector,
    @Inject(DynamicComponentLoader) this.dynamicComponentLoader,
    @Inject(ElementRef) this.elementRef,
    @Inject(Renderer) this.renderer,
    @Inject(ChangeDetectorRef) this.changeDetector,
    @Inject(DragDropService) this.dragDropService);

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override void ngOnDestroy() {
    _shiftSubscription?.cancel();
    _showHooksSubscription?.cancel();
  }

  @override void ngOnInit() => _injectChildComponent();

  void _injectChildComponent() {
    if (_isChildComponentInjected || resolveRendererHandler == null || renderTypeTarget == null) return;

    _isChildComponentInjected = true;

    final Type resolvedRendererType = resolveRendererHandler(0, listItem);

    if (resolvedRendererType == null) throw new ArgumentError('Unable to resolve renderer for list item: ${listItem.runtimeType}');

    dynamicComponentLoader.loadNextToLocation(resolvedRendererType, renderTypeTarget, ReflectiveInjector.fromResolvedProviders(ReflectiveInjector.resolve(<Provider>[
      new Provider(ListRendererService, useValue: listRendererService),
      new Provider(ListItem, useValue: listItem),
      new Provider(IsSelectedHandler, useValue: isSelected),
      new Provider(GetHierarchyOffsetHandler, useValue: getHierarchyOffset),
      new Provider(LabelHandler, useValue: labelHandler),
      new Provider('list-item-index', useValue: index)
    ]), injector)).then((ComponentRef ref) {
      if (dragDropHandler != null) {
        final ListDragDropHandlerType dragDropType = dragDropService.typeHandler(listItem);

        if (dragDropType != ListDragDropHandlerType.NONE) {
          renderer.setElementClass(ref.location.nativeElement, 'ngDragDrop--target', true);

          (ref.location.nativeElement as Element).style.order = '1';
        }
      }

      changeDetector.markForCheck();
    });
  }

  void handleDrop(DropResult dropResult) {
    listRendererService.triggerEvent(new ItemRendererEvent<int, Comparable<dynamic>>('dropEffectRequest', dropResult.listItem, dropResult.type));
  }

}