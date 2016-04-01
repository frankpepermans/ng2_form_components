library ng2_form_components.components.list_item_renderer;

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart' show FormComponent, LabelHandler;
import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService;

typedef bool IsSelectedHandler (ListItem listItem);
typedef String GetHierarchyOffsetHandler(ListItem listItem);

@Component(
    selector: 'list-item-renderer',
    template: '''
      <div #renderType></div>
    '''
)
class ListItemRenderer<T extends Comparable> implements AfterViewInit {

  //-----------------------------
  // input
  //-----------------------------

  @Input() ListRendererService listRendererService;
  @Input() LabelHandler labelHandler;
  @Input() Type renderType;
  @Input() ListItem<T> listItem;
  @Input() IsSelectedHandler isSelected;
  @Input() GetHierarchyOffsetHandler getHierarchyOffset;

  //-----------------------------
  // public properties
  //-----------------------------

  final DynamicComponentLoader dynamicComponentLoader;
  final ElementRef elementRef;
  final ChangeDetectorRef changeDetector;

  //-----------------------------
  // constructor
  //-----------------------------

  ListItemRenderer(
    @Inject(DynamicComponentLoader) this.dynamicComponentLoader,
    @Inject(ElementRef) this.elementRef,
    @Inject(ChangeDetectorRef) this.changeDetector);

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override void ngAfterViewInit() {
    dynamicComponentLoader.loadIntoLocation(renderType, elementRef, 'renderType', Injector.resolve(<Provider>[
      new Provider(ListRendererService, useValue: listRendererService),
      new Provider(ListItem, useValue: listItem),
      new Provider(IsSelectedHandler, useValue: isSelected),
      new Provider(GetHierarchyOffsetHandler, useValue: getHierarchyOffset),
      new Provider(LabelHandler, useValue: labelHandler)
    ])).then((ComponentRef ref) => changeDetector.markForCheck());
  }

}