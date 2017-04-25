import 'dart:async';
import 'dart:html';

typedef bool Matcher(MutationRecord record);

class MutationObserverStream extends Stream<bool> {
  final StreamController<bool> controller;

  MutationObserverStream(Element element, {Matcher matcher: null})
      : controller = _buildController(element, matcher);

  @override
  StreamSubscription<bool> listen(void onData(bool event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  static StreamController<bool> _buildController(
      Element element, Matcher matcher) {
    StreamController<bool> controller;
    MutationObserver observer;

    matcher ??= (_) => true;

    controller = new StreamController<bool>(
        sync: true,
        onListen: () {
          void onMutation(
              List<MutationRecord> mutations, MutationObserver observer) {
            final MutationRecord match =
                mutations.firstWhere(matcher, orElse: () => null);

            if (match != null) controller.add(true);
          }

          observer = new MutationObserver(onMutation)
            ..observe(element,
                subtree: true,
                childList: true,
                attributes: false,
                characterData: true);
        },
        onCancel: () => observer.disconnect());

    return controller;
  }
}
