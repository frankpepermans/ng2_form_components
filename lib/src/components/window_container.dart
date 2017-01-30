import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:ng2_form_components/ng2_form_components.dart' show WindowListeners;
import 'package:ng2_state/ng2_state.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:dorm/dorm.dart';

@Component(
    selector: 'window-container',
    templateUrl: 'window_container.html',
    styleUrls: const <String>['window_container.css'],
    providers: const <dynamic>[const Provider(StatefulComponent, useExisting: WindowContainer)],
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false
)
class WindowContainer extends ComponentState implements StatefulComponent, OnDestroy, AfterViewInit {

  @ViewChild('header') ElementRef headerRef;

  final ElementRef elementRef;
  final WindowListeners windowListeners = new WindowListeners();

  String _headerText;
  String get headerText => _headerText;
  @Input() set headerText(String value) {
    if (value != _headerText) setState(() => _headerText = value);
  }

  @Output() Stream<bool> get close => _close$ctrl.stream;

  final StreamController<bool> _close$ctrl = new StreamController<bool>.broadcast();
  final StreamController<bool> _onDestroy$ctrl = new StreamController<bool>.broadcast();
  final StreamController<_DragPosition> _dragPosition$ctrl = new rx.BehaviourSubject<_DragPosition>.broadcast();

  StreamSubscription<_DragPosition> _dragSubscription, _dragCommitSubscription;

  @override Stream<bool> get onDestroy => _onDestroy$ctrl.stream;

  @override String stateGroup, stateId;

  WindowContainer(
      @Inject(ElementRef) this.elementRef);

  @override Stream<Entity> provideState() => _dragPosition$ctrl.stream
      .distinct((_DragPosition dA, _DragPosition dB) => dA.left == dB.left && dA.top == dB.top)
      .map((_DragPosition value) => new SerializableTuple2<num, num>()
    ..item1 = value.left
    ..item2 = value.top);

  @override void receiveState(Entity state, StatePhase phase) {
    final SerializableTuple2<num, num> tuple = state as SerializableTuple2<num, num>;

    _dragPosition$ctrl.add(new _DragPosition(tuple.item1, tuple.item2));
  }

  @override void ngOnDestroy() {
    _onDestroy$ctrl.add(true);

    _close$ctrl.close();
    _onDestroy$ctrl.close();
    _dragPosition$ctrl.close();

    _dragSubscription?.cancel();
    _dragCommitSubscription?.cancel();
  }

  @override void ngAfterViewInit() {
    final Element element = elementRef.nativeElement;
    final DivElement header = headerRef.nativeElement;

    _dragSubscription = rx.observable(header.onMouseDown)
        .map((MouseEvent event) {
          event.preventDefault();

          return <String, int>{ 'left': event.client.x - element.offset.left, 'top': event.client.y - element.offset.top };
        })
        .flatMapLatest((Map<String, int> event) => rx.observable(document.body.onMouseMove)
        .map((MouseEvent pos) => new _DragPosition(pos.client.x - event['left'], pos.client.y - event['top']))
        .takeUntil(document.body.onMouseUp))
        .listen(_dragPosition$ctrl.add);

    _dragCommitSubscription = new rx.Observable<_DragPosition>.merge(<Stream<_DragPosition>>[
      _dragPosition$ctrl.stream,
      rx.observable(windowListeners.windowResize).flatMapLatest((_) => _dragPosition$ctrl.stream)
    ]).listen((_DragPosition position) {
      final num lMax = window.document.documentElement.clientWidth - element.clientWidth;
      final num tMax = window.document.documentElement.clientHeight - element.clientHeight;

      num left = position.left < 0 ? 0 : position.left > lMax ? lMax : position.left;
      num top = position.top < 0 ? 0 : position.top > tMax ? tMax : position.top;

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