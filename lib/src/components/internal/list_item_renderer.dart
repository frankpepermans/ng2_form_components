library ng2_form_components.components.list_item_renderer;

import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/core/linker/view_utils.dart';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart' show LabelHandler;
import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService;

import 'package:ng2_form_components/src/components/internal/form_component.dart';

import 'package:dnd/dnd.dart';

typedef bool IsSelectedHandler (ListItem listItem);
typedef String GetHierarchyOffsetHandler(ListItem listItem);
typedef void ListDragDropHandler(ListItem dragListItem, ListItem dropListItem, int offset);
typedef ListDragDropHandlerType DragDropTypeHandler(ListItem listItem);

enum ListDragDropHandlerType {
  SORT,
  SWAP,
  ALL
}

@Component(
    selector: 'list-item-renderer',
    template: '''
      <div #dragdropAbove *ngIf="showSortingAreas()" [ngClass]="dragdropAboveClass"></div>
      <div #renderType></div>
      <div #dragdropBelow *ngIf="showSortingAreas()" [ngClass]="dragdropBelowClass"></div>
    ''',
    providers: const <Type>[ViewUtils]
)
class ListItemRenderer<T extends Comparable> implements AfterViewInit, OnDestroy {

  @ViewChild('renderType', read: ViewContainerRef) ViewContainerRef renderTypeTarget;
  @ViewChild('dragdropAbove', read: ViewContainerRef) ViewContainerRef dragdropAbove;
  @ViewChild('dragdropBelow', read: ViewContainerRef) ViewContainerRef dragdropBelow;

  //-----------------------------
  // input
  //-----------------------------

  @Input() ListRendererService listRendererService;
  @Input() int index;
  @Input() LabelHandler labelHandler;
  @Input() ListDragDropHandler dragDropHandler;
  @Input() DragDropTypeHandler dragDropTypeHandler;
  @Input() ListItem<T> listItem;
  @Input() IsSelectedHandler isSelected;
  @Input() GetHierarchyOffsetHandler getHierarchyOffset;
  @Input() ResolveRendererHandler resolveRendererHandler;

  //-----------------------------
  // public properties
  //-----------------------------

  final DynamicComponentLoader dynamicComponentLoader;
  final ElementRef elementRef;
  final ChangeDetectorRef changeDetector;
  final ViewUtils viewUtils;
  final Injector injector;

  final StreamController<List<bool>> _dragDropDisplay$ctrl = new StreamController<List<bool>>.broadcast();

  StreamSubscription<DropzoneEvent> _dropSubscription, _drpZoneLeaveSubscription;
  StreamSubscription<Tuple2<Element, List<bool>>> _shiftSubscription;
  StreamSubscription<MouseEvent> _showHooksSubscription;
  StreamSubscription<List<bool>> _dragDropDisplaySubscription;

  Map<String, bool> dragdropAboveClass = const <String, bool>{'dnd-sort-handler': false}, dragdropBelowClass = const <String, bool>{'dnd-sort-handler': false};

  //-----------------------------
  // constructor
  //-----------------------------

  ListItemRenderer(
    @Inject(Injector) this.injector,
    @Inject(DynamicComponentLoader) this.dynamicComponentLoader,
    @Inject(ElementRef) this.elementRef,
    @Inject(ViewUtils) this.viewUtils,
    @Inject(ChangeDetectorRef) this.changeDetector);

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override void ngOnDestroy() {
    if (dragDropHandler != null) {
      final List<Element> elements = <Element>[elementRef.nativeElement];

      if (dragdropAbove != null) elements.add(dragdropAbove.element.nativeElement);
      if (dragdropBelow != null) elements.add(dragdropBelow.element.nativeElement);

      elements.forEach((Element element) {
        if (listRendererService.dragDropElements.contains(element))
          listRendererService.dragDropElements.removeWhere((Map<Element, ListItem<Comparable>> valuePair) => valuePair.containsKey(element));
      });
    }

    _dropSubscription?.cancel();
    _shiftSubscription?.cancel();
    _drpZoneLeaveSubscription?.cancel();
    _showHooksSubscription?.cancel();
    _dragDropDisplaySubscription?.cancel();
  }

