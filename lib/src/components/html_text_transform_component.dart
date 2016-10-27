library ng2_form_components.components.html_text_transform_component;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:angular2/angular2.dart';
import 'package:dorm/dorm.dart' show Entity;

import 'package:ng2_state/ng2_state.dart' show StatefulComponent, SerializableTuple1, StatePhase, StateService;

import 'package:ng2_form_components/src/components/internal/form_component.dart' show FormComponent;
import 'package:ng2_form_components/src/components/helpers/html_text_transformation.dart' show HTMLTextTransformation;
import 'package:ng2_form_components/src/components/helpers/html_transform.dart' show HTMLTransform;

import 'package:ng2_form_components/src/components/html_text_transform_menu.dart' show HTMLTextTransformMenu;

import 'package:ng2_form_components/src/utils/window_listeners.dart' show WindowListeners;

typedef Range RangeModifier(Range range);
typedef String ContentInterceptor(String value);

@Component(
  selector: 'html-text-transform-component',
  templateUrl: 'html_text_transform_component.html',
  providers: const <Type>[StateService],
  changeDetection: ChangeDetectionStrategy.OnPush,
  preserveWhitespace: false
)
class HTMLTextTransformComponent extends FormComponent<Comparable<dynamic>> implements StatefulComponent, OnDestroy, AfterViewInit {

  final ElementRef element;
  final HTMLTransform transformer = new HTMLTransform();
  final WindowListeners windowListeners = new WindowListeners();

  ElementRef _contentElement;
  ElementRef get contentElement => _contentElement;
  @ViewChild('content') set contentElement(ElementRef value) {
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
  @Input() set menu(HTMLTextTransformMenu value) {
    _menu = value;

    _menuSubscription?.cancel();

    if (value != null) _menuSubscription = value.transformation.listen(transformSelection);
  }

  ContentInterceptor _interceptor;
  ContentInterceptor get interceptor => _interceptor;
  @Input() set interceptor(ContentInterceptor value) {
    _interceptor = value;

    _interceptorChanged$ctrl.add(true);
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output() Stream<String> get transformation => _modelTransformation$ctrl.stream;
  @Output() Stream<bool> get hasSelectedRange => _hasSelectedRange$ctrl.stream;
  @Output() Stream<String> get rangeText => _rangeToString$ctrl.stream.map((Range range) => range.cloneContents().text);
  @Output() Stream<bool> get blur => _blurTrigger$ctrl.stream;
  @Output() Stream<bool> get focus => _focusTrigger$ctrl.stream;
  @Output() Stream<Range> get rangeSelection => _activeRange$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  static bool _HAS_MODIFIED_INSERT_LINE_RULE = false;

  rx.Observable<Range> _range$;
  rx.Observable<Tuple2<Range, HTMLTextTransformation>> _rangeTransform$;
  StreamSubscription<Tuple2<Range, HTMLTextTransformation>> _range$subscription;
  StreamSubscription<bool> _hasRangeSubscription;
  StreamSubscription<HTMLTextTransformation> _menuSubscription;
  StreamSubscription<KeyboardEvent> _keyboardSubscription;
  StreamSubscription<KeyboardEvent> _noInputOnSelectionSubscription;
  StreamSubscription<String> _pasteSubscription;
  StreamSubscription<Range> _activeRangeSubscription;
  StreamSubscription<String> _contentSubscription;
  StreamSubscription<String> _mutationObserverSubscription;

  final StreamController<Range> _activeRange$ctrl = new StreamController<Range>.broadcast();
  final StreamController<HTMLTextTransformation> _transformation$ctrl = new StreamController<HTMLTextTransformation>.broadcast();
  final StreamController<String> _mutationObserver$ctrl = new StreamController<String>.broadcast();
  final StreamController<String> _modelTransformation$ctrl = new StreamController<String>.broadcast();
  final StreamController<bool> _hasSelectedRange$ctrl = new StreamController<bool>();
  final StreamController<bool> _rangeTrigger$ctrl = new StreamController<bool>();
  final StreamController<bool> _blurTrigger$ctrl = new StreamController<bool>();
  final StreamController<bool> _focusTrigger$ctrl = new StreamController<bool>();
  final StreamController<Range> _rangeToString$ctrl = new StreamController<Range>();
  final StreamController<String> _content$ctrl = new StreamController<String>.broadcast();
  final StreamController<bool> _interceptorChanged$ctrl = new StreamController<bool>();

  MutationObserver _observer;

  //-----------------------------
  // Constructor
  //-----------------------------

  HTMLTextTransformComponent(
    @Inject(ElementRef) ElementRef elementRef,
    @Inject(ChangeDetectorRef) ChangeDetectorRef changeDetector,
    @Inject(StateService) StateService stateService) :
      this.element = elementRef,
      super(changeDetector, elementRef, stateService) {
    if (!_HAS_MODIFIED_INSERT_LINE_RULE) {
      _HAS_MODIFIED_INSERT_LINE_RULE = true;

      document.execCommand('insertBrOnReturn');
    }
  }

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override Stream<SerializableTuple1<String>> provideState() => _modelTransformation$ctrl.stream
    .where((String value) => value != null && value.isNotEmpty)
    .distinct((String vA, String vB) => vA.compareTo(vB) == 0)
    .map((String value) => new SerializableTuple1<String>()..item1 = value);

  @override void receiveState(Entity entity, StatePhase phase) {
    final SerializableTuple1<String> tuple = entity as SerializableTuple1<String>;
    final String incoming = tuple.item1;

    _updateInnerHtmlTrusted(incoming, false);
  }

  @override void ngAfterViewInit() {
    _updateInnerHtmlTrusted(model, false);

    _initStreams();
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();

    _observer.disconnect();

    _activeRangeSubscription?.cancel();
    _range$subscription?.cancel();
    _hasRangeSubscription?.cancel();
    _menuSubscription?.cancel();
    _keyboardSubscription?.cancel();
    _noInputOnSelectionSubscription?.cancel();
    _pasteSubscription?.cancel();
    _contentSubscription?.cancel();
    _mutationObserverSubscription?.cancel();

    _activeRange$ctrl.close();
    _transformation$ctrl.close();
    _modelTransformation$ctrl.close();
    _hasSelectedRange$ctrl.close();
    _rangeTrigger$ctrl.close();
    _blurTrigger$ctrl.close();
    _focusTrigger$ctrl.close();
    _rangeToString$ctrl.close();
    _content$ctrl.close();
    _mutationObserver$ctrl.close();
    _interceptorChanged$ctrl.close();
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
    _content$ctrl.add(result);

    if (notifyStateListeners) _modelTransformation$ctrl.add(result);
  }

  void _initStreams() {
    final Element element = _contentElement.nativeElement as Element;

    _contentSubscription = new rx.Observable<String>.combineLatest(<Stream<dynamic>>[
      rx.observable(_content$ctrl.stream)
        .startWith(<String>[model])
        .distinct(),
      rx.observable(_interceptorChanged$ctrl.stream)
        .startWith(const <bool>[false])
    ], (String newContent, _) => newContent)
      .listen((String newContent) {
        _setInnerHtml(newContent);

        _contentModifier(null, null);
      });

    _mutationObserverSubscription = rx.observable(_mutationObserver$ctrl.stream)
      .debounce(const Duration(milliseconds: 80))
      .listen((String content) {
        if (!_modelTransformation$ctrl.isClosed) {
          if (model == null || model.compareTo(contentElement.nativeElement.innerHtml) != 0) {
            model = contentElement.nativeElement.innerHtml;

            _content$ctrl.add(model);

            _modelTransformation$ctrl.add(model);
          }
        }
      });

    _range$ = new rx.Observable<dynamic>.merge(<Stream<dynamic>>[
      element.onMouseDown,
      rx.observable(element.onMouseDown)
        .flatMapLatest((_) => document.onMouseUp.take(1)),
      element.onKeyDown,
      rx.observable(element.onKeyDown)
        .flatMapLatest((_) => document.onKeyUp.take(1)),
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
      .map(_analyzeRange)
      .where(_hasValidRange)
      .map(_extractSelectionToString)
      .flatMapLatest((Range range) => _transformation$ctrl.stream
        .take(1)
        .map((HTMLTextTransformation transformationType) => new Tuple2<Range, HTMLTextTransformation>(range, transformationType))
      );

    _observer = new MutationObserver(_contentModifier)
      ..observe(element, characterData: true, subtree: true, characterDataOldValue: true, childList: true, attributes: true);

    _pasteSubscription = rx.observable(element.onPaste)
      .flatMapLatest((_) => _modelTransformation$ctrl.stream)
      .listen((String value) {
        if (value != null && value.length > 5 && value.trim().substring(0, 5) == '<div>') {
          final DocumentFragment fragment = new DocumentFragment();
          final Element element = _contentElement.nativeElement as Element;

          fragment.setInnerHtml(element.innerHtml
              .replaceAll(r'<div>', '')
              .replaceAll(r'</div>', '<br>'), treeSanitizer: NodeTreeSanitizer.trusted);

          _updateInnerHtmlTrusted(fragment.innerHtml);
        }
      });

    _range$subscription = _rangeTransform$
      .flatMapLatest((Tuple2<Range, HTMLTextTransformation> tuple) => new Stream<HTMLTextTransformation>.fromFuture(tuple.item2.setup())
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
        .takeUntil(document.onMouseUp)
      )
      .listen((_) {});
  }

  void _setInnerHtml(String newContent) {
    final Element element = _contentElement.nativeElement as Element;

    if (_interceptor != null) newContent = _interceptor(newContent);

    if (newContent != element.innerHtml) element.setInnerHtml(newContent, treeSanitizer: NodeTreeSanitizer.trusted);
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

    return true;
  }

  void _contentModifier(List<MutationRecord> records, _) {
    if (!_mutationObserver$ctrl.isClosed) _mutationObserver$ctrl.add(contentElement.nativeElement.innerHtml);
  }

  void _transformContent(Tuple2<Range, HTMLTextTransformation> tuple) {
    final String tag = tuple.item2.tag.toLowerCase();

    switch (tag) {
      case 'b':
        _execDocumentCommand('bold'); return;
      case 'i':
        _execDocumentCommand('italic'); return;
      case 'u':
        _execDocumentCommand('underline'); return;
      case 'ol':
        _execDocumentCommand('insertOrderedList'); return;
      case 'ul':
        _execDocumentCommand('insertUnorderedList'); return;
      case 'justifyleft':
        _execDocumentCommand('justifyLeft'); return;
      case 'justifycenter':
        _execDocumentCommand('justifyCenter'); return;
      case 'justifyright':
        _execDocumentCommand('justifyRight'); return;
      case 'justifyfull':
        _execDocumentCommand('justifyFull'); return;
      case 'header':
        _execDocumentCommand('fontSize', false, '32px'); return;
      case 'clear':
        _execDocumentCommand('removeFormat'); return;
      case 'undo':
        _execDocumentCommand('undo'); return;
      case 'redo':
        _execDocumentCommand('redo'); return;
      default:
        if ((tuple.item1.startContainer != tuple.item1.endContainer) || (tuple.item1.startOffset != tuple.item1.endOffset)) {
          _injectCustomTag(tuple);
          _rangeTrigger$ctrl.add(true);
        }
    }
  }

  void _execDocumentCommand(String command, [bool showUI = null, String value = null]) {
    document.execCommand(command, showUI, value);

    _rangeTrigger$ctrl.add(true);
  }

  List<Node> _listAllNodes(Node node, {List<Node> allNodes}) {
    allNodes.add(node);

    node.childNodes.forEach((Node childNode) => _listAllNodes(childNode, allNodes: allNodes));

    return allNodes;
  }

  void _injectCustomTag(Tuple2<Range, HTMLTextTransformation> tuple) {
    final StringBuffer buffer = new StringBuffer();
    final Range range = tuple.item1;
    final List<Node> allNodes = <Node>[];
    Node root = range.commonAncestorContainer;
    bool isRangeModified = false;

    while (root != contentElement.nativeElement) {
      if (root.parent.text.compareTo(root.text) == 0) root = root.parent;
      else break;
    }

    _listAllNodes(root, allNodes: allNodes);

    allNodes.forEach((Node node) {
      if (node is Element) {
        String nodeName = node.nodeName.toLowerCase();

        if (nodeName == 'li' || node.attributes.containsKey('editor-wrap-on-selection')) {
          if (node.contains(range.startContainer)) {
            range.setStartBefore(node);

            isRangeModified = true;
          }

          if (node.contains(range.endContainer)) {
            range.setEndAfter(node);

            isRangeModified = true;
          }

          if (node == root) {
            range.setStartBefore(node);
            range.setEndAfter(node);

            isRangeModified = true;
          }
        }
      }
    });

    if (isRangeModified) {
      final Selection selection = window.getSelection();

      selection.removeAllRanges();
      selection.addRange(range);
    }

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

    /*_modelTransformation$ctrl.stream
      .take(1)
      .listen((_) => window.getSelection().removeAllRanges());*/
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
    _rangeToString$ctrl.add(forRange);

    return forRange;
  }

  Range _resetButtons(Range forRange) {
    if (menu?.buttons != null) {
      bool isChanged = false;
      List<HTMLTextTransformation> allButtons = menu.buttons.fold(<HTMLTextTransformation>[], (List<HTMLTextTransformation> prev, List<HTMLTextTransformation> value) {
        prev.addAll(value);

        return prev;
      });

      allButtons.forEach((HTMLTextTransformation transformation) {
        if (transformation.doRemoveTag) {
          transformation.doRemoveTag = false;

          isChanged = true;
        }
      });

      if (isChanged) changeDetector.markForCheck();
    }

    return forRange;
  }

  Range _analyzeRange(Range range) {
    if (menu?.buttons != null && range != null) {
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