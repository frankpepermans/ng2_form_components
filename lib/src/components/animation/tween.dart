library ng2_form_components.components.animation.tween;

import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/animate.dart';

@Directive(
    selector: '[tween]'
)
class Tween implements OnInit, OnDestroy {

  int _duration = 600;
  int get duration => _duration;
  @Input() set duration(int value) {
    _duration = value;
  }

  String _tweenStyleProperty = 'top';
  String get tweenStyleProperty => _tweenStyleProperty;
  @Input() set tweenStyleProperty(String value) {
    _tweenStyleProperty = value;
  }

  StreamController<dynamic> _beforeDestroyChildTrigger;
  StreamController<dynamic> get beforeDestroyChildTrigger => _beforeDestroyChildTrigger;
  @Input() set beforeDestroyChildTrigger(StreamController<dynamic> value) {
    _beforeDestroyChildTrigger = value;
  }

  int _startValue = -1;
  int get startValue => _startValue;
  @Input() set startValue(int value) {
    _startValue = value;
  }

  int _endValue = -1;
  int get endValue => _endValue;
  @Input() set endValue(int value) {
    _endValue = value;
  }

  bool _hasCloseAnimation = true;
  bool get hasCloseAnimation => _hasCloseAnimation;
  @Input() set hasCloseAnimation(bool value) {
    _hasCloseAnimation = value;
  }

  final AnimationBuilder animationBuilder;
  final ElementRef element;

  Element nativeElement;
  CssAnimationBuilder cssAnimationBuilder;

  StreamSubscription<dynamic> _beforeDestroyChildTriggerSubscription;

  Tween(@Inject(AnimationBuilder) this.animationBuilder, @Inject(ElementRef) this.element) {
    nativeElement = element.nativeElement as Element;
    cssAnimationBuilder = animationBuilder.css();
  }

  @override void ngOnInit() {
    nativeElement.style.visibility = 'hidden';

    window.animationFrame.whenComplete(tweenOpen);

    if (hasCloseAnimation && beforeDestroyChildTrigger != null) _beforeDestroyChildTriggerSubscription = beforeDestroyChildTrigger.stream.take(1).listen(tweenClose);
  }

  @override void ngOnDestroy() {
    _beforeDestroyChildTriggerSubscription?.cancel();
  }

  void tweenOpen() {
    final int t0 = startValue == -1 ? -nativeElement.clientHeight : startValue;
    final int t1 = endValue == -1 ? 0 : endValue;

    cssAnimationBuilder.setDuration(duration);

    cssAnimationBuilder.setFromStyles(<String, dynamic>{
      tweenStyleProperty: '${t0}px',
      'visibility': 'visible'
    });

    cssAnimationBuilder.setToStyles(<String, dynamic>{
      tweenStyleProperty: '${t1}px'
    });

    if (hasCloseAnimation) {
      cssAnimationBuilder.start(nativeElement)
        ..onComplete(() {
          nativeElement.style.removeProperty(tweenStyleProperty);
          nativeElement.style.removeProperty('visibility');
        });
    } else {
      cssAnimationBuilder.start(nativeElement)
        ..onComplete(() {
          nativeElement.style.removeProperty('visibility');
        });
    }
  }

  void tweenClose(_) {
    final int t0 = startValue == -1 ? 0 : startValue;
    final int t1 = endValue == -1 ? -nativeElement.clientHeight : endValue;

    cssAnimationBuilder.setDuration(duration);

    cssAnimationBuilder.setFromStyles(<String, dynamic>{
      tweenStyleProperty: '${t0}px'
    });

    cssAnimationBuilder.setToStyles(<String, dynamic>{
      tweenStyleProperty: '${t1}px'
    });

    cssAnimationBuilder.start(nativeElement)
      ..onComplete(() {
        nativeElement.style.removeProperty(tweenStyleProperty);

        beforeDestroyChildTrigger.add(true);
      });
  }
}