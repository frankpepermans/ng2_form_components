library ng2_form_components.components.html_text_transform_component;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:angular2/angular2.dart';
import 'package:angular2/platform/browser.dart' show DOCUMENT;
import 'package:dorm/dorm.dart' show Entity;

import 'package:ng2_state/ng2_state.dart' show StatefulComponent, SerializableTuple1, StatePhase, StateService;

import 'package:ng2_form_components/src/components/internal/form_component.dart' show FormComponent;
import 'package:ng2_form_components/src/components/helpers/html_text_transformation.dart' show HTMLTextTransformation;
import 'package:ng2_form_components/src/components/helpers/html_transform.dart' show HTMLTransform;

import 'package:ng2_form_components/src/components/html_text_transform_menu.dart' show HTMLTextTransformMenu;

import 'package:ng2_form_components/src/utils/mutation_observer_stream.dart' show MutationObserverStream;

typedef Range RangeModifier(Range range);
typedef String ContentInterceptor(String value);

@Component(
    selector: 'html-text-transform-component',
    templateUrl: 'html_text_transform_component.html',
    styles: const <String>['''
    :host {
      width: 100%
    }
    '''],
    providers: const <dynamic>[StateService, DOCUMENT, const Provider(StatefulComponent, useExisting: HTMLTextTransformComponent)],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false
)
class HTMLTextTransformComponent extends FormComponent<Comparable<dynamic>> implements StatefulComponent, OnDestroy, OnInit, AfterViewInit {

  final ElementRef element;
  final HTMLTransform transformer = new HTMLTransform();

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
  @Output() Stream<bool> get transformationSuccess => _transformationSuccess$ctrl.stream;

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
  StreamSubscription<ClipboardEvent> _pasteSubscription;
  StreamSubscription<Range> _activeRangeSubscription;
  StreamSubscription<String> _contentSubscription;
  StreamSubscription<String> _mutationObserverSubscription;

  final StreamController<Range> _activeRange$ctrl = new StreamController<Range>.broadcast();
  final StreamController<HTMLTextTransformation> _transformation$ctrl = new StreamController<HTMLTextTransformation>.broadcast();
  final StreamController<String> _modelTransformation$ctrl = new StreamController<String>.broadcast();
  final StreamController<bool> _hasSelectedRange$ctrl = new StreamController<bool>();
  final StreamController<bool> _rangeTrigger$ctrl = new StreamController<bool>();
  final StreamController<bool> _blurTrigger$ctrl = new StreamController<bool>();
  final StreamController<bool> _focusTrigger$ctrl = new StreamController<bool>();
  final StreamController<Range> _rangeToString$ctrl = new StreamController<Range>();
  final StreamController<String> _content$ctrl = new StreamController<String>.broadcast();
  final StreamController<bool> _interceptorChanged$ctrl = new StreamController<bool>();
  final StreamController<bool> _transformationSuccess$ctrl = new StreamController<bool>.broadcast();

  //-----------------------------
  // Constructor
  //-----------------------------

  HTMLTextTransformComponent(
    @Inject(ElementRef) ElementRef elementRef) :
      this.element = elementRef,
      super(elementRef) {
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

  @override void ngOnInit() {
    _updateInnerHtmlTrusted(model, false);

    _initStreams();
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();

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

  Future<Null> _handleKeyDown(KeyboardEvent event) async {
    if (event.keyCode == 10 || event.keyCode == 13) {
      event.preventDefault();

      Selection selection = window.getSelection();

      if (selection != null) {
        final Range range = selection.getRangeAt(0);

        if (_isInsideList(range)) {
          final Element liElement = new LIElement();

          _expandRange(range, until: (Node node) => _isHtmlList(node) && node != contentElement.nativeElement);

          range.collapse(false);

          range
            ..insertNode(liElement);

          range.setStart(liElement, 0);
          range.setEnd(liElement, 0);
        } else {
          final Element breakElement = new Element.br();
          final Text text = new Text('\u00A0');

          range
            ..insertNode(text)
            ..insertNode(breakElement);

          range.setStart(text, 0);
          range.setEnd(text, 0);
        }

        selection.removeAllRanges();
        selection.addRange(range);
      }
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

    _contentSubscription = rx.Observable.combineLatest2(
      rx.observable(_content$ctrl.stream)
        .startWith(model)
        .distinct(),
      rx.observable(_interceptorChanged$ctrl.stream)
        .startWith(false)
    , (String newContent, _) => newContent)
      .listen((String newContent) => _setInnerHtml(newContent));

    _range$ = new rx.Observable<dynamic>.merge(<Stream<dynamic>>[
      element.onMouseDown,
      rx.observable(element.onMouseDown)
        .flatMapLatest((_) => document.onMouseUp.take(1)),
      element.onKeyDown,
      rx.observable(element.onKeyDown)
        .flatMapLatest((_) => document.onKeyUp.take(1)),
      rx.observable(_rangeTrigger$ctrl.stream),
    ])
      .asBroadcastStream()
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

    _pasteSubscription = rx.observable(element.onPaste)
      .listen((ClipboardEvent event) {
        final String dataRaw = event.clipboardData.getData('text/plain');
        final String content = const HtmlEscape().convert(dataRaw)
            .replaceAll(new RegExp(r'[\r]'), '<BR>')
            .replaceAll(new RegExp(r'[\n]'), '');

        event.preventDefault();

        document.execCommand('insertHTML', false, content);
      });

    _range$subscription = _rangeTransform$
      .flatMapLatest((Tuple2<Range, HTMLTextTransformation> tuple) => new Stream<HTMLTextTransformation>.fromFuture(tuple.item2.setup())
        .map((HTMLTextTransformation transformation) {
          transformation?.owner = tuple.item2;
          transformation?.doRemoveTag = tuple.item2?.doRemoveTag;

          return new Tuple2<Range, HTMLTextTransformation>(tuple.item1, transformation);
        }))
      .listen((Tuple2<Range, HTMLTextTransformation> tuple) {
        if (tuple.item2 != null) {
          _transformContent(tuple);
        } else {
          final String contentWithoutPlaceholder = element.innerHtml
              .replaceAllMapped(new RegExp(r'<mark[\s]+start(|="")><\/mark>'), (Match match) => '')
              .replaceAll(new RegExp(r'<mark[\s]+end(|="")><\/mark>'), '');

          element.setInnerHtml(contentWithoutPlaceholder, treeSanitizer: NodeTreeSanitizer.trusted);

          _updateInnerHtmlTrusted(contentWithoutPlaceholder);

          _rangeTrigger$ctrl.add(true);
        }
      });

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
      .listen(null);


  }

  @override void ngAfterViewInit() {
    final Element element = _contentElement.nativeElement as Element;

    _mutationObserverSubscription = rx.observable(new MutationObserverStream(element))
        .skip(1)
        .where((_) => !_modelTransformation$ctrl.isClosed)
        .debounce(const Duration(milliseconds: 80))
        .map((_) => element.innerHtml)
        .where((String value) => model == null || value != model)
        .listen((String content) {
          model = content;

          _content$ctrl.add(content);

          _modelTransformation$ctrl.add(content);
        });
  }

  Range _extractSelectionToString(Range forRange) {
    _rangeToString$ctrl.add(forRange);

    return forRange;
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
      case 'h1':
      case 'h2':
      case 'h3':
        _removeTagsInRange(tuple.item1, const <String>['h1', 'h2', 'h3']); break;
      case 'clear':
        _removeTagsInRange(tuple.item1, const <String>['h1', 'h2', 'h3']);

        _execDocumentCommand('removeFormat'); return;
      case 'undo':
        _execDocumentCommand('undo'); return;
      case 'redo':
        _execDocumentCommand('redo'); return;
    }

    final Element customElement = _createCustomNode(tuple.item2);

    final Range range = (tuple.item2.shouldExpand) ? _expandRange(tuple.item1) : tuple.item1;

    try {
      range.surroundContents(customElement);
    } catch (error) {
      if (!tuple.item2.shouldExpand) _transformationSuccess$ctrl.add(false);
      else {
        final DocumentFragment fragment = tuple.item1.extractContents();

        customElement.append(fragment);

        tuple.item1.collapse(true);

        window.getSelection()
          ..removeAllRanges()
          ..addRange(tuple.item1);

        tuple.item1.insertNode(customElement);

        final List<Element> allListElements = new List<Element>()
          ..addAll(querySelectorAll('span'))
          ..addAll(querySelectorAll('li'))
          ..addAll(querySelectorAll('ol'))
          ..addAll(querySelectorAll('ul'));

        allListElements
            .where(_isEmptyElement)
            .forEach((Element element) => element.replaceWith(new DocumentFragment.html('')));

        allListElements
            .where(_containsPilcrowOnly)
            .forEach((Element element) => element.replaceWith(element.firstChild));
      }
    }

    _rangeTrigger$ctrl.add(true);
  }

  Range _expandRange(Range range, {bool until(Node node)}) {
    String selectedText;
    Range clonedRange;
    DocumentFragment fragment;

    until ??= (Node node) {
      print('"${node.text}" - "$selectedText"');
      return node == contentElement.nativeElement || _isHtmlList(node) || !_textMatches(node.text, selectedText);
    };

    List<Node> ancestorNodes = <Node>[range.startContainer, range.endContainer];
    Node targetNode;
    int index = 0;

    ancestorNodes.forEach((Node ancestorNode) {
      clonedRange = new Range()
        ..selectNodeContents(ancestorNode);

      if (index == 0) {
        clonedRange.setStart(ancestorNode, range.startOffset);
      } else {
        clonedRange.setEnd(ancestorNode, range.endOffset);
      }

      targetNode = null;
      fragment = clonedRange.cloneContents();
      selectedText = fragment.text
          .replaceAll('¶', '');

      while(ancestorNode != null && !until(ancestorNode)) {
        targetNode = ancestorNode;
        ancestorNode = ancestorNode.parentNode;
      }

      if (targetNode != null) {
        clonedRange = range.cloneRange();

        if (index == 0) {
          clonedRange.setStartBefore(targetNode);
        } else {
          clonedRange.setEndAfter(targetNode);
        }

        range = clonedRange;
      }

      index++;
    });

    window.getSelection()
      ..removeAllRanges()
      ..addRange(range);

    return range;
  }

  bool _textMatches(String left, String right) {
    final String nLeft = left
        .replaceAll('¶', '')
        .trim();

    final String nRight = right
        .replaceAll('¶', '')
        .trim();

    return nLeft.compareTo(nRight) == 0;
  }

  bool _isInsideList(Range range) {
    Node ancestorNode = range.commonAncestorContainer;

    while (ancestorNode != contentElement.nativeElement) {
      String nodeName = ancestorNode.nodeName.toLowerCase();

      if (nodeName.compareTo('li') == 0) return true;

      ancestorNode = ancestorNode.parentNode;
    }

    return false;
  }

  bool _isHtmlList(Node element) => (
    element is OListElement ||
    element is UListElement
  );

  void _removeTagsInRange(Range range, List<String> affectedNodes) {
    _expandRange(range);

    final DocumentFragment fragment = range.cloneContents();
    String selectedText = fragment.innerHtml;print(selectedText);

    affectedNodes
      .forEach((String nodeName) {
        final RegExp openingTagRegExp = new RegExp('<$nodeName[^>]*>');

        final Iterable<Match> openingTagMatches = openingTagRegExp.allMatches(selectedText);

        if (nodeName.compareTo('br') == 0) {
          selectedText = selectedText.replaceAllMapped(openingTagRegExp, ((_) => ''));
        } else {
          final RegExp closingTagRegExp = new RegExp('</$nodeName[^>]*>');
          final Iterable<Match> closingTagMatches = closingTagRegExp.allMatches(selectedText);

          if (openingTagMatches.length == closingTagMatches.length) {
            selectedText = selectedText.replaceAllMapped(openingTagRegExp, ((_) => ''));
            selectedText = selectedText.replaceAllMapped(closingTagRegExp, ((_) => ''));
          }
        }
      });

    final DocumentFragment textFragment = new DocumentFragment.html(selectedText, treeSanitizer: NodeTreeSanitizer.trusted);

    range.deleteContents();
    range.insertNode(textFragment);

    window.getSelection()
      ..removeAllRanges()
      ..addRange(range);
  }

  bool _isEmptyElement(Element element) => element.text.trim().isEmpty;

  bool _containsPilcrowOnly(Element element) => element.children.length == 1 && element.firstChild.nodeName.toLowerCase().compareTo('figure') == 0;

  void _execDocumentCommand(String command, [bool showUI = null, String value = null]) {
    document.execCommand(command, showUI, value);

    _rangeTrigger$ctrl.add(true);
  }

  String _generateUid() {
    final StringBuffer buffer = new StringBuffer();
    final Random rnd = new Random();

    buffer.write(rnd.nextInt(0xfffffff).toRadixString(16));
    buffer.write('-');
    buffer.write(rnd.nextInt(0xffff).toRadixString(16));
    buffer.write('-');
    buffer.write(rnd.nextInt(0xffff).toRadixString(16));
    buffer.write('-');
    buffer.write(rnd.nextInt(0xffff).toRadixString(16));
    buffer.write('-');
    buffer.write(rnd.nextInt(0xffffffff).toRadixString(16));
    buffer.write(rnd.nextInt(0xffff).toRadixString(16));

    return buffer.toString();
  }

  Element _createCustomNode(HTMLTextTransformation transformation) {
    final Element element = new Element.tag(transformation.tag);

    element.attributes['uid'] = _generateUid();

    if (transformation.id != null) element.attributes['id'] = transformation.id;
    if (transformation.className != null) element.className = transformation.className;

    if (transformation.style != null) {
      transformation.style.forEach((String K, String V) => element.style.setProperty(K, V));
    }

    if (transformation.attributes != null) {
      transformation.attributes.forEach((String K, String V) {
        if (V == null || V.toLowerCase() == 'true') element.attributes[K] = '';
        else element.attributes[K] = V;
      });
    }

    return element;
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

      if (isChanged) deliverStateChanges();
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

              break;
            }

            currentNode = currentNode.parentNode;
          }
        }
      });

      deliverStateChanges();

      menu.deliverStateChanges();
    }

    return range;
  }

  void handleFocus() => _focusTrigger$ctrl.add(true);

  void handleBlur() => _blurTrigger$ctrl.add(true);
}