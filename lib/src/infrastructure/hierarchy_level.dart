library domain.hierarchy_level;

import 'package:dorm/dorm.dart';

@Ref('domain.hierarchy_level')
class HierarchyLevel extends Entity implements Comparable {

  String get refClassName => 'domain.hierarchy_level';

  @Property(LABEL_SYMBOL, 'label', String, 'label')
  @Id('')
  static const String LABEL = 'label';
  static const Symbol LABEL_SYMBOL = const Symbol('domain.hierarchy_level.label');

  String label;

  @Property(CHILDREN_SYMBOL, 'children', List, 'children')
  @Transient()
  static const String CHILDREN = 'children';
  static const Symbol CHILDREN_SYMBOL = const Symbol('domain.hierarchy_level.children');

  List<HierarchyLevel> children;

  HierarchyLevel() : super();

  static HierarchyLevel construct() => new HierarchyLevel();

  int compareTo(HierarchyLevel other) {
    if (other != null) return (other.label.compareTo(label) == 0) ? 0 : 1;

    return -1;
  }

}