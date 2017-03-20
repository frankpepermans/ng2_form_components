import 'dart:async';
import 'dart:html';

class MutationObserverStream extends Stream<bool> {
  final StreamController<bool> controller;

  MutationObserverStream(Element element)
      : controller = _buildController(element);

  @override
  StreamSubscription<bool> listen(void onData(bool event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  static StreamController<bool> _buildController(Element element) {
    StreamController<bool> controller;
    MutationObserver observer;

    controller = new StreamController<bool>(
        sync: true,
        onListen: () {
          void onMutation(
                  List<MutationRecord> mutations, MutationObserver observer) =>
              controller.add(true);

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