  @override void ngAfterViewInit() {
    final Type resolvedRendererType = resolveRendererHandler(0, listItem);

    if (resolvedRendererType == null) throw new ArgumentError('Unable to resolve renderer for list item: ${listItem.runtimeType}');

    dynamicComponentLoader.loadNextToLocation(resolvedRendererType, renderTypeTarget, ReflectiveInjector.fromResolvedProviders(ReflectiveInjector.resolve(<Provider>[
      new Provider(ListRendererService, useValue: listRendererService),
      new Provider(ListItem, useValue: listItem),
      new Provider(IsSelectedHandler, useValue: isSelected),
      new Provider(GetHierarchyOffsetHandler, useValue: getHierarchyOffset),
      new Provider(LabelHandler, useValue: labelHandler),
      new Provider('list-item-index', useValue: index),
      new Provider(ViewUtils, useValue: viewUtils)
    ]), injector)).then((ComponentRef ref) {
      if (dragDropHandler != null) {
        (ref.location.nativeElement as Element).className = 'dnd--child';

        listRendererService.dragDropElements.add(<Element, ListItem<Comparable>>{elementRef.nativeElement: listItem});

        new Draggable(elementRef.nativeElement, verticalOnly: true);

        switch (dragDropTypeHandler(listItem)) {
          case ListDragDropHandlerType.SWAP:
            _setupDragDropSwap();

            break;
          case ListDragDropHandlerType.SORT:
            _setupDragDropSort(ref.location.nativeElement);

            break;
          case ListDragDropHandlerType.ALL:
            _setupDragDropSwap();
            _setupDragDropSort(ref.location.nativeElement);

            break;
        }
      }

      changeDetector.markForCheck();
    });
  }

  void _setupDragDropSwap() {
    final Dropzone dropZone = new Dropzone(elementRef.nativeElement);

    _dropSubscription = dropZone.onDrop
      .listen((DropzoneEvent event) {
        final Map<Element, ListItem> pair = listRendererService.dragDropElements
          .firstWhere((Map<Element, ListItem<Comparable>> valuePair) => valuePair.containsKey(event.draggableElement), orElse: () => null);

        dragDropHandler(pair[event.draggableElement], listItem, 0);
    });
  }

  void _setupDragDropSort(Element rendererElement) {
    final Element element = elementRef.nativeElement;
    final Element injectedContentElement = rendererElement.children.first;
    final Dropzone dropZone = new Dropzone(element, overClass: 'dnd-owning-object');

    _shiftSubscription = rx.observable(_dragDropDisplay$ctrl.stream)
      .flatMapLatest((List<bool> indices) => rx.observable(dropZone.onDrop)
        .map((DropzoneEvent event) => new Tuple2<Element, List<bool>>(event.draggableElement, indices)))
      .listen((Tuple2<Element, List<bool>> tuple) {
        final Map<Element, ListItem> pair = listRendererService.dragDropElements
          .firstWhere((Map<Element, ListItem<Comparable>> valuePair) => valuePair.containsKey(tuple.item1), orElse: () => null);

        dragDropHandler(pair[tuple.item1], listItem, tuple.item2.first ? -1 : tuple.item2.last ? 1 : 0);
      });

    _drpZoneLeaveSubscription = dropZone.onDragLeave
      .listen((_) {
        _dragDropDisplay$ctrl.add(const <bool>[false, false]);

        changeDetector.markForCheck();
      });

    _showHooksSubscription = rx.observable(dropZone.onDragEnter)
      .where((DropzoneEvent event) => event.draggableElement != element)
      .flatMapLatest((_) => rx.observable(injectedContentElement.onMouseMove)
        .takeUntil(dropZone.onDragLeave))
      .listen((MouseEvent event) {
        final num height = injectedContentElement.client.height;

        if (event.offset.y < height / 2) {
          _dragDropDisplay$ctrl.add(const <bool>[true, false]);
        } else {
          _dragDropDisplay$ctrl.add(const <bool>[false, true]);
        }

        changeDetector.markForCheck();
      });

    _dragDropDisplaySubscription = _dragDropDisplay$ctrl.stream
      .listen((List<bool> indices) {
        dragdropAboveClass = dragdropBelowClass = const <String, bool>{'dnd-sort-handler': false};

        if (indices.first) dragdropAboveClass = const <String, bool>{'dnd-sort-handler': true};
        if (indices.last) dragdropBelowClass = const <String, bool>{'dnd-sort-handler': true};

        changeDetector.markForCheck();
      });
  }

  bool showSortingAreas() => dragDropTypeHandler(listItem) == ListDragDropHandlerType.ALL || dragDropTypeHandler(listItem) == ListDragDropHandlerType.SORT;

}