// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:vitool/vitool.dart';

const String kCodegenComment =
    '// AUTOGENERATED FILE DO NOT EDIT!\n'
    '// This file was generated by vitool.\n';

void main(List<String> args) {
  final ArgParser parser = ArgParser();

  parser.addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: "Display the tool's usage instructions and quit.",
  );

  parser.addOption('output', abbr: 'o', help: 'Target path to write the generated Dart file to.');

  parser.addOption('asset-name', abbr: 'n', help: 'Name to be used for the generated constant.');

  parser.addOption('part-of', abbr: 'p', help: "Library name to add a dart 'part of' clause for.");

  parser.addOption(
    'header',
    abbr: 'd',
    help:
        'File whose contents are to be prepended to the beginning of '
        'the generated Dart file; this can be used for a license comment.',
  );

  parser.addFlag(
    'codegen_comment',
    abbr: 'c',
    defaultsTo: true,
    help:
        'Whether to include the following comment after the header:\n'
        '$kCodegenComment',
  );

  final ArgResults argResults = parser.parse(args);

  if (argResults['help'] as bool ||
      !argResults.wasParsed('output') ||
      !argResults.wasParsed('asset-name') ||
      argResults.rest.isEmpty) {
    printUsage(parser);
    return;
  }

  final List<FrameData> frames = <FrameData>[
    for (final String filePath in argResults.rest) interpretSvg(filePath),
  ];

  final StringBuffer generatedSb = StringBuffer();

  if (argResults.wasParsed('header')) {
    generatedSb.write(File(argResults['header'] as String).readAsStringSync());
    generatedSb.write('\n');
  }

  if (argResults['codegen_comment'] as bool) {
    generatedSb.write(kCodegenComment);
  }

  if (argResults.wasParsed('part-of')) {
    generatedSb.write(
      'part of ${argResults['part-of']}; // ignore: use_string_in_part_of_directives\n',
    );
  }

  final Animation animation = Animation.fromFrameData(frames);
  generatedSb.write(animation.toDart('_AnimatedIconData', argResults['asset-name'] as String));

  final File outFile = File(argResults['output'] as String);
  outFile.writeAsStringSync(generatedSb.toString());
}

void printUsage(ArgParser parser) {
  print('Usage: vitool --asset-name=<asset_name> --output=<output_path> <frames_list>');
  print(
    '\nExample: vitool --asset-name=_\$menu_arrow --output=lib/data/menu_arrow.g.dart assets/svg/menu_arrow/*.svg\n',
  );
  print(parser.usage);
}
