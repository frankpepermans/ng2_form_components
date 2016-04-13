library ng2_form_components.components.html_text_transform_component;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:angular2/angular2.dart';
import 'package:dorm/dorm.dart' show Entity;

import 'package:ng2_state/ng2_state.dart' show StatefulComponent, SerializableTuple1, StatePhase;

import 'package:ng2_form_components/ng2_form_components.dart' show FormComponent;
import 'package:ng2_form_components/src/components/helpers/html_text_transformation.dart' show HTMLTextTransformation;

@Component(
  selector: 'html-text-transform-component',
  templateUrl: 'html_text_transform_component.html',
  directives: const [NgClass],
  changeDetection: ChangeDetectionStrategy.OnPush
)
class HTMLTextTransformComponent extends FormComponent implements StatefulComponent, OnDestroy, OnInit, AfterViewInit {

  final ElementRef element;

  //-----------------------------
  // input
  //-----------------------------

  @Input() String model;
  @Input() List<List<HTMLTextTransformation>> buttons;

  //-----------------------------
  // output
  //-----------------------------

  @Output() Stream<String> get transformation => _modelTransformation$ctrl.stream;
  @Output() Stream<bool> get hasSelectedRange => _hasSelectedRange$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  rx.Observable<Range> _range$;
  rx.Observable<Tuple2<Range, HTMLTextTransformation>> _rangeTransform$;
  StreamSubscription<Tuple2<Range, HTMLTextTransformation>> _range$subscription;
  StreamSubscription<bool> _hasRangeSubscription;

  final StreamController<HTMLTextTransformation> _transformation$ctrl = new StreamController<HTMLTextTransformation>.broadcast();
  final StreamController<String> _modelTransformation$ctrl = new StreamController<String>.broadcast();
  final StreamController<bool> _hasSelectedRange$ctrl = new StreamController<bool>();

  String _lastProcessedRangeValue;
  Element _container;
  bool _isDestroyCalled = false;

  //-----------------------------
  // Constructor
  //-----------------------------

  HTMLTextTransformComponent(@Inject(ElementRef) this.element, @Inject(ChangeDetectorRef) ChangeDetectorRef changeDetector) : super(changeDetector);

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<SerializableTuple1> provideState() => _modelTransformation$ctrl.stream
    .where((String value) => value != null && value.isNotEmpty)
    .distinct((String vA, String vB) => vA.compareTo(vB) == 0)
    .map((String value) => new SerializableTuple1()..item1 = value);

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple1 tuple = entity as SerializableTuple1;
    final String incoming = tuple.item1;

    _updateInnerHtmlTrusted(incoming, false);
  }

  @override void ngOnInit() => _initStreams();

  @override void ngAfterViewInit() {
    _container = _findEditableElement(element.nativeElement);

    _updateInnerHtmlTrusted(model, false);
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();

    _container.removeEventListener('DOMSubtreeModified', _contentModifier);

    _isDestroyCalled = true;

    _range$subscription?.cancel();
    _hasRangeSubscription?.cancel();
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void transformSelection(HTMLTextTransformation transformationType) => _transformation$ctrl.add(transformationType);

  void onFocus(FocusEvent event) {
    _container.addEventListener('DOMSubtreeModified', _contentModifier);

    _range$subscription = _rangeTransform$
      .where((Tuple2<Range, HTMLTextTransformation> tuple) {
        final Range range = tuple.item1;
        final String currentRangeValue = '${range}_${range.startOffset}_${range.endOffset}_${tuple.item2.tag}';

        if (
        (
          (range.startContainer == range.endContainer) &&
          (range.startOffset == range.endOffset)
        ) ||
          (range.startOffset == 0 && range.endOffset == 0) ||
          (currentRangeValue == _lastProcessedRangeValue)
        ) return false;

        return true;
      })
      .listen(_transformContent) as StreamSubscription<Tuple2<Range, HTMLTextTransformation>>;
  }

  void onBlur(FocusEvent event) {
    _container.removeEventListener('DOMSubtreeModified', _contentModifier);

    _range$subscription.cancel();

    _range$subscription = null;
  }

  //-----------------------------
  // inner methods
  //-----------------------------

  void _updateInnerHtmlTrusted(String result, [bool notifyStateListeners=true]) {
    model = result;

    if (_container != null) _container.setInnerHtml(result, treeSanitizer: NodeTreeSanitizer.trusted);

    if (notifyStateListeners) _modelTransformation$ctrl.add(result);
  }

  void _initStreams() {
    _range$ = new rx.Observable.merge([
      document.onMouseUp,
      document.onKeyUp
    ], asBroadcastStream: true)
      .map((_) => window.getSelection())
      .map((Selection selection) {
        final List<Range> ranges = <Range>[];

        for (int i=0, len=selection.rangeCount; i<len; i++) {
          Range range = selection.getRangeAt(i);

          if (range.startContainer != range.endContainer || range.startOffset != range.endOffset) ranges.add(range);
        }

        return (ranges.isNotEmpty) ? ranges.first : null;
      }) as rx.Observable<Range>;

    _rangeTransform$ = _range$
      .tap((_) => _resetButtons())
      .where((Range range) => range != null)
      .tap(_analyzeRange)
      .flatMapLatest((Range range) => _transformation$ctrl.stream
        .take(1)
        .map((HTMLTextTransformation transformationType) => new Tuple2<Range, HTMLTextTransformation>(range, transformationType))
      ) as rx.Observable<Tuple2<Range, HTMLTextTransformation>>;

    _hasRangeSubscription = _range$
      .map((Range range) {
        if (range == null) return false;

        return ((range.startContainer == range.endContainer) && (range.startOffset == range.endOffset)) ? false : true;
      })
      .listen(_hasSelectedRange$ctrl.add) as StreamSubscription<bool>;
  }

  void _contentModifier(Event event) {
    model = _container.innerHtml;

    _modelTransformation$ctrl.add(model);
  }

  void _transformContent(Tuple2<Range, HTMLTextTransformation> tuple) {
    final StringBuffer buffer = new StringBuffer();
    final Range range = tuple.item1;

    final DocumentFragment extractedContent = range.extractContents();

    if (tuple.item2.doRemoveTag) {
      final List<Element> matchingElements = <Element>[];

      _findElements(extractedContent, tuple.item2.tag.toLowerCase(), matchingElements);

      for (int i=matchingElements.length-1; i>=0; i--) {
        Element element = matchingElements[i];

        element.replaceWith(new DocumentFragment.html(element.innerHtml, treeSanitizer: NodeTreeSanitizer.trusted));
      }

      if (tuple.item2.outerContainer != null) {
        buffer.write('<tmp_tag>');
        buffer.write(extractedContent.innerHtml);
        buffer.write('</tmp_tag>');
      } else {
        buffer.write(extractedContent.innerHtml);
      }

      tuple.item2.doRemoveTag = false;
    } else {
      buffer.write(_writeOpeningTag(tuple.item2));
      buffer.write(extractedContent.innerHtml);
      buffer.write(_writeClosingTag(tuple.item2));
    }

    range.insertNode(new DocumentFragment.html(buffer.toString(), treeSanitizer: NodeTreeSanitizer.trusted));

    if (tuple.item2.outerContainer != null) {
      range.selectNode(tuple.item2.outerContainer);

      final DocumentFragment extractedParentContent = range.extractContents();
      String result = extractedParentContent.innerHtml;

      result = result.replaceFirst(r'<tmp_tag>', _writeClosingTag(tuple.item2));
      result = result.replaceFirst(r'</tmp_tag>', _writeOpeningTag(tuple.item2));

      tuple.item2.outerContainer = null;

      range.insertNode(new DocumentFragment.html(result, treeSanitizer: NodeTreeSanitizer.trusted));
    }

    _resetButtons();
  }

  String _writeOpeningTag(HTMLTextTransformation transformation) {
    final StringBuffer buffer = new StringBuffer();

    buffer.write('<${transformation.tag}');

    if (transformation.id != null) buffer.write(' id="${transformation.id}"');

    if (transformation.className != null) buffer.write(' class="${transformation.className}"');

    if (transformation.style != null) {
      final List<String> styleParts = <String>[];

      transformation.style.forEach((String K, String V) => styleParts.add('$K:$V'));

      buffer.write(' style="${styleParts.join(';')}"');
    }

    if (transformation.attributes != null) {
      final List<String> attributes = <String>[];

      transformation.attributes.forEach((String K, String V) {
        if (V == null || V.toLowerCase() == 'true') attributes.add(K);
        else attributes.add('$K="$V"');
      });

      buffer.write(' ${attributes.join(' ')}');
    }

    buffer.write('>');

    return buffer.toString();
  }

  String _writeClosingTag(HTMLTextTransformation transformation) => '</${transformation.tag}>';

  Element _findEditableElement(Element element) {
    element.childNodes.firstWhere((Node childNode) => (childNode is Element && childNode.contentEditable == 'true'), orElse: () => null);

    for (int i=0, len=element.childNodes.length; i<len; i++) {
      Node childNode = element.childNodes[i];
      bool isElement = childNode is Element;

      if (isElement && (childNode as Element).contentEditable == 'true') return childNode;

      if (isElement) {
        Element childElement = _findEditableElement(childNode);

        if (childElement != null) return childElement;
      }
    }

    return null;
  }

  void _resetButtons() {
    List<HTMLTextTransformation> allButtons = buttons.fold(<HTMLTextTransformation>[], (List<HTMLTextTransformation> prev, List<HTMLTextTransformation> value) {
      prev.addAll(value);

      return prev;
    });

    allButtons.forEach((HTMLTextTransformation transformation) => transformation.doRemoveTag = false);

    changeDetector.markForCheck();
  }

  void _analyzeRange(Range range) {
    final DocumentFragment fragment = range.cloneContents();
    final Map<String, int> span = <String, int>{};
    final int textLength = fragment.text.length;

    fragment.children.forEach((Element element) => _mapChildElements(element, span));

    List<HTMLTextTransformation> allButtons = buttons.fold(<HTMLTextTransformation>[], (List<HTMLTextTransformation> prev, List<HTMLTextTransformation> value) {
      prev.addAll(value);

      return prev;
    });

    span.forEach((String K, int V) => print('$K: $V'));

    allButtons.forEach((HTMLTextTransformation transformation) {
      final String tag = _toNodeNameFromTransformation(transformation);

      transformation.doRemoveTag = (span.containsKey(tag) && span[tag] == textLength);

      print('$tag: ${span[tag]}: $textLength');

      if (!transformation.doRemoveTag && range.startContainer == range.endContainer) {
        Node currentNode = range.startContainer;

        while (currentNode != null) {print('looking at: ${_toNodeNameFromElement(currentNode)}: trying to match: $tag');
          if (_toNodeNameFromElement(currentNode) == tag) {
            transformation.doRemoveTag = true;
            transformation.outerContainer = currentNode;
            print('has match!');
            break;
          }

          currentNode = currentNode.parentNode;
        }
      }
    });

    changeDetector.markForCheck();
  }

  void _mapChildElements(Element element, Map<String, int> elementSpan, [List<String> elementsEncountered]) {
    final String nodeName = _toNodeNameFromElement(element);

    elementsEncountered = elementsEncountered ?? <String>[];

    if (!elementsEncountered.contains(nodeName)) {
      if (!elementSpan.containsKey(nodeName)) elementSpan[nodeName] = element.text.length;
      else elementSpan[nodeName] += element.text.length;
    }

    elementsEncountered.add(nodeName);

    element.children.forEach((Element E) => _mapChildElements(E, elementSpan, elementsEncountered));
  }

  String _toNodeNameFromElement(Node element) {
    List<String> nameList = <String>[element.nodeName.toUpperCase()];

    if (element is Element && element.attributes != null) element.attributes.forEach((String K, String V) => nameList.add('$K:$V'));

    return nameList.join('|');
  }

  String _toNodeNameFromTransformation(HTMLTextTransformation transformation) {
    List<String> nameList = <String>[transformation.tag.toUpperCase()];

    if (transformation.attributes != null) transformation.attributes.forEach((String K, String V) => nameList.add('$K:$V'));

    return nameList.join('|');
  }

  void _findElements(Node element, String nodeName, List<Element> elements) {
    if (element.nodeName.toLowerCase() == nodeName) elements.add(element);

    if (element is DocumentFragment) element.children.forEach((Element E) => _findElements(E, nodeName, elements));
    else if (element is Element) element.children.forEach((Element E) => _findElements(E, nodeName, elements));
  }
}