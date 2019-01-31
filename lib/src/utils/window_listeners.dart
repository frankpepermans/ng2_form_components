import 'dart:async';
import 'dart:html';

import 'package:ng2_form_components/src/utils/mutation_observer_stream.dart';

class WindowListeners {
  Stream<bool> get windowMutation =>
      MutationObserverStream(document.body).skip(1);
  Stream<bool> get windowResize => _maybeConstructResizeListener();

  final StreamController<bool> _windowResize =
      StreamController<bool>.broadcast();

  bool _hasResizeListener = false;

  static WindowListeners _instance;

  factory WindowListeners() => _instance ??= WindowListeners._internal();

  WindowListeners._internal();

  void _onWindowResize(dynamic _) => _windowResize.add(true);

  Stream<bool> _maybeConstructResizeListener() {
    if (!_hasResizeListener) {
      _hasResizeListener = true;

      window.addEventListener('resize', _onWindowResize);
    }

    return _windowResize.stream;
  }
}
