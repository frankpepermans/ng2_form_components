library ng2_form_components.components.animation.tween;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';

@Directive(selector: '[tween]')
class Tween implements OnInit, OnDestroy {
  int _duration = 300;
  int get duration => _duration;
  @Input()
  set duration(int value) {
    _duration = value;
  }

  String _tweenStyleProperty = 'top';
  String get tweenStyleProperty => _tweenStyleProperty;
  @Input()
  set tweenStyleProperty(String value) {
    _tweenStyleProperty = value;
  }

  StreamController<dynamic> _beforeDestroyChildTrigger;
  StreamController<dynamic> get beforeDestroyChildTrigger =>
      _beforeDestroyChildTrigger;
  @Input()
  set beforeDestroyChildTrigger(StreamController<dynamic> value) {
    _beforeDestroyChildTrigger = value;
  }

  int _startValue = -1;
  int get startValue => _startValue;
  @Input()
  set startValue(int value) {
    _startValue = value;
  }

  int _endValue = -1;
  int get endValue => _endValue;
  @Input()
  set endValue(int value) {
    _endValue = value;
  }

  bool _hasCloseAnimation = true;
  bool get hasCloseAnimation => _hasCloseAnimation;
  @Input()
  set hasCloseAnimation(bool value) {
    _hasCloseAnimation = value;
  }

  final Element element;

  Timer _openTimer;
  Element nativeElement;

  StreamSubscription<dynamic> _beforeDestroyChildTriggerSubscription;

  Tween(@Inject(Element) this.element) {
    nativeElement = element;
  }

  @override
  void ngOnInit() {
    nativeElement.style.visibility = 'hidden';

    window.animationFrame.whenComplete(tweenOpen);

    if (hasCloseAnimation && beforeDestroyChildTrigger != null)
      _beforeDestroyChildTriggerSubscription =
          beforeDestroyChildTrigger.stream.take(1).listen(tweenClose);
  }

  @override
  void ngOnDestroy() {
    _beforeDestroyChildTriggerSubscription?.cancel();
  }

  void tweenOpen() {
    final int t0 = startValue == -1 ? -nativeElement.clientHeight : startValue;
    final int t1 = endValue == -1 ? 0 : endValue;

    nativeElement.style.setProperty(tweenStyleProperty, '${t0}px');
    nativeElement.style.visibility = 'visible';
    nativeElement.style.transition =
        '$tweenStyleProperty ${duration / 1000}s ease-out';

    animationFrame$().take(1).listen((_) {
      nativeElement.style.setProperty(tweenStyleProperty, '${t1}px');
    });

    _openTimer?.cancel();

    if (hasCloseAnimation) {
      _openTimer = new Timer(new Duration(milliseconds: duration), () {
        nativeElement.style.removeProperty(tweenStyleProperty);
        nativeElement.style.removeProperty('visibility');
      });
    } else {
      _openTimer = new Timer(new Duration(milliseconds: duration), () {
        nativeElement.style.removeProperty('visibility');
      });
    }
  }

  void tweenClose(dynamic _) {
    final int t0 = startValue == -1 ? 0 : startValue;
    final int t1 = endValue == -1 ? -nativeElement.clientHeight : endValue;

    nativeElement.style.setProperty(tweenStyleProperty, '${t0}px');

    animationFrame$().take(1).listen((_) {
      nativeElement.style.setProperty(tweenStyleProperty, '${t1}px');

      _openTimer?.cancel();

      new Timer(new Duration(milliseconds: duration), () {
        nativeElement.style.removeProperty(tweenStyleProperty);

        if (!beforeDestroyChildTrigger.isClosed)
          beforeDestroyChildTrigger.add(true);
      });
    });
  }

  Stream<num> animationFrame$() async* {
    yield await window.animationFrame;
  }
}
