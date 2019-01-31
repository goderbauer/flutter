// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

// the numbers below are odd, so that the totals don't seem round. :-)
const double todoCost = 1009.0; // about two average SWE days, in dollars
const double ignoreCost = 2003.0; // four average SWE days, in dollars
const double pythonCost = 3001.0; // six average SWE days, in dollars
const double skipCost = 2473.0; // 20 hours: 5 to fix the issue we're ignoring, 15 to fix the bugs we missed because the test was off
const double ignoreForFileCost = 2477.0; // similar thinking as skipCost
const double asDynamicCost = 2003.0; // same as ignoring analyzer warning

final RegExp todoPattern = RegExp(r'(?://|#) *TODO');
final RegExp ignorePattern = RegExp(r'// *ignore:');
final RegExp ignoreForFilePattern = RegExp(r'// *ignore_for_file:');
final RegExp asDynamicPattern = RegExp(r'as dynamic');

class _CostTotals {
  _CostTotals(this.item);

  final String item;

  double todoCost = 0.0;
  double ignoreCost = 0.0;
  double pythonCost = 0.0;
  double skipCost = 0.0;
  double ignoreForFileCost = 0.0;
  double asDynamicCost = 0.0;

  double get total => todoCost + ignoreCost + pythonCost + skipCost + ignoreForFileCost + asDynamicCost;

  String _toCvsLine(String costtype, double cost) => '$costtype, $item, $cost';

  String toCsv() {
    return '${_toCvsLine('todoCost', todoCost)}\n'
        '${_toCvsLine('ignoreCost', ignoreCost)}\n'
        '${_toCvsLine('pythonCost', pythonCost)}\n'
        '${_toCvsLine('skipCost', skipCost)}\n'
        '${_toCvsLine('ignoreForFileCost', ignoreForFileCost)}\n'
        '${_toCvsLine('asDynamicCost', asDynamicCost)}';}

  static String cvsHeader() {
    return 'costype,category,cost';
  }
}

Map<String, _CostTotals> _costs = <String, _CostTotals>{};

_CostTotals getTotalsForFile(String entry) {
  if (entry.startsWith('examples/')) {
    return _costs.putIfAbsent('examples', () => _CostTotals('examples'));
  }
  if (entry.startsWith('packages/flutter/lib/src/material/') || entry.startsWith('packages/flutter/test/material/')) {
    return _costs.putIfAbsent('flutter/material', () => _CostTotals('flutter/material'));
  }
  if (entry.startsWith('packages/flutter/lib/src/cupertino/') || entry.startsWith('packages/flutter/test/cupertino/')) {
    return _costs.putIfAbsent('flutter/cupertino', () => _CostTotals('flutter/cupertino'));
  }
  if (entry.startsWith('packages/flutter/')) {
    return _costs.putIfAbsent('flutter/framework', () => _CostTotals('flutter/framework'));
  }
  if (entry.startsWith('packages/')) {
    final String name = entry.split('/')[1];
    return _costs.putIfAbsent(name, () => _CostTotals(name));
  }
  return _costs.putIfAbsent('other', () => _CostTotals('other'));
}

Future<void> findCostsForFile(File file, _CostTotals totals) async {
  if (path.extension(file.path) == '.py')
    totals.pythonCost += pythonCost;
  if (path.extension(file.path) != '.dart' &&
      path.extension(file.path) != '.yaml' &&
      path.extension(file.path) != '.sh')
    return;
  final bool isTest = file.path.endsWith('_test.dart');
  for (String line in await file.readAsLines()) {
    if (line.contains(todoPattern))
      totals.todoCost += todoCost;
    if (line.contains(ignorePattern))
      totals.ignoreCost += ignoreCost;
    if (line.contains(ignoreForFilePattern))
      totals.ignoreForFileCost += ignoreForFileCost;
    if (line.contains(asDynamicPattern))
      totals.asDynamicCost += asDynamicCost;
    if (isTest && line.contains('skip:'))
      totals.skipCost += skipCost;
  }
}

Future<double> findCostsForRepo() async {
  final Process git = await startProcess(
    'git',
    <String>['ls-files', '--full-name', flutterDirectory.path],
    workingDirectory: flutterDirectory.path,
  );
  await for (String entry in git.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter())) {
    await findCostsForFile(File(path.join(flutterDirectory.path, entry)), getTotalsForFile(entry));
  }
  final int gitExitCode = await git.exitCode;
  if (gitExitCode != 0)
    throw Exception('git exit with unexpected error code $gitExitCode');
  print(_CostTotals.cvsHeader());
  for (_CostTotals v in _costs.values) {
    if (v.total != 0.0) {
      print(v.toCsv());
    }
  }
  return _costs.values.fold<double>(0.0, (double total, _CostTotals c) => total += c.total);
}

Future<int> countDependencies() async {
  final List<String> lines = (await evalFlutter(
    'update-packages',
    options: <String>['--transitive-closure'],
  )).split('\n');
  final int count = lines.where((String line) => line.contains('->')).length;
  if (count < 2) // we'll always have flutter and flutter_test, at least...
    throw Exception('"flutter update-packages --transitive-closure" returned bogus output:\n${lines.join("\n")}');
  return count;
}

Future<int> countConsumerDependencies() async {
  final List<String> lines = (await evalFlutter(
    'update-packages',
    options: <String>['--transitive-closure', '--consumer-only'],
  )).split('\n');
  final int count = lines.where((String line) => line.contains('->')).length;
  if (count < 2) // we'll always have flutter and flutter_test, at least...
    throw Exception('"flutter update-packages --transitive-closure" returned bogus output:\n${lines.join("\n")}');
  return count;
}

const String _kCostBenchmarkKey = 'technical_debt_in_dollars';
const String _kNumberOfDependenciesKey = 'dependencies_count';
const String _kNumberOfConsumerDependenciesKey = 'consumer_dependencies_count';

Future<void> main() async {
  await task(() async {
    return TaskResult.success(
      <String, dynamic>{
        _kCostBenchmarkKey: await findCostsForRepo(),
        _kNumberOfDependenciesKey: await countDependencies(),
        _kNumberOfConsumerDependenciesKey: await countConsumerDependencies(),
      },
      benchmarkScoreKeys: <String>[
        _kCostBenchmarkKey,
        _kNumberOfDependenciesKey,
        _kNumberOfConsumerDependenciesKey,
      ],
    );
  });
}
