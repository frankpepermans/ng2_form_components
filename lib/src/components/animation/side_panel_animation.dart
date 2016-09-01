library ng2_form_components.components.animation.side_panel_animation;

import 'dart:async';

import 'package:angular2/angular2.dart';
import 'package:angular2/animate.dart';

import 'package:ng2_form_components/src/components/animation/tween.dart';

@Directive(
    selector: '[panel-tween]'
)
class SidePanelAnimation extends Tween implements OnInit {

  @override @Input() set duration(int value) {
    super.duration = value;
  }

  @override @Input() set tweenStyleProperty(String value) {
    super.tweenStyleProperty = value;
  }

  @override @Input() set beforeDestroyChildTrigger(StreamController<dynamic> value) {
    super.beforeDestroyChildTrigger = value as StreamController<bool>;
  }

  SidePanelAnimation(
      @Inject(AnimationBuilder) AnimationBuilder animationBuilder,
      @Inject(ElementRef) ElementRef element) : super(animationBuilder, element) {
    tweenStyleProperty = 'width';
  }

  @override void tweenOpen() {
    cssAnimationBuilder.setDuration(duration);

    cssAnimationBuilder.setFromStyles(<String, dynamic>{
      tweenStyleProperty: '0',
      'visibility': 'visible'
    });

    cssAnimationBuilder.setToStyles(<String, dynamic>{
      tweenStyleProperty: '${nativeElement.clientWidth}px'
    });

    cssAnimationBuilder.start(nativeElement)
      ..onComplete(() {
        nativeElement.style.removeProperty(tweenStyleProperty);
        nativeElement.style.removeProperty('visibility');
      });
  }

  @override void tweenClose(_) {
    cssAnimationBuilder.setDuration(duration);

    cssAnimationBuilder.setFromStyles(<String, dynamic>{
      tweenStyleProperty: '${nativeElement.clientWidth}px'
    });

    cssAnimationBuilder.setToStyles(<String, dynamic>{
      tweenStyleProperty: '0'
    });

    cssAnimationBuilder.start(nativeElement)
      ..onComplete(() {
        nativeElement.style.removeProperty(tweenStyleProperty);

        beforeDestroyChildTrigger.add(true);
      });
  }

}