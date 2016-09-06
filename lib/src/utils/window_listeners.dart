library ng2_form_components.utils.window_listeners;

import 'dart:async';
import 'dart:html';

class WindowListeners {

  Stream<bool> get windowMutation => _windowMutation.stream;
  Stream<bool> get windowResize => _windowResize.stream;

  final StreamController<bool> _windowMutation = new StreamController<bool>.broadcast();
  final StreamController<bool> _windowResize = new StreamController<bool>.broadcast();

  static WindowListeners _instance;

  factory WindowListeners() {
    if (_instance != null) return _instance;

    _instance = new WindowListeners._internal();

    return _instance;
  }

  WindowListeners._internal() {
    new MutationObserver(_onModified).observe(document, subtree: true, childList: true, attributes: true, characterData: true);

    window.addEventListener('resize', _onWindowResize);
  }


  void _onModified(__, _) => _windowMutation.add(true);

  void _onWindowResize(_) => _windowResize.add(true);

}