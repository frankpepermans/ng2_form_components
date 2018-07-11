import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:ng2_form_components/ng2_form_components.dart'
    show WindowListeners;
import 'package:ng2_state/ng2_state.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:dorm/dorm.dart';

import 'package:ng2_form_components/src/components/internal/form_component.dart';

@Component(
    selector: 'window-container',
    templateUrl: 'window_container.html',
    styles: const <String>[
      '''
    :host {
        position: absolute;
        display: flex;
        flex-direction: column;
        width: 400px;
        height: 500px;
        left: 20px;
        top: 20px;
        border: 1px solid #333;
        background: #fff;
    }'''
    ],
    providers: const <Provider>[
      const ExistingProvider.forToken(const OpaqueToken('statefulComponent'), WindowContainer)
    ],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false)
class WindowContainer<T extends Comparable<dynamic>> extends FormComponent<T>
    implements StatefulComponent, OnDestroy, AfterViewInit {
  @ViewChild('header')
  Element headerRef;

  final WindowListeners windowListeners = new WindowListeners();

  String _headerText;
  String get headerText => _headerText;
  @Input()
  set headerText(String value) {
    if (value != _headerText) setState(() => _headerText = value);
  }

  @Output()
  Stream<bool> get close => _close$ctrl.stream;

  final StreamController<bool> _close$ctrl =
      new StreamController<bool>.broadcast();
  final StreamController<_DragPosition> _dragPosition$ctrl =
      new rx.BehaviorSubject<_DragPosition>();

  StreamSubscription<_DragPosition> _dragSubscription, _dragCommitSubscription;

  WindowContainer(@Inject(Element) Element elementRef)
      : super(elementRef);

  @override
  Stream<Entity> provideState() => _dragPosition$ctrl.stream
      .distinct((_DragPosition dA, _DragPosition dB) =>
          dA.left == dB.left && dA.top == dB.top)
      .map((_DragPosition value) => new SerializableTuple2<num, num>()
        ..item1 = value.left
        ..item2 = value.top);

  @override
  void receiveState(SerializableTuple2<num, num> state, StatePhase phase) =>
      _dragPosition$ctrl.add(new _DragPosition(state.item1, state.item2));

  @override
  void ngOnDestroy() {
    super.ngOnDestroy();

    _close$ctrl.close();
    _dragPosition$ctrl.close();

    _dragSubscription?.cancel();
    _dragCommitSubscription?.cancel();
  }

  @override
  void ngAfterViewInit() {
    final Element element = elementRef;
    final DivElement header = headerRef as DivElement;

    _dragSubscription = new rx.Observable<MouseEvent>(header.onMouseDown)
        .map((MouseEvent event) {
          event.preventDefault();

          return <String, int>{
            'left': event.client.x.toInt() - element.offset.left.toInt(),
            'top': event.client.y.toInt() - element.offset.top.toInt()
          };
        })
        .switchMap((Map<String, int> event) =>
            new rx.Observable<MouseEvent>(document.body.onMouseMove)
                .map((MouseEvent pos) => new _DragPosition(
                    pos.client.x - event['left'], pos.client.y - event['top']))
                .takeUntil(document.body.onMouseUp))
        .listen(_dragPosition$ctrl.add);

    _dragCommitSubscription =
        new rx.Observable<_DragPosition>.merge(<Stream<_DragPosition>>[
      _dragPosition$ctrl.stream,
      new rx.Observable<bool>(windowListeners.windowResize)
          .switchMap((_) => _dragPosition$ctrl.stream)
    ]).listen((_DragPosition position) {
      final num lMax =
          window.document.documentElement.clientWidth - element.clientWidth;
      final num tMax =
          window.document.documentElement.clientHeight - element.clientHeight;

      num left =
          position.left < 0 ? 0 : position.left > lMax ? lMax : position.left;
      num top =
          position.top < 0 ? 0 : position.top > tMax ? tMax : position.top;

      element.style.top = '${top}px';
      element.style.left = '${left}px';
    });
  }

  void handleClose() => _close$ctrl.add(true);
}

class _DragPosition {
  final num left, top;

  const _DragPosition(this.left, this.top);
}
