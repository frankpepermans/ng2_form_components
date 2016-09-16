library ng2_form_components.components.animation.hierarchy_animation;

import 'dart:async';
import 'dart:html';

import 'package:rxdart/rxdart.dart' as rx;

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/animation/tween.dart';

@Directive(
    selector: '[hierarchy-tween]'
)
class HierarchyAnimation extends Tween implements OnInit, OnDestroy {

  @override @Input() set duration(int value) {
    super.duration = value;
  }

  @override @Input() set tweenStyleProperty(String value) {
    super.tweenStyleProperty = value;
  }

  @override @Input() set beforeDestroyChildTrigger(StreamController<dynamic> value) {
    super.beforeDestroyChildTrigger = value as StreamController<int>;
  }

  int _index;
  int get index => _index;
  @Input() set index(int value) {
    _index = value;
  }

  int _level;
  int get level => _level;
  @Input() set level(int value) {
    _level = value;
  }

  bool _forceAnimateOnOpen = false;
  bool get forceAnimateOnOpen => _forceAnimateOnOpen;
  @Input() set forceAnimateOnOpen(bool value) {
    _forceAnimateOnOpen = value;
  }

  static List<HierarchyAnimation> animations = <HierarchyAnimation>[];

  final StreamController<num> _animation$ctrl = new StreamController<num>.broadcast();

  StreamSubscription<dynamic> _beforeDestroyChildTriggerSubscription;
  StreamSubscription<num> _openSubscription;

  bool _animationBegan = false;
  Timer _openTimer;

  HierarchyAnimation(
      @Inject(ElementRef) ElementRef element) : super(element);

  @override void ngOnInit() {
    if (forceAnimateOnOpen) {
      nativeElement.style.visibility = 'hidden';
      nativeElement.style.position = 'absolute';

      window.animationFrame.whenComplete(tweenOpen);

      animations.add(this);

      _nextAnimationFrame();
    }

    if (beforeDestroyChildTrigger != null) _beforeDestroyChildTriggerSubscription = beforeDestroyChildTrigger.stream
      .where((int index) => index == this.index)
      .take(1)
      .listen(tweenClose);
  }

  @override void ngOnDestroy() {
    super.ngOnDestroy();

    animations.remove(this);

    _openSubscription?.cancel();
    _beforeDestroyChildTriggerSubscription?.cancel();

    _animation$ctrl.close();
  }

  @override void tweenOpen() {
    _openSubscription = rx.observable(_animation$ctrl.stream)
      .where((_) => animations.isNotEmpty && animations.first.level == level)
      .take(1)
      .listen((_) {
        final int toHeight = nativeElement.clientHeight;

        nativeElement.style.height = '0px';
        nativeElement.style.visibility = 'visible';
        nativeElement.style.position = 'relative';
        nativeElement.style.transition = 'height ${duration / 1000}s ease-out';

        animationFrame$()
          .take(1)
          .listen((_) {
            nativeElement.style.height = '${toHeight}px';

            _openTimer?.cancel();

            _openTimer = new Timer(new Duration(milliseconds: duration), () {
              nativeElement.style.removeProperty('height');
              nativeElement.style.removeProperty('visibility');
              nativeElement.style.removeProperty('position');

              animations.remove(this);
            });
          });

        _animationBegan = true;
      });
  }

  @override void tweenClose(_) {
    nativeElement.style.height = '${nativeElement.clientHeight}px';
    nativeElement.style.visibility = 'visible';
    nativeElement.style.position = 'relative';
    nativeElement.style.transition = 'height ${duration / 1000}s ease-out';

    animationFrame$()
      .take(1)
      .listen((_) {
        nativeElement.style.height = '0';

        _openTimer?.cancel();

        new Timer(new Duration(milliseconds: duration), () {
          nativeElement.style.removeProperty('height');
          nativeElement.style.removeProperty('visibility');
          nativeElement.style.removeProperty('position');

          animations.remove(this);

          if (!beforeDestroyChildTrigger.isClosed) beforeDestroyChildTrigger.add(index);
        });
      });
  }

  void _nextAnimationFrame() {
    window.animationFrame.then((num time) {
      if (!_animationBegan) {
        if (!_animation$ctrl.isClosed) _animation$ctrl.add(time);

        _nextAnimationFrame();
      }
    });
  }

}