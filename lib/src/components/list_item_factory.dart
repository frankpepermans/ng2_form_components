library ng2_form_components.domain.list_item_factory;

import 'package:ng2_form_components/src/components/list_item.dart';

class ListItemFactory<T extends Comparable> {

  static ListItemFactory _instance;

  int _nextUid = 1;

  factory ListItemFactory() {
    if (_instance != null) return _instance as ListItemFactory<T>;

    _instance = new ListItemFactory._internal();

    return _instance as ListItemFactory<T>;
  }

  ListItemFactory._internal();

  ListItem<T> create() => new ListItem()..id = _nextUid++;

}