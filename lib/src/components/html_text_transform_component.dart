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
  templateUrl: 'html_text_transform_component.html'
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

  @Output() Stream get transformation => _modelTransformation$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  rx.Observable<Range> _range$;
  rx.Observable<Tuple2<Range, HTMLTextTransformation>> _rangeTransform$;
  StreamSubscription<String> _range$subscription;

  final StreamController<num> _animation$ctrl = new StreamController<num>.broadcast();
  final StreamController<HTMLTextTransformation> _transformation$ctrl = new StreamController<HTMLTextTransformation>.broadcast();
  final StreamController<String> _modelTransformation$ctrl = new StreamController<String>.broadcast();

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

  Stream<SerializableTuple1> provideState() => _modelTransformation$ctrl.stream
    .where((String value) => value != null && value.isNotEmpty)
    .distinct((String vA, String vB) => vA.compareTo(vB) == 0)
    .map((String value) => new SerializableTuple1()..item1 = value);

  void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple1 tuple = entity as SerializableTuple1;
    final String incoming = tuple.item1;

    _updateInnerHtmlTrusted(incoming, false);
  }

  void ngOnInit() => _initStreams();

  void ngAfterViewInit() {
    _container = _findEditableElement(element.nativeElement);

    _updateInnerHtmlTrusted(model, false);
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();
    // onBlur will destroy any subscriptions, no need to do it again here
    _isDestroyCalled = true;
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
      .map(_transformContent)
      .where((String result) => result != null)
      .listen(_updateInnerHtmlTrusted, onError: (e) => print('error: $e')) as StreamSubscription<String>;
  }

  void onBlur(FocusEvent event) {
    _container.removeEventListener('DOMSubtreeModified', _contentModifier);

    _range$subscription.cancel();
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
    _nextAnimationFrame();

    _range$ = rx.observable(_animation$ctrl.stream)
      .map((_) => window.getSelection())
      .map((Selection selection) {
        final List<Range> ranges = <Range>[];

        for (int i=0, len=selection.rangeCount; i<len; i++) {
          Range range = selection.getRangeAt(i);

          if (range.startOffset != range.endOffset) ranges.add(range);
        }

        return (ranges.isNotEmpty) ? ranges.first : null;
      })
      .where((Range range) => range != null)
      .distinct(_areSameRanges) as rx.Observable<Range>;

    _rangeTransform$ = _range$
      .flatMapLatest((Range range) => _transformation$ctrl.stream
        .take(1)
        .map((HTMLTextTransformation transformationType) => new Tuple2<Range, HTMLTextTransformation>(range, transformationType))
      ) as rx.Observable<Tuple2<Range, HTMLTextTransformation>>;
  }

  bool _areSameRanges(Range rangeA, Range rangeB) => (
    rangeA.startContainer == rangeB.startContainer &&
    rangeA.startOffset == rangeB.startOffset &&
    rangeA.endOffset == rangeB.endOffset
  );

  void _nextAnimationFrame() {
    window.animationFrame.then((num time) {
      _animation$ctrl.add(time);

      if (!_isDestroyCalled) _nextAnimationFrame();
    });
  }

  void _contentModifier(Event event) {
    model = _container.innerHtml;

    _modelTransformation$ctrl.add(model);
  }

  String _transformContent(Tuple2<Range, HTMLTextTransformation> tuple) {
    final StringBuffer buffer = new StringBuffer();
    final Range range = tuple.item1;
    final String oldContent = model;
    int startOffset = -1, endOffset = -1;

    range.extractContents();
    range.insertNode(new Element.tag('section'));

    final String newContent = _container.innerHtml;

    for (int i=0, len=oldContent.length; i<len; i++) {
      if (startOffset == -1 && oldContent.codeUnitAt(i) != newContent.codeUnitAt(i)) {
        startOffset = i;
      }

      if (endOffset == -1 && oldContent.codeUnitAt(oldContent.length - i - 1) != newContent.codeUnitAt(newContent.length - i - 1)) {
        endOffset = oldContent.length - i;
      }

      if (startOffset >= 0 && endOffset >= 0) break;
    }

    buffer.write(oldContent.substring(0, startOffset));
    buffer.write('<${tuple.item2.tag}');

    if (tuple.item2.id != null) buffer.write(' id="${tuple.item2.id}"');

    if (tuple.item2.style != null) {
      final List<String> styleParts = <String>[];

      tuple.item2.style.forEach((String K, String V) => styleParts.add('${K}:${V}'));

      buffer.write(' style="${styleParts.join(';')}"');
    }

    buffer.write('>');
    buffer.write(oldContent.substring(startOffset, endOffset));
    buffer.write('</${tuple.item2.tag}>');
    buffer.write(oldContent.substring(endOffset));

    return buffer.toString();
  }

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
}