// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap can be created with valid Map - SwipeEdge.left', () {
    final PredictiveBackEvent event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(event.swipeEdge, SwipeEdge.left);
    expect(event.isButtonEvent, isFalse);
  });

  test('fromMap can be created with valid Map - SwipeEdge.right', () {
    final PredictiveBackEvent event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 1,
    });
    expect(event.swipeEdge, SwipeEdge.right);
    expect(event.isButtonEvent, isFalse);
  });

  test('fromMap can be created with valid Map - isButtonEvent zero position', () {
    final PredictiveBackEvent event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 0.0],
      'progress': 0.0,
      'swipeEdge': 1,
    });
    expect(event.isButtonEvent, isTrue);
  });

  test('fromMap can be created with valid Map - isButtonEvent null position', () {
    final PredictiveBackEvent event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': null,
      'progress': 0.0,
      'swipeEdge': 1,
    });
    expect(event.isButtonEvent, isTrue);
  });

  test('fromMap throws when given invalid progress', () {
    expect(
      () => PredictiveBackEvent.fromMap(const <String?, Object?>{
        'touchOffset': <double>[0.0, 100.0],
        'progress': 2.0,
        'swipeEdge': 1,
      }),
      throwsAssertionError,
    );
  });

  test('fromMap throws when given invalid swipeEdge', () {
    expect(
      () => PredictiveBackEvent.fromMap(const <String?, Object?>{
        'touchOffset': <double>[0.0, 100.0],
        'progress': 0.0,
        'swipeEdge': 2,
      }),
      throwsRangeError,
    );
  });

  test('equality when created with the same parameters', () {
    final PredictiveBackEvent eventA = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    final PredictiveBackEvent eventB = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(eventA, equals(eventB));
    expect(eventA.hashCode, equals(eventB.hashCode));
    expect(eventA.toString(), equals(eventB.toString()));
  });

  test('when created with different parameters', () {
    final PredictiveBackEvent eventA = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    final PredictiveBackEvent eventB = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[1.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(eventA, isNot(equals(eventB)));
    expect(eventA.hashCode, isNot(equals(eventB.hashCode)));
    expect(eventA.toString(), isNot(equals(eventB.toString())));
  });
}
