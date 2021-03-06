library ng2_form_components.components.animation.side_panel_animation;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/animation/tween.dart';

@Directive(selector: '[panel-tween]')
class SidePanelAnimation extends Tween implements OnInit {
  @override
  @Input()
  set beforeDestroyChildTrigger(StreamController<dynamic> value) {
    super.beforeDestroyChildTrigger = value as StreamController<bool>;
  }

  SidePanelAnimation(@Inject(Element) Element element) : super(element) {
    tweenStyleProperty = 'width';
  }

  @override
  void tweenOpen() {
    nativeElement.style.setProperty(tweenStyleProperty, '0');
    nativeElement.style.visibility = 'visible';
    nativeElement.style.transition =
        '$tweenStyleProperty ${duration / 1000}s ease-out';

    animationFrame$().take(1).listen((_) {
      nativeElement.style
          .setProperty(tweenStyleProperty, '${nativeElement.clientWidth}px');

      Timer(Duration(milliseconds: duration), () {
        nativeElement.style.removeProperty(tweenStyleProperty);
        nativeElement.style.removeProperty('visibility');
      });
    });
  }

  @override
  void tweenClose(dynamic _) {
    nativeElement.style
        .setProperty(tweenStyleProperty, '${nativeElement.clientWidth}px');
    nativeElement.style.visibility = 'visible';
    nativeElement.style.transition =
        '$tweenStyleProperty ${duration / 1000}s ease-out';

    animationFrame$().take(1).listen((_) {
      nativeElement.style.setProperty(tweenStyleProperty, '0');

      Timer(Duration(milliseconds: duration), () {
        nativeElement.style.removeProperty(tweenStyleProperty);

        beforeDestroyChildTrigger.add(true);
      });
    });
  }
}
