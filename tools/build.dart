import 'dart:async';

import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:ng2_form_components/builder.dart';

Future<BuildResult> main(List<String> args) async => build(<BuilderApplication>[
      new BuilderApplication.forBuilder(
          'domain',
          //ignore: always_specify_types
          [dormBuilder],
          (PackageNode node) => node.isRoot,
          hideOutput: false,
          defaultGenerateFor: const InputSet(include: const <String>[
            'lib/src/components/list_item.dart',
            'lib/src/infrastructure/hierarchy_level.dart',
            'web/person.dart'
          ]))
      /*new BuilderApplication.forBuilder('swagger_api', [swaggerBuilder],
        (PackageNode node) => node.name == 'xpert_libraries')*/
    ], deleteFilesByDefault: true);
