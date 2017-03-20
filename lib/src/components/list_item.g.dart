// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: CodeGenerator
// Target: abstract class ListItem
// **************************************************************************

import 'package:dorm/dorm.dart';

import 'list_item.dart' as sup;

class ListItem<T extends Comparable<dynamic>> extends Entity
    with sup.ListItem<T>
    implements Comparable<sup.ListItem<Comparable<dynamic>>> {
  /// refClassName
  @override
  String get refClassName =>
      'i112ng2_form_components_lib_src_components_list_item';

  /// Public properties
  /// container
  static const String CONTAINER = 'container';
  static const Symbol CONTAINER_SYMBOL =
      #i112ng2_form_components_lib_src_components_list_item_container;

  final DormProxy<String> _container =
      new DormProxy<String>(CONTAINER, CONTAINER_SYMBOL);
  @override
  String get container => _container.value;
  set container(String value) {
    _container.value = value;
  }

  /// data
  static const String DATA = 'data';
  static const Symbol DATA_SYMBOL =
      #i112ng2_form_components_lib_src_components_list_item_data;

  final DormProxy<T> _data = new DormProxy<T>(DATA, DATA_SYMBOL);
  @override
  T get data => _data.value;
  set data(T value) {
    _data.value = value;
  }

  /// isAlwaysOpen
  static const String ISALWAYSOPEN = 'isAlwaysOpen';
  static const Symbol ISALWAYSOPEN_SYMBOL =
      #i112ng2_form_components_lib_src_components_list_item_isAlwaysOpen;

  final DormProxy<bool> _isAlwaysOpen =
      new DormProxy<bool>(ISALWAYSOPEN, ISALWAYSOPEN_SYMBOL);
  @override
  bool get isAlwaysOpen => _isAlwaysOpen.value;
  set isAlwaysOpen(bool value) {
    _isAlwaysOpen.value = value;
  }

  /// parent
  static const String PARENT = 'parent';
  static const Symbol PARENT_SYMBOL =
      #i112ng2_form_components_lib_src_components_list_item_parent;

  final DormProxy<ListItem<T>> _parent =
      new DormProxy<ListItem<T>>(PARENT, PARENT_SYMBOL);
  @override
  ListItem<T> get parent => _parent.value;
  set parent(ListItem<T> value) {
    _parent.value = value;
  }

  /// selectable
  static const String SELECTABLE = 'selectable';
  static const Symbol SELECTABLE_SYMBOL =
      #i112ng2_form_components_lib_src_components_list_item_selectable;

  final DormProxy<bool> _selectable =
      new DormProxy<bool>(SELECTABLE, SELECTABLE_SYMBOL);
  @override
  bool get selectable => _selectable.value;
  set selectable(bool value) {
    _selectable.value = value;
  }

  /// DO_SCAN
  static void DO_SCAN<T extends Comparable<dynamic>>([String _R, Entity _C()]) {
    _R ??= 'i112ng2_form_components_lib_src_components_list_item';
    _C ??= () => new ListItem<T>();
    Entity.DO_SCAN(_R, _C);
    Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[
      const PropertyData(
          symbol: ListItem.CONTAINER_SYMBOL,
          name: 'container',
          type: String,
          metatags: const <dynamic>[
            const DefaultValue(''),
          ]),
      const PropertyData(
          symbol: ListItem.DATA_SYMBOL,
          name: 'data',
          type: dynamic,
          metatags: const <dynamic>[]),
      const PropertyData(
          symbol: ListItem.ISALWAYSOPEN_SYMBOL,
          name: 'isAlwaysOpen',
          type: bool,
          metatags: const <dynamic>[
            const DefaultValue(false),
          ]),
      const PropertyData(
          symbol: ListItem.PARENT_SYMBOL,
          name: 'parent',
          type: ListItem,
          metatags: const <dynamic>[]),
      const PropertyData(
          symbol: ListItem.SELECTABLE_SYMBOL,
          name: 'selectable',
          type: bool,
          metatags: const <dynamic>[
            const DefaultValue(true),
          ]),
    ]);
  }

  /// Ctr
  ListItem() : super() {
    Entity.ASSEMBLER.registerProxies(this, <DormProxy<dynamic>>[
      _container,
      _data,
      _isAlwaysOpen,
      _parent,
      _selectable
    ]);
  }
  static ListItem<T>
      construct<T extends Comparable<dynamic>>() => new ListItem<T>();
}
