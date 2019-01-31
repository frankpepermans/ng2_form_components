import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/list_item.g.dart';

import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';

@Injectable()
class DragDropService {
  ListDragDropHandlerType typeHandler(ListItem<Comparable> listItem) =>
      ListDragDropHandlerType.NONE;

  String resolveDropClassName(ListItem<Comparable> dropListItem) =>
      'ngDragDrop--drop-inside';
}
