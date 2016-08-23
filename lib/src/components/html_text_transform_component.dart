library ng2_form_components.components.html_text_transform_component;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:angular2/angular2.dart';
import 'package:dorm/dorm.dart' show Entity;

import 'package:ng2_state/ng2_state.dart' show StatefulComponent, SerializableTuple1, StatePhase, StateService;

import 'package:ng2_form_components/ng2_form_components.dart' show FormComponent;
import 'package:ng2_form_components/src/components/helpers/html_text_transformation.dart' show HTMLTextTransformation;
import 'package:ng2_form_components/src/components/helpers/html_transform.dart' show HTMLTransform;

import 'package:ng2_form_components/src/components/html_text_transform_menu.dart';

typedef RangeModifier(Range range);

@Component(
  selector: 'html-text-transform-component',
  templateUrl: 'html_text_transform_component.html',
  directives: const [NgClass],
  providers: const <Type>[StateService],
  changeDetection: ChangeDetectionStrategy.OnPush
)
class HTMLTextTransformComponent extends FormComponent implements StatefulComponent, OnDestroy, AfterViewInit {

  final ElementRef element;
  final HTMLTransform transformer = new HTMLTransform();

  ElementRef _contentElement;
  ElementRef get contentElement => _contentElement;
  @ViewChild('content') void set contentElement(ElementRef value) {
    _contentElement = value;

    _setupListeners();
  }

  //-----------------------------
  // input
  //-----------------------------

  @Input() String model;
  @Input() RangeModifier rangeModifier;
  @Input() bool isContentLocked = false;

  HTMLTextTransformMenu _menu;
  HTMLTextTransformMenu get menu => _menu;
  @Input() void set menu(HTMLTextTransformMenu value) {
    _menu = value;

    _menuSubscription?.cancel();

    if (value != null) _menuSubscription = value.transformation.listen(transformSelection);
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output() Stream<String> get transformation => _modelTransformation$ctrl.stream;
  @Output() Stream<bool> get hasSelectedRange => _hasSelectedRange$ctrl.stream;
  @Output() Stream<String> get rangeText => _rangeToString$ctrl.stream;
  @Output() Stream<bool> get blur => _blurTrigger$ctrl.stream;
  @Output() Stream<bool> get focus => _focusTrigger$ctrl.stream;
  @Output() Stream<Range> get rangeSelection => _activeRange$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  rx.Observable<Range> _range$;
  rx.Observable<Tuple2<Range, HTMLTextTransformation>> _rangeTransform$;
  StreamSubscription<Tuple2<Range, HTMLTextTransformation>> _range$subscription;
  StreamSubscription<bool> _hasRangeSubscription;
  StreamSubscription<HTMLTextTransformation> _menuSubscription;
  StreamSubscription<KeyboardEvent> _keyboardSubscription;
  StreamSubscription<KeyboardEvent> _noInputOnSelectionSubscription;
  StreamSubscription<String> _pasteSubscription;
  StreamSubscription<Range> _activeRangeSubscription;

  final StreamController<Range> _activeRange$ctrl = new StreamController<Range>.broadcast();
  final StreamController<HTMLTextTransformation> _transformation$ctrl = new StreamController<HTMLTextTransformation>.broadcast();
  final StreamController<String> _modelTransformation$ctrl = new StreamController<String>.broadcast();
  final StreamController<bool> _hasSelectedRange$ctrl = new StreamController<bool>();
  final StreamController<bool> _rangeTrigger$ctrl = new StreamController<bool>();
  final StreamController<bool> _blurTrigger$ctrl = new StreamController<bool>();
  final StreamController<bool> _focusTrigger$ctrl = new StreamController<bool>();
  final StreamController<String> _rangeToString$ctrl = new StreamController<String>();

  //-----------------------------
  // Constructor
  //-----------------------------

  HTMLTextTransformComponent(
    @Inject(ElementRef) ElementRef elementRef,
    @Inject(ChangeDetectorRef) ChangeDetectorRef changeDetector,
    @Inject(StateService) StateService stateService) :
      this.element = elementRef,
      super(changeDetector, elementRef, stateService) {
    document.execCommand('insertBrOnReturn');
  }

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

  @override void ngAfterViewInit() {
    _updateInnerHtmlTrusted(model, false);

    _initStreams();
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();

    final Element element = _contentElement.nativeElement as Element;

    element.removeEventListener('DOMSubtreeModified', _contentModifier);

    _activeRangeSubscription?.cancel();
    _range$subscription?.cancel();
    _hasRangeSubscription?.cancel();
    _menuSubscription?.cancel();
    _keyboardSubscription?.cancel();
    _noInputOnSelectionSubscription?.cancel();
    _pasteSubscription?.cancel();
  }

  void _setupListeners() {
    _keyboardSubscription?.cancel();

    if (_contentElement != null) {
      final Element element = _contentElement.nativeElement as Element;

      _keyboardSubscription = element.onKeyDown
        .listen(_handleKeyDown);
    }
  }

  void _handleKeyDown(KeyboardEvent event) {
    if (event.keyCode == 10 || event.keyCode == 13) {
      event.preventDefault();

      document.execCommand('insertHTML', false, '<br><br>');
    }
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void transformSelection(HTMLTextTransformation transformationType) => _transformation$ctrl.add(transformationType);

  void forceUpdate(String result, [bool notifyStateListeners=true]) => _updateInnerHtmlTrusted(result, notifyStateListeners);

  //-----------------------------
  // inner methods
  //-----------------------------

  void _updateInnerHtmlTrusted(String result, [bool notifyStateListeners=true]) {
    model = result;

    if (contentElement != null) {
      final Element element = contentElement.nativeElement;

      element.setInnerHtml(result, treeSanitizer: NodeTreeSanitizer.trusted);
    }

    if (notifyStateListeners) _modelTransformation$ctrl.add(result);
  }

  void _initStreams() {
    _range$ = new rx.Observable.merge([
      document.onMouseDown,
      document.onMouseUp,
      document.onKeyDown,
      document.onKeyUp,
      rx.observable(_rangeTrigger$ctrl.stream),
    ], asBroadcastStream: true)
      .map((_) => window.getSelection())
      .map((Selection selection) {
        if (selection.rangeCount > 0) {
          if (rangeModifier != null) return rangeModifier(selection.getRangeAt(0));

          return selection.getRangeAt(0);
        }

        return null;
      });

    _activeRangeSubscription = _range$
      .listen(_activeRange$ctrl.add);

    _rangeTransform$ = _range$
      .map(_resetButtons)
      .where(_hasValidRange)
      .map(_extractSelectionToString)
      .map(_analyzeRange)
      .flatMapLatest((Range range) => _transformation$ctrl.stream
        .take(1)
        .map((HTMLTextTransformation transformationType) => new Tuple2<Range, HTMLTextTransformation>(range, transformationType))
      );

    final Element element = _contentElement.nativeElement as Element;

    element.addEventListener('DOMSubtreeModified', _contentModifier);

    _pasteSubscription = rx.observable(element.onPaste)
      .flatMapLatest((_) => _modelTransformation$ctrl.stream)
      .listen((String value) {
        if (value != null && value.length > 5 && value.trim().substring(0, 5) == '<div>') {
          final DocumentFragment fragment = new DocumentFragment();

          fragment.setInnerHtml(element.innerHtml
              .replaceAll(r'<div>', '')
              .replaceAll(r'</div>', '<br>'), treeSanitizer: NodeTreeSanitizer.trusted);

          _updateInnerHtmlTrusted(fragment.innerHtml);
        }
      });

    _range$subscription = _rangeTransform$
      .flatMapLatest((Tuple2<Range, HTMLTextTransformation> tuple) => new Stream.fromFuture(tuple.item2.setup())
        .map((HTMLTextTransformation transformation) {
          transformation.owner = tuple.item2;
          transformation.doRemoveTag = tuple.item2.doRemoveTag;
          transformation.outerContainer = tuple.item2.outerContainer;

          return new Tuple2<Range, HTMLTextTransformation>(tuple.item1, transformation);
        }))
      .where((Tuple2<Range, HTMLTextTransformation> tuple) => tuple.item2 != null)
      .listen(_transformContent);

    _hasRangeSubscription = _range$
      .map(_hasValidRange)
      .listen(_hasSelectedRange$ctrl.add);

    _noInputOnSelectionSubscription = rx.observable(element.onMouseDown)
      .flatMapLatest((_) => rx.observable(element.onKeyDown)
        .map((KeyboardEvent event) {
          event.preventDefault();

          return event;
        })
        .takeUntil(element.onMouseUp)
      )
      .listen((_) {});
  }

  bool _hasValidRange(Range range) {
    if (range == null) return false;

    Node currentNode = range.commonAncestorContainer;
    bool isOwnRange = false;

    while (currentNode != null) {
      if (currentNode == contentElement.nativeElement) {
        isOwnRange = true;

        break;
      }

      currentNode = currentNode.parentNode;
    }

    if (!isOwnRange) return false;

    return ((range.startContainer == range.endContainer) && (range.startOffset == range.endOffset)) ? false : true;
  }

  void _contentModifier(Event event) {
    model = contentElement.nativeElement.innerHtml;

    _modelTransformation$ctrl.add(model);
  }

  void _transformContent(Tuple2<Range, HTMLTextTransformation> tuple) {
    final String tag = tuple.item2.tag.toLowerCase();

    _rangeTrigger$ctrl.add(true);

    switch (tag) {
      case 'b':
        document.execCommand('bold'); return;
      case 'i':
        document.execCommand('italic'); return;
      case 'u':
        document.execCommand('underline'); return;
      case 'li':
        document.execCommand('insertOrderedList'); return;
      case 'justifyleft':
        document.execCommand('justifyLeft'); return;
      case 'justifycenter':
        document.execCommand('justifyCenter'); return;
      case 'justifyright':
        document.execCommand('justifyRight'); return;
      case 'header':
        document.execCommand('fontSize', false, '32px'); return;
      case 'clear':
        document.execCommand('removeFormat'); return;
      case 'undo':
        document.execCommand('undo'); return;
      case 'redo':
        document.execCommand('redo'); return;
      default:
        _injectCustomTag(tuple);
    }
  }

  void _injectCustomTag(Tuple2<Range, HTMLTextTransformation> tuple) {
    final StringBuffer buffer = new StringBuffer();
    final Range range = tuple.item1;

    final DocumentFragment extractedContent = range.extractContents();

    if (tuple.item2.doRemoveTag) {
      transformer.removeTransformation(tuple.item2, extractedContent);

      if (tuple.item2.outerContainer != null) {
        buffer.write('<tmp_tag>');
        buffer.write(tuple.item2.body != null ? tuple.item2.body : extractedContent.innerHtml);
        buffer.write('</tmp_tag>');
      } else {
        buffer.write(extractedContent.innerHtml);
      }

      tuple.item2.doRemoveTag = false;
    } else {
      buffer.write(_writeOpeningTag(tuple.item2));
      buffer.write(tuple.item2.body != null ? tuple.item2.body : extractedContent.innerHtml);
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

    _rangeTrigger$ctrl.add(true);
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

  Range _extractSelectionToString(Range forRange) {
    _rangeToString$ctrl.add(forRange.cloneContents().text);

    return forRange;
  }

  Range _resetButtons(Range forRange) {
    if (menu?.buttons != null) {
      List<HTMLTextTransformation> allButtons = menu.buttons.fold(<HTMLTextTransformation>[], (List<HTMLTextTransformation> prev, List<HTMLTextTransformation> value) {
        prev.addAll(value);

        return prev;
      });

      allButtons.forEach((HTMLTextTransformation transformation) => transformation.doRemoveTag = false);

      changeDetector.markForCheck();
    }

    return forRange;
  }

  Range _analyzeRange(Range range) {
    if (menu?.buttons != null) {
      final DocumentFragment fragment = range.cloneContents();
      final List<String> encounteredElementFullNames = transformer.listChildTagsByFullName(fragment);

      List<HTMLTextTransformation> allButtons = menu.buttons.fold(<HTMLTextTransformation>[], (List<HTMLTextTransformation> prev, List<HTMLTextTransformation> value) {
        prev.addAll(value);

        return prev;
      });

      allButtons.forEach((HTMLTextTransformation transformation) {
        final String tag = transformer.toNodeNameFromTransformation(transformation);

        transformation.doRemoveTag = transformation.allowRemove && encounteredElementFullNames.contains(tag);

        if (transformation.allowRemove && !transformation.doRemoveTag && range.startContainer == range.endContainer) {
          Node currentNode = range.startContainer;

          while (currentNode != null && currentNode != this.element.nativeElement) {
            if (transformer.toNodeNameFromElement(currentNode) == tag) {
              transformation.doRemoveTag = true;
              transformation.outerContainer = currentNode;

              break;
            }

            currentNode = currentNode.parentNode;
          }
        }
      });

      changeDetector.markForCheck();

      menu.changeDetector.markForCheck();
    }

    return range;
  }

  void handleFocus() => _focusTrigger$ctrl.add(true);

  void handleBlur() => _blurTrigger$ctrl.add(true);
}