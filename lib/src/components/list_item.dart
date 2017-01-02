library ng2_form_components.domain.list_item;

class ListItem<T extends Comparable<dynamic>> implements Comparable<ListItem<Comparable<dynamic>>> {
  T data;
  String container;
  ListItem<T> parent;
  bool selectable;
  bool isAlwaysOpen;

  @override int compareTo(ListItem<Comparable<dynamic>> other) {
    if (other != null && other.data != null) return other.data.compareTo(data);

    return -1;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'data': data,
    'container': container,
    'parent': parent,
    'selectable': selectable,
    'isAlwaysOpen': isAlwaysOpen
  };

}