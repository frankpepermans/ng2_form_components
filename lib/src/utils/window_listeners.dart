library ng2_form_components.utils.window_listeners;

import 'dart:async';
import 'dart:html';

class WindowListeners {

  Stream<bool> get windowDOMSubtreeModified => _windowDOMSubtreeModified.stream;
  Stream<bool> get windowResize => _windowResize.stream;

  final StreamController<bool> _windowDOMSubtreeModified = new StreamController<bool>.broadcast();
  final StreamController<bool> _windowResize = new StreamController<bool>.broadcast();

  static WindowListeners _instance;

  factory WindowListeners() {
    if (_instance != null) return _instance;

    _instance = new WindowListeners._internal();

    return _instance;
  }

  WindowListeners._internal() {
    window.addEventListener('DOMSubtreeModified', _onDOMSubtreeModified);
    window.addEventListener('resize', _onWindowResize);
  }


  void _onDOMSubtreeModified(_) => _windowDOMSubtreeModified.add(true);

  void _onWindowResize(_) => _windowResize.add(true);

}