import 'dart:async';
import 'dart:html';

typedef bool Matcher(MutationRecord record);

class MutationObserverStream extends Stream<bool> {
  final StreamController<bool> controller;

  MutationObserverStream(Element element,
      {Matcher matcher: null,
      bool subtree: true,
      bool childList: true,
      bool attributes: false,
      bool characterData: true})
      : controller = _buildController(
            element, matcher, subtree, childList, attributes, characterData);

  @override
  StreamSubscription<bool> listen(void onData(bool event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  static StreamController<bool> _buildController(
      Element element,
      Matcher matcher,
      bool subtree,
      bool childList,
      bool attributes,
      bool characterData) {
    StreamController<bool> controller;
    MutationObserver observer;

    matcher ??= (MutationRecord record) => true;

    controller = new StreamController<bool>(
        sync: true,
        onListen: () {
          void onMutation(List<dynamic> mutations, MutationObserver observer) {
            final List<MutationRecord> list = mutations.cast<MutationRecord>();

            final MutationRecord match =
                list.firstWhere(matcher, orElse: () => null);

            if (match != null) controller.add(true);
          }

          observer = new MutationObserver(onMutation)
            ..observe(element,
                subtree: subtree,
                childList: childList,
                attributes: attributes,
                characterData: characterData);
        },
        onCancel: () => observer.disconnect());

    return controller;
  }
}
