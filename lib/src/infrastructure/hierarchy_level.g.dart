// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CodeGenerator
// **************************************************************************

import 'package:dorm/dorm.dart';

import 'hierarchy_level.dart' as sup;

class HierarchyLevel extends Entity
    with sup.HierarchyLevel
    implements Comparable<dynamic> {
  /// refClassName
  @override
  String get refClassName =>
      'i112ng2_form_components_lib_src_infrastructure_hierarchy_level';

  /// Public properties
  /// children
  static const String CHILDREN = 'children';
  static const Symbol CHILDREN_SYMBOL =
      #i112ng2_form_components_lib_src_infrastructure_hierarchy_level_children;

  final DormProxy<List<HierarchyLevel>> _children =
      DormProxy<List<HierarchyLevel>>(CHILDREN, CHILDREN_SYMBOL);
  @override
  List<HierarchyLevel> get children => _children.value;
  set children(List<HierarchyLevel> value) {
    _children.value = value;
  }

  /// label
  static const String LABEL = 'label';
  static const Symbol LABEL_SYMBOL =
      #i112ng2_form_components_lib_src_infrastructure_hierarchy_level_label;

  final DormProxy<String> _label = DormProxy<String>(LABEL, LABEL_SYMBOL);
  @override
  String get label => _label.value;
  set label(String value) {
    _label.value = value;
  }

  /// DO_SCAN
  static void DO_SCAN([String _R, Entity _C()]) {
    _R ??= 'i112ng2_form_components_lib_src_infrastructure_hierarchy_level';
    _C ??= () => HierarchyLevel();
    Entity.DO_SCAN(_R, _C);
    Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[
      PropertyData(
          symbol: HierarchyLevel.CHILDREN_SYMBOL,
          name: 'children',
          type: List,
          metatags: <dynamic>[
            Transient(),
          ]),
      PropertyData(
          symbol: HierarchyLevel.LABEL_SYMBOL,
          name: 'label',
          type: String,
          metatags: <dynamic>[
            Id(''),
          ]),
    ]);
  }

  /// Constructor
  HierarchyLevel() {
    Entity.ASSEMBLER
        .registerProxies(this, <DormProxy<dynamic>>[_children, _label]);
    this.children = List<HierarchyLevel>();
  }

  /// Internal constructor
  static HierarchyLevel construct() => HierarchyLevel();

  /// withChildren
  HierarchyLevel withChildren(List<HierarchyLevel> value) =>
      duplicate(ignoredSymbols: const <Symbol>[HierarchyLevel.CHILDREN_SYMBOL])
        ..children = value;

  /// withLabel
  HierarchyLevel withLabel(String value) =>
      duplicate(ignoredSymbols: const <Symbol>[HierarchyLevel.LABEL_SYMBOL])
        ..label = value;

  /// Duplicates the [HierarchyLevel] and any recursive entities to a new [HierarchyLevel]
  @override
  HierarchyLevel duplicate({List<Symbol> ignoredSymbols}) =>
      super.duplicate(ignoredSymbols: ignoredSymbols) as HierarchyLevel;
  @override
  bool operator ==(Object other) =>
      other is HierarchyLevel && other.hashCode == this.hashCode;
  @override
  int get hashCode => hash_finish(hash_combine(
      hash_combine(0, hash_combineAll(this.children)), this.label.hashCode));

  /// toString implementation for debugging purposes
  @override
  String toString() => 'HierarchyLevel: {label: $label}';
}
