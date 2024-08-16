// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JsonEncoder;

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:gallery/data/demos.dart';
import 'package:gallery/main.dart' show GalleryApp;

// See transitions_perf_test.dart for how to run this test.

Future<String> _handleMessages(String? message) async {
  switch (message) {
    case 'demoDescriptions':
      final List<String> demoDescriptions = Demos.allDescriptions();
      return JsonEncoder.withIndent('  ').convert(demoDescriptions);
    case 'isTestingCraneOnly':
      return String.fromEnvironment('onlyCrane', defaultValue: 'false');
    case 'isTestingReplyOnly':
      return String.fromEnvironment('onlyReply', defaultValue: 'false');
    default:
      throw 'unknown message';
  }
}

void main() {
  enableFlutterDriverExtension(handler: _handleMessages);
  runApp(GalleryApp(isTestMode: true));
}
