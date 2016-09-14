library ng2_form_components.infrastructure.drag_drop_service;

import 'package:angular2/angular2.dart';

import 'package:ng2_form_components/src/components/list_item.dart';

import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';

@Injectable()
abstract class DragDropService {

  ListDragDropHandlerType typeHandler(ListItem<Comparable<dynamic>> listItem);

  String resolveDropClassName(ListItem<Comparable<dynamic>> dropListItem);

}