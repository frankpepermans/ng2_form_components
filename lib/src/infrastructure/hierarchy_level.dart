library domain.hierarchy_level;

import 'package:dorm/dorm.dart';

@dorm
abstract class HierarchyLevel implements Entity, Comparable<dynamic> {
  @Id('')
  String get label;
  @Transient()
  List<HierarchyLevel> get children;

  @override
  int compareTo(dynamic other) {
    if (other is HierarchyLevel)
      return (other.label.compareTo(label) == 0) ? 0 : 1;

    return -1;
  }
}
