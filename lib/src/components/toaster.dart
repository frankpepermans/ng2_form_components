library ng2_form_components.components.toaster;

import 'dart:async';
import 'dart:html';
import 'dart:collection';

import 'package:rxdart/rxdart.dart' as rx;

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/animation/tween.dart';
import 'package:ng2_form_components/src/utils/html_loader.dart' show HtmlLoader;

enum ToastMessageType {
  INFO,
  WARNING,
  ERROR
}

@Component(
    selector: 'toaster',
    templateUrl: 'toaster.html',
    directives: const <dynamic>[coreDirectives, Tween, HtmlLoader],
    pipes: const <dynamic>[commonPipes],
    changeDetection: ChangeDetectionStrategy.OnPush,
    preserveWhitespace: false
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

    _toastMessage$ctrl.close();
  }

  void addMessage(String message, {ToastMessageType type: ToastMessageType.INFO}) => _toastMessage$ctrl.add(new _ToastMessage(message, type, new Duration(milliseconds: messageDuration)));

  void _initStreams() {
    _toastMessageSubscription = new rx.Observable<_ToastMessage>(_toastMessage$ctrl.stream)
      .flatMap((_ToastMessage message) => new Stream<num>.fromFuture(window.animationFrame)
        .map((_) => message))
      .flatMap((_ToastMessage message) => message.appear)
      .doOnData(messageQueue.add)
      .doOnData((_) => changeDetector.markForCheck())
      .flatMap((_ToastMessage message) => message.disappear)
      .doOnData(messageQueue.remove)
      .doOnData((_ToastMessage message) => message.close())
      .listen((_) => changeDetector.markForCheck());
  }

  Map<String, bool> getToastCssMap(_ToastMessage message) {
    switch (message.type) {
      case ToastMessageType.INFO: return <String, bool>{'toast--info': true};
      case ToastMessageType.WARNING: return <String, bool>{'toast--warning': true};
      case ToastMessageType.ERROR: return <String, bool>{'toast--error': true};
    }

    return const <String, bool>{};
  }

  String tracker(int index, dynamic message) => (message as _ToastMessage).message;

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

  void close() {
    _appear$ctrl.close();
    _disappear$ctrl.close();
  }

}