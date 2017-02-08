library ng2_form_components.components.html_text_transform_menu;

import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:ng2_form_components/src/components/helpers/html_text_transformation.dart' show HTMLTextTransformation;

@Component(
    selector: 'html-text-transform-menu',
    templateUrl: 'html_text_transform_menu.html',
    changeDetection: ChangeDetectionStrategy.Stateful,
    preserveWhitespace: false
)
class HTMLTextTransformMenu extends ComponentState implements OnDestroy {

  //-----------------------------
  // input
  //-----------------------------

  List<List<HTMLTextTransformation>> _buttons;
  List<List<HTMLTextTransformation>> get buttons => _buttons;
  @Input() set buttons(List<List<HTMLTextTransformation>> value) {
    setState(() => _buttons = value);
  }

  //-----------------------------
  // output
  //-----------------------------

  @Output() Stream<HTMLTextTransformation> get transformation => _transformation$ctrl.stream;

  //-----------------------------
  // private properties
  //-----------------------------

  final StreamController<HTMLTextTransformation> _transformation$ctrl = new StreamController<HTMLTextTransformation>.broadcast();

  //-----------------------------
  // Constructor
  //-----------------------------

  HTMLTextTransformMenu();

  //-----------------------------
  // ng2 life cycle
  //-----------------------------

  @override void ngOnDestroy() {
    _transformation$ctrl.close();
  }

  //-----------------------------
  // template methods
  //-----------------------------

  void triggerButton(HTMLTextTransformation transformationType, MouseEvent event) {
    event.preventDefault();
    event.stopPropagation();

    _transformation$ctrl.add(transformationType);
  }

  //-----------------------------
  // inner methods
  //-----------------------------

}