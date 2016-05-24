library ng2_form_components.domain.list_item;

import 'package:dorm/dorm.dart';

@Ref('entities.listItem')
class ListItem<T extends Comparable> extends Entity implements Comparable {

  @override String get refClassName => 'entities.listItem';

  //-----------------------------
  // public properties
  //-----------------------------

  @Property(DATA_SYMBOL, 'data', dynamic, 'data')
  static const String DATA = 'data';
  static const Symbol DATA_SYMBOL = const Symbol('entities.listItem.data');

  T data;

  @Property(CONTAINER_SYMBOL, 'container', String, 'container')
  @DefaultValue('')
  static const String CONTAINER = 'container';
  static const Symbol CONTAINER_SYMBOL = const Symbol('entities.listItem.container');

  String container;

  @Property(PARENT_SYMBOL, 'parent', ListItem, 'parent')
  static const String PARENT = 'parent';
  static const Symbol PARENT_SYMBOL = const Symbol('entities.listItem.parent');

  ListItem<T> parent;

  @Property(SELECTABLE_SYMBOL, 'selectable', bool, 'selectable')
  @DefaultValue(true)
  static const String SELECTABLE = 'selectable';
  static const Symbol SELECTABLE_SYMBOL = const Symbol('entities.listItem.selectable');

  bool selectable;

  //-----------------------------
  // constructor
  //-----------------------------

  ListItem() : super();

  static ListItem construct() => new ListItem();

  @override int compareTo(ListItem other) {
    if (other != null && other.data != null) return other.data.compareTo(data);

    return -1;
  }

  @override String toString() => data.toString();

}