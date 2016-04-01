library ng2_form_components.components.animation.tween;

import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/animate.dart';

@Directive(
    selector: '[tween]'
)
class Tween implements OnInit {

  int _duration = 600;
  int get duration => _duration;
  @Input() void set duration(int value) {
    _duration = value;
  }

  String _style = 'top';
  String get style => _style;
  @Input() void set style(String value) {
    _style = value;
  }

  StreamController _beforeDestroyChildTrigger;
  StreamController get beforeDestroyChildTrigger => _beforeDestroyChildTrigger;
  @Input() void set beforeDestroyChildTrigger(StreamController value) {
    _beforeDestroyChildTrigger = value;
  }

  final AnimationBuilder animationBuilder;
  final ElementRef element;

  Element nativeElement;
  CssAnimationBuilder cssAnimationBuilder;

  Tween(@Inject(AnimationBuilder) this.animationBuilder, @Inject(ElementRef) this.element) {
    nativeElement = element.nativeElement as Element;
    cssAnimationBuilder = animationBuilder.css();
  }

  @override void ngOnInit() {
    nativeElement.style.visibility = 'hidden';

    window.animationFrame.whenComplete(tweenOpen);

    if (beforeDestroyChildTrigger != null) beforeDestroyChildTrigger.stream.take(1).listen(tweenClose);
  }

  void tweenOpen() {
    cssAnimationBuilder.setDuration(duration);

    cssAnimationBuilder.setFromStyles(<String, dynamic>{
      style: '-${nativeElement.clientHeight}px',
      'visibility': 'visible'
    });

    cssAnimationBuilder.setToStyles(<String, dynamic>{
      style: '0'
    });

    cssAnimationBuilder.start(nativeElement)
      ..onComplete(() {
        nativeElement.style.removeProperty(style);
        nativeElement.style.removeProperty('visibility');
      });
  }

  void tweenClose(_) {
    cssAnimationBuilder.setDuration(duration);

    cssAnimationBuilder.setFromStyles(<String, dynamic>{
      style: '0'
    });

    cssAnimationBuilder.setToStyles(<String, dynamic>{
      style: '-${nativeElement.clientHeight}px'
    });

    cssAnimationBuilder.start(nativeElement)
      ..onComplete(() {
        nativeElement.style.removeProperty(style);

        beforeDestroyChildTrigger.add(true);
      });
  }
}