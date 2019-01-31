import 'dart:async';
import 'dart:html';

class MutationObserverStream extends Stream<bool> {
  final StreamController<bool> controller;

  static bool _defaultMatcher(MutationRecord record) => true;

  MutationObserverStream(Element element,
      {bool matcher(MutationRecord record) = _defaultMatcher,
      bool subtree = true,
      bool childList = true,
      bool attributes = false,
      List<String> attributeFilter = null,
      bool characterData = true})
      : controller = _buildController(element, matcher, subtree, childList,
            attributes, attributeFilter, characterData);

  @override
  StreamSubscription<bool> listen(void onData(bool event),
          {Function onError, void onDone(), bool cancelOnError}) =>
      controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  static StreamController<bool> _buildController(
      Element element,
      bool matcher(MutationRecord record),
      bool subtree,
      bool childList,
      bool attributes,
      List<String> attributeFilter,
      bool characterData) {
    StreamController<bool> controller;
    MutationObserver observer;

    return controller = StreamController<bool>(
        sync: true,
        onListen: () {
          void onMutation(List<dynamic> mutations, MutationObserver observer) {
            final List<MutationRecord> list = mutations.cast<MutationRecord>();

            final MutationRecord match =
                list.firstWhere(matcher, orElse: () => null);

            if (match != null) controller.add(true);
          }

          observer = MutationObserver(onMutation)
            ..observe(element,
                subtree: subtree,
                childList: childList,
                attributes: attributes,
                attributeFilter: attributeFilter,
                characterData: characterData);
        },
        onCancel: () => observer.disconnect());
  }
}
