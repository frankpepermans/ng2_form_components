library ng2_form_components.domain.list_item;

import 'package:dorm/dorm.dart';

@dorm
abstract class ListItem<T extends Comparable<dynamic>>
    implements Entity, Comparable<ListItem<Comparable<dynamic>>> {
  T get data;
  @DefaultValue('')
  String get container;
  ListItem<T> get parent;
  @DefaultValue(true)
  bool get selectable;
  @DefaultValue(false)
  bool get isAlwaysOpen;

  @override
  int compareTo(ListItem<Comparable<dynamic>> other) {
    if (other != null && other.data != null) return other.data.compareTo(data);

    return -1;
  }

  @override
  String toString() => data.toString();
}
