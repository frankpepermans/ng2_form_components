// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: CodeGenerator
// Target: abstract class HierarchyLevel
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
      new DormProxy<List<HierarchyLevel>>(CHILDREN, CHILDREN_SYMBOL);
  @override
  List<HierarchyLevel> get children => _children.value;
  set children(List<HierarchyLevel> value) {
    _children.value = value;
  }

  /// label
  static const String LABEL = 'label';
  static const Symbol LABEL_SYMBOL =
      #i112ng2_form_components_lib_src_infrastructure_hierarchy_level_label;

  final DormProxy<String> _label = new DormProxy<String>(LABEL, LABEL_SYMBOL);
  @override
  String get label => _label.value;
  set label(String value) {
    _label.value = value;
  }

  /// DO_SCAN
  static void DO_SCAN /**/ ([String _R, Entity _C()]) {
    _R ??= 'i112ng2_form_components_lib_src_infrastructure_hierarchy_level';
    _C ??= () => new HierarchyLevel();
    Entity.DO_SCAN(_R, _C);
    Entity.ASSEMBLER.scan(_R, _C, const <PropertyData>[
      const PropertyData(
          symbol: HierarchyLevel.CHILDREN_SYMBOL,
          name: 'children',
          type: List,
          metatags: const <dynamic>[
            const Transient(),
          ]),
      const PropertyData(
          symbol: HierarchyLevel.LABEL_SYMBOL,
          name: 'label',
          type: String,
          metatags: const <dynamic>[
            const Id(''),
          ]),
    ]);
  }

  /// Ctr
  HierarchyLevel() : super() {
    Entity.ASSEMBLER
        .registerProxies(this, <DormProxy<dynamic>>[_children, _label]);
  }
  static HierarchyLevel /**/ construct /**/ () => new HierarchyLevel();
}
