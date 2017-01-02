library domain.hierarchy_level;

class HierarchyLevel implements Comparable<HierarchyLevel> {
  String label;
  List<HierarchyLevel> children;

  @override int compareTo(HierarchyLevel other) {
    if (other != null) return (other.label.compareTo(label) == 0) ? 0 : 1;

    return -1;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'children': children
  };
}