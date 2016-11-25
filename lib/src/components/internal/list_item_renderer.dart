library ng2_form_components.components.list_item_renderer;

import 'dart:async';

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart' show LabelHandler;
import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService;

import 'package:ng2_form_components/src/components/internal/form_component.dart';

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
      <div><div #renderType></div></div>
    ''',
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false
)
class ListItemRenderer<T extends Comparable<dynamic>> extends ComponentState implements OnInit {

  ViewContainerRef _renderTypeTarget;
  ViewContainerRef get renderTypeTarget => _renderTypeTarget;
  @ViewChild('renderType', read: ViewContainerRef) set renderTypeTarget(ViewContainerRef value) {
    _renderTypeTarget = value;
  }

  //-----------------------------
  // input
  //-----------------------------

  ListRendererService _listRendererService;
  ListRendererService get listRendererService => _listRendererService;
  @Input() set listRendererService(ListRendererService value) {
    _listRendererService = value;
  }

  int _index;
  int get index => _index;
  @Input() set index(int value) {
    _index = value;
  }

  LabelHandler _labelHandler;
  LabelHandler get labelHandler => _labelHandler;
  @Input() set labelHandler(LabelHandler value) {
    _labelHandler = value;
  }

  ListItem<T> _listItem;
  ListItem<T> get listItem => _listItem;
  @Input() set listItem(ListItem<T> value) {
    _listItem = value;
  }

  IsSelectedHandler _isSelected;
  IsSelectedHandler get isSelected => _isSelected;
  @Input() set isSelected(IsSelectedHandler value) {
    _isSelected = value;
  }

  GetHierarchyOffsetHandler _getHierarchyOffset;
  GetHierarchyOffsetHandler get getHierarchyOffset => _getHierarchyOffset;
  @Input() set getHierarchyOffset(GetHierarchyOffsetHandler value) {
    _getHierarchyOffset = value;
  }

  ResolveRendererHandler _resolveRendererHandler;
  ResolveRendererHandler get resolveRendererHandler => _resolveRendererHandler;
  @Input() set resolveRendererHandler(ResolveRendererHandler value) {
    _resolveRendererHandler = value;
  }

  //-----------------------------
  // public properties
  //-----------------------------

  final DynamicComponentLoader dynamicComponentLoader;
  final Injector injector;
  final DragDropService dragDropService;

  //-----------------------------
  // constructor
  //-----------------------------

  ListItemRenderer(
    @Inject(Injector) this.injector,
    @Inject(DynamicComponentLoader) this.dynamicComponentLoader,
    @Inject(DragDropService) this.dragDropService);

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override void ngOnInit() {
    final Type resolvedRendererType = resolveRendererHandler(0, listItem);

    if (resolvedRendererType == null) throw new ArgumentError('Unable to resolve renderer for list item: ${listItem.runtimeType}');

    dynamicComponentLoader.loadNextToLocation(resolvedRendererType, renderTypeTarget, ReflectiveInjector.fromResolvedProviders(ReflectiveInjector.resolve(<Provider>[
      new Provider(ListRendererService, useValue: listRendererService),
      new Provider(ListItem, useValue: listItem),
      new Provider(IsSelectedHandler, useValue: isSelected),
      new Provider(GetHierarchyOffsetHandler, useValue: getHierarchyOffset),
      new Provider(LabelHandler, useValue: labelHandler),
      new Provider('list-item-index', useValue: index)
    ]), injector)).then(ngOnComponentLoaded);
  }

  void ngOnComponentLoaded(ComponentRef ref) {
    deliverStateChanges();
  }

}