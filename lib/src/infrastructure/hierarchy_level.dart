library domain.hierarchy_level;

import 'package:dorm/dorm.dart';

@dorm
abstract class HierarchyLevel extends Entity implements Comparable<HierarchyLevel> {
  @Id('')
  String get label;
  @Transient()
  List<HierarchyLevel> get children;

  @override int compareTo(HierarchyLevel other) {
    if (other != null) return (other.label.compareTo(label) == 0) ? 0 : 1;

    return -1;
  }

}