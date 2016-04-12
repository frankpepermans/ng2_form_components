library ng2_form_components.components.list_item_renderer;

import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart' show FormComponent, LabelHandler;
import 'package:ng2_form_components/src/components/list_item.dart' show ListItem;

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart' show ListRendererService;

import 'package:dnd/dnd.dart';

typedef bool IsSelectedHandler (ListItem listItem);
typedef String GetHierarchyOffsetHandler(ListItem listItem);
typedef void ListDragDropHandler(ListItem dragListItem, ListItem dropListItem);

@Component(
    selector: 'list-item-renderer',
    template: '''
      <div #renderType></div>
    '''
)
class ListItemRenderer<T extends Comparable> implements AfterViewInit, OnDestroy {

  //-----------------------------
  // input
  //-----------------------------

  @Input() ListRendererService listRendererService;
  @Input() int index;
  @Input() LabelHandler labelHandler;
  @Input() ListDragDropHandler dragDropHandler;
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

  StreamSubscription<DropzoneEvent> _dropSubscription;

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

  @override void ngOnDestroy() {
    if (dragDropHandler != null && listRendererService.dragDropElements.contains(elementRef.nativeElement)) {
      listRendererService.dragDropElements.removeWhere((Map<Element, ListItem> valuePair) => valuePair.containsKey(elementRef.nativeElement));
    }

    _dropSubscription?.cancel();
  }

  @override void ngAfterViewInit() {
    dynamicComponentLoader.loadIntoLocation(renderType, elementRef, 'renderType', Injector.resolve(<Provider>[
      new Provider(ListRendererService, useValue: listRendererService),
      new Provider(ListItem, useValue: listItem),
      new Provider(IsSelectedHandler, useValue: isSelected),
      new Provider(GetHierarchyOffsetHandler, useValue: getHierarchyOffset),
      new Provider(LabelHandler, useValue: labelHandler)
    ])).then((ComponentRef ref) {
      if (dragDropHandler != null) {
        listRendererService.dragDropElements.add(<Element, ListItem>{elementRef.nativeElement: listItem});

        new Draggable(elementRef.nativeElement);

        final Dropzone dropZone = new Dropzone(elementRef.nativeElement, acceptor: new _SameListRendererAcceptor(listRendererService));

        _dropSubscription = dropZone.onDrop
          .listen((DropzoneEvent event) {
            final Map<Element, ListItem> pair = listRendererService.dragDropElements
              .firstWhere((Map<Element, ListItem> valuePair) => valuePair.containsKey(event.draggableElement), orElse: () => null);

            dragDropHandler(pair[event.draggableElement], listItem);
          });
      }

      changeDetector.markForCheck();
    });
  }

}

class _SameListRendererAcceptor implements Acceptor {

  final ListRendererService listRendererService;

  _SameListRendererAcceptor(this.listRendererService);

  @override bool accepts(Element draggableElement, int draggableId, Element dropzoneElement) => listRendererService.dragDropElements.contains(draggableElement);

}