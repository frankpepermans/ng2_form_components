import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'package:rxdart/rxdart.dart';

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/animation/tween.dart';
import 'package:ng2_form_components/src/utils/html_loader.dart' show HtmlLoader;

enum ToastMessageType { INFO, WARNING, ERROR }

@Component(
    selector: 'toaster',
    templateUrl: 'toaster.html',
    directives: <dynamic>[coreDirectives, Tween, HtmlLoader],
    pipes: <dynamic>[commonPipes],
    changeDetection: ChangeDetectionStrategy.OnPush,
    preserveWhitespace: false)
class Toaster implements OnDestroy {
  @Input()
  int messageDuration = 5000;

  final ChangeDetectorRef changeDetector;

  final StreamController<_ToastMessage> _toastMessage$ctrl =
      StreamController<_ToastMessage>();

  final Queue<_ToastMessage> messageQueue = Queue<_ToastMessage>();

  StreamSubscription<_ToastMessage> _toastMessageSubscription;

  Toaster(@Inject(ChangeDetectorRef) this.changeDetector) {
    _initStreams();
  }

  @override
  void ngOnDestroy() {
    _toastMessageSubscription?.cancel();

    _toastMessage$ctrl.close();
  }

  void addMessage(String message,
          {ToastMessageType type = ToastMessageType.INFO}) =>
      _toastMessage$ctrl.add(_ToastMessage(
          message, type, Duration(milliseconds: messageDuration)));

  void _initStreams() {
    _toastMessageSubscription = Observable(_toastMessage$ctrl.stream)
        .flatMap((message) =>
            Stream.fromFuture(window.animationFrame).map((_) => message))
        .flatMap((message) => message.appear)
        .doOnData(messageQueue.add)
        .doOnData((_) => changeDetector.markForCheck())
        .flatMap((message) => message.disappear)
        .doOnData(messageQueue.remove)
        .doOnData((message) => message.close())
        .listen((_) => changeDetector.markForCheck());
  }

  Map<String, bool> getToastCssMap(_ToastMessage message) {
    switch (message.type) {
      case ToastMessageType.INFO:
        return <String, bool>{'toast--info': true};
      case ToastMessageType.WARNING:
        return <String, bool>{'toast--warning': true};
      case ToastMessageType.ERROR:
        return <String, bool>{'toast--error': true};
    }

    return const <String, bool>{};
  }

  String tracker(int index, dynamic message) =>
      (message as _ToastMessage).message;

  String getBottomOffset(int index) => '${64 * index}px';
}

class _ToastMessage {
  final StreamController<_ToastMessage> _appear$ctrl =
      StreamController<_ToastMessage>();
  final StreamController<_ToastMessage> _disappear$ctrl =
      StreamController<_ToastMessage>();

  Stream<_ToastMessage> get appear => _appear$ctrl.stream;
  Stream<_ToastMessage> get disappear => _disappear$ctrl.stream;

  final String message;
  final ToastMessageType type;
  final Duration duration;

  _ToastMessage(this.message, this.type, this.duration) {
    _appear$ctrl.add(this);

    Timer(duration, () => _disappear$ctrl.add(this));
  }

  void close() {
    _appear$ctrl.close();
    _disappear$ctrl.close();
  }
}
