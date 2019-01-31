// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CodeGenerator
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
      DormProxy<String>(CONTAINER, CONTAINER_SYMBOL);
  @override
  String get container => _container.value;
  set container(String value) {
    _container.value = value;
  }

  /// data
  static const String DATA = 'data';
  static const Symbol DATA_SYMBOL =
      #i112ng2_form_components_lib_src_components_list_item_data;

  final DormProxy<T> _data = DormProxy<T>(DATA, DATA_SYMBOL);
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
      DormProxy<bool>(ISALWAYSOPEN, ISALWAYSOPEN_SYMBOL);
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
      DormProxy<ListItem<T>>(PARENT, PARENT_SYMBOL);
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
      DormProxy<bool>(SELECTABLE, SELECTABLE_SYMBOL);
  @override
  bool get selectable => _selectable.value;
  set selectable(bool value) {
    _selectable.value = value;
  }

  /// DO_SCAN
  static void DO_SCAN<T extends Comparable<dynamic>>([String _R, Entity _C()]) {
    _R ??= 'i112ng2_form_components_lib_src_components_list_item';
    _C ??= () => ListItem<T>();
    Entity.DO_SCAN(_R, _C);
    Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[
      PropertyData(
          symbol: ListItem.CONTAINER_SYMBOL,
          name: 'container',
          type: String,
          metatags: <dynamic>[
            DefaultValue(''),
          ]),
      PropertyData(
          symbol: ListItem.DATA_SYMBOL,
          name: 'data',
          type: dynamic,
          metatags: <dynamic>[]),
      PropertyData(
          symbol: ListItem.ISALWAYSOPEN_SYMBOL,
          name: 'isAlwaysOpen',
          type: bool,
          metatags: <dynamic>[
            DefaultValue(false),
          ]),
      PropertyData(
          symbol: ListItem.PARENT_SYMBOL,
          name: 'parent',
          type: ListItem,
          metatags: <dynamic>[]),
      PropertyData(
          symbol: ListItem.SELECTABLE_SYMBOL,
          name: 'selectable',
          type: bool,
          metatags: <dynamic>[
            DefaultValue(true),
          ]),
    ]);
  }

  /// Constructor
  ListItem() {
    Entity.ASSEMBLER.registerProxies(this, <DormProxy<dynamic>>[
      _container,
      _data,
      _isAlwaysOpen,
      _parent,
      _selectable
    ]);
  }

  /// Internal constructor
  static ListItem<T> construct<T extends Comparable<dynamic>>() =>
      ListItem<T>();

  /// withContainer
  ListItem<T> withContainer(String value) =>
      duplicate(ignoredSymbols: const <Symbol>[ListItem.CONTAINER_SYMBOL])
        ..container = value;

  /// withData
  ListItem<T> withData(T value) =>
      duplicate(ignoredSymbols: const <Symbol>[ListItem.DATA_SYMBOL])
        ..data = value;

  /// withIsAlwaysOpen
  ListItem<T> withIsAlwaysOpen(bool value) =>
      duplicate(ignoredSymbols: const <Symbol>[ListItem.ISALWAYSOPEN_SYMBOL])
        ..isAlwaysOpen = value;

  /// withParent
  ListItem<T> withParent(ListItem<T> value) =>
      duplicate(ignoredSymbols: const <Symbol>[ListItem.PARENT_SYMBOL])
        ..parent = value;

  /// withSelectable
  ListItem<T> withSelectable(bool value) =>
      duplicate(ignoredSymbols: const <Symbol>[ListItem.SELECTABLE_SYMBOL])
        ..selectable = value;

  /// Duplicates the [ListItem] and any recursive entities to a new [ListItem]
  @override
  ListItem<T> duplicate({List<Symbol> ignoredSymbols}) =>
      super.duplicate(ignoredSymbols: ignoredSymbols) as ListItem<T>;
  @override
  bool operator ==(Object other) =>
      other is ListItem<T> && other.hashCode == this.hashCode;

  /// toString implementation for debugging purposes
  @override
  String toString() => 'i112ng2_form_components_lib_src_components_list_item';
}
