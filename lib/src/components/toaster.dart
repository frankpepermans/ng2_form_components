library ng2_form_components.components.toaster;

import 'dart:async';
import 'dart:html';
import 'dart:collection';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:angular2/angular2.dart';
import 'package:dorm/dorm.dart' show Entity;

import 'package:ng2_state/ng2_state.dart' show StatefulComponent, SerializableTuple1, StatePhase, StateService;

import 'package:ng2_form_components/ng2_form_components.dart' show FormComponent;
import 'package:ng2_form_components/src/components/helpers/html_text_transformation.dart' show HTMLTextTransformation;
import 'package:ng2_form_components/src/components/helpers/html_transform.dart' show HTMLTransform;

import 'package:ng2_form_components/src/components/html_text_transform_menu.dart';

import 'package:ng2_form_components/src/components/animation/tween.dart';

enum ToastMessageType {
  INFO,
  WARNING,
  ERROR
}

@Component(
    selector: 'toaster',
    templateUrl: 'toaster.html',
    directives: const <Type>[Tween],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class Toaster implements OnDestroy {

  @Input() int messageDuration = 5000;

  final ChangeDetectorRef changeDetector;

  final StreamController<_ToastMessage> _toastMessage$ctrl = new StreamController<_ToastMessage>();

  final Queue<_ToastMessage> messageQueue = new Queue<_ToastMessage>();

  StreamSubscription<_ToastMessage> _toastMessageSubscription;

  Toaster(
    @Inject(ChangeDetectorRef) this.changeDetector) {
      _initStreams();
    }

  @override void ngOnDestroy() {
    _toastMessageSubscription?.cancel();
  }

  void addMessage(String message, {ToastMessageType type: ToastMessageType.INFO}) => _toastMessage$ctrl.add(new _ToastMessage(message, type, new Duration(milliseconds: messageDuration)));

  void _initStreams() {
    _toastMessageSubscription = rx.observable(_toastMessage$ctrl.stream)
      .flatMap((_ToastMessage message) => new Stream<num>.fromFuture(window.animationFrame)
        .map((_) => message))
      .flatMap((_ToastMessage message) => message.appear)
      .tap(messageQueue.add)
      .tap((_) => changeDetector.markForCheck())
      .flatMap((_ToastMessage message) => message.disappear)
      .tap(messageQueue.remove)
      .listen((_) => changeDetector.markForCheck());
  }

  String getBottomOffset(int index) => '${64 * index}px';
}

class _ToastMessage {

  final StreamController<_ToastMessage> _appear$ctrl = new StreamController<_ToastMessage>();
  final StreamController<_ToastMessage> _disappear$ctrl = new StreamController<_ToastMessage>();

  Stream<_ToastMessage> get appear => _appear$ctrl.stream;
  Stream<_ToastMessage> get disappear => _disappear$ctrl.stream;

  final String message;
  final ToastMessageType type;
  final Duration duration;

  _ToastMessage(this.message, this.type, this.duration) {
    _appear$ctrl.add(this);

    new Timer(duration, () => _disappear$ctrl.add(this));
  }

}