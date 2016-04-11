library ng2_form_components.components.helpers.drag_drop;

import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/animate.dart';

import 'package:dnd/dnd.dart';

typedef void DragDropHandler(int dragItemIndex, int dropItemIndex);

@Directive(
    selector: '[drag-drop]'
)
class DragDrop implements AfterViewInit {

  DragDropHandler _handler;
  DragDropHandler get handler => _handler;
  @Input() void set handler(DragDropHandler value) {
    _handler = value;
  }

  static int _dragDropSessionId = 1;

  final AnimationBuilder animationBuilder;
  final ElementRef element;

  Element nativeElement;
  CssAnimationBuilder cssAnimationBuilder;

  List<Element> list;

  DragDrop(@Inject(AnimationBuilder) this.animationBuilder, @Inject(ElementRef) this.element) {
    nativeElement = element.nativeElement as Element;
    cssAnimationBuilder = animationBuilder.css();
  }

  void ngAfterViewInit() {
    final ddId = _dragDropSessionId++;

    list = <Element>[];

    _compileSortablesList(nativeElement, list);

    list.forEach((Element element) => element.className = _appendStyleName(element.className, '_sortable_$ddId'));

    final ElementList<Element> elements = querySelectorAll('._sortable_$ddId');

    new Draggable(elements, avatarHandler: new AvatarHandler.clone());
    new Dropzone(elements)..onDrop.listen(_handleSwap);
  }

  void _handleSwap(DropzoneEvent event) {
    if (handler != null) handler(
        list.indexOf(event.draggableElement),
        list.indexOf(event.dropzoneElement)
    );
  }

  void _compileSortablesList(Element element, List<Element> list) {
    element.children.forEach((Element childElement) {
      if (childElement.attributes.containsKey('drag-drop-target')) list.add(childElement);

      _compileSortablesList(childElement, list);
    });
  }

  String _appendStyleName(String existingClassName, String toAppend) {
    if (existingClassName == null || existingClassName.trim().isEmpty) return toAppend;

    final List<String> cssNames = existingClassName.trim().split(' ');

    cssNames.add(toAppend);

    return cssNames.join(' ');
  }
}