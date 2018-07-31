import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:built_dorm/src/codegen/codegen.dart' show CodeGenerator;

Builder dormBuilder(BuilderOptions options) =>
    new LibraryBuilder(const CodeGenerator());
