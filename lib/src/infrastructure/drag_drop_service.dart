library ng2_form_components.infrastructure.drag_drop_service;

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/list_item.g.dart';

import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';

@Injectable()
class DragDropService {

  ListDragDropHandlerType typeHandler(ListItem<Comparable<dynamic>> listItem) => ListDragDropHandlerType.NONE;

  String resolveDropClassName(ListItem<Comparable<dynamic>> dropListItem) => 'ngDragDrop--drop-inside';

}