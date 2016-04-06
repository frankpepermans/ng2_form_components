library ng2_form_components.components.animation.hierarchy_animation;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;

import 'package:angular2/angular2.dart';
import 'package:angular2/animate.dart';

import 'package:ng2_form_components/src/components/animation/tween.dart';

@Directive(
    selector: '[hierarchy-tween]'
)
class HierarchyAnimation extends Tween implements OnInit {

  static final Map<String, bool> _hasOpenedRegistry = <String, bool>{};

  @override @Input() void set duration(int value) {
    super.duration = value;
  }

  @override @Input() void set style(String value) {
    super.style = value;
  }

  @override @Input() void set beforeDestroyChildTrigger(StreamController value) {
    super.beforeDestroyChildTrigger = value as StreamController<int>;
  }

  int _index;
  int get index => _index;
  @Input() void set index(int value) {
    _index = value;
  }

  int _level;
  int get level => _level;
  @Input() void set level(int value) {
    _level = value;
  }

  bool _forceAnimateOnOpen = false;
  bool get forceAnimateOnOpen => _forceAnimateOnOpen;
  @Input() void set forceAnimateOnOpen(bool value) {
    _forceAnimateOnOpen = value;
  }

  static List<HierarchyAnimation> animations = <HierarchyAnimation>[];

  final StreamController<num> _animation$ctrl = new StreamController<num>.broadcast();

  bool _animationBegan = false;

  HierarchyAnimation(
      @Inject(AnimationBuilder) AnimationBuilder animationBuilder,
      @Inject(ElementRef) ElementRef element) : super(animationBuilder, element);

  @override void ngOnInit() {
    if (forceAnimateOnOpen || _hasOpenedRegistry.containsKey('${index}_${level}')) {
      nativeElement.style.visibility = 'hidden';
      nativeElement.style.position = 'absolute';

      window.animationFrame.whenComplete(tweenOpen);

      animations.add(this);

      _nextAnimationFrame();
    } else {
      _hasOpenedRegistry['${index}_${level}'] = true;
    }

    if (beforeDestroyChildTrigger != null) beforeDestroyChildTrigger.stream
      .where((int index) => index == this.index)
      .take(1)
      .listen(tweenClose);
  }

  @override void tweenOpen() {
    rx.observable(_animation$ctrl.stream)
      .where((_) => animations.isNotEmpty && animations.first.level == level)
      .take(1)
      .listen((_) {
        final CssAnimationBuilder cssAnimationBuilder = animationBuilder.css();

        cssAnimationBuilder.setDuration(duration);

        cssAnimationBuilder.setFromStyles(<String, dynamic>{
          'height': '0px',
          'visibility': 'visible',
          'position': 'relative'
        });

        cssAnimationBuilder.setToStyles(<String, dynamic>{
          'height': '${nativeElement.clientHeight}px'
        });

        cssAnimationBuilder.start(nativeElement)
          ..onComplete(() {
            nativeElement.style.removeProperty('height');
            nativeElement.style.removeProperty('visibility');
            nativeElement.style.removeProperty('position');

            animations.remove(this);
          });

        _animationBegan = true;
      });
  }

  @override void tweenClose(_) {
    cssAnimationBuilder.setDuration(duration);

    cssAnimationBuilder.setFromStyles(<String, dynamic>{
      'height': '${nativeElement.clientHeight}px',
      'visibility': 'visible',
      'position': 'relative'
    });

    cssAnimationBuilder.setToStyles(<String, dynamic>{
      'height': '0px'
    });

    cssAnimationBuilder.start(nativeElement)
      ..onComplete(() {
        nativeElement.style.removeProperty('height');
        nativeElement.style.removeProperty('visibility');
        nativeElement.style.removeProperty('position');

        animations.remove(this);

        beforeDestroyChildTrigger.add(index);
      });
  }

  void _nextAnimationFrame() {
    window.animationFrame.then((num time) {
      if (!_animationBegan) {
        _animation$ctrl.add(time);

        _nextAnimationFrame();
      }
    });
  }

}