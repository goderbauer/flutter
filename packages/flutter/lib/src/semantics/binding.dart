// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show AccessibilityFeatures, SemanticsUpdateBuilder, SemanticsAction;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'debug.dart';

export 'dart:ui' show AccessibilityFeatures, SemanticsAction;

/// The glue between the semantics layer and the Flutter engine.
mixin SemanticsBinding on BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _accessibilityFeatures = platformDispatcher.accessibilityFeatures;
    platformDispatcher
      ..onSemanticsEnabledChanged = _handleSemanticsEnabledChanged
      ..onSemanticsAction = _handleSemanticsAction;
    _handleSemanticsEnabledChanged();
  }

  ///
  final SemanticsCoordinator semanticsCoordinator = SemanticsCoordinator._();

  SemanticsHandle? _semanticsHandle;

  void _handleSemanticsEnabledChanged() {
    setSemanticsEnabled(platformDispatcher.semanticsEnabled);
  }

  void _handleSemanticsAction(int id, ui.SemanticsAction action, ByteData? args) {
    performSemanticsAction(
      0, // TODO(window): this needs to come from the engine.
      id,
      action,
      args != null ? const StandardMessageCodec().decodeMessage(args) : null,
    );
  }

  ///
  @protected
  void performSemanticsAction(int viewId, int nodeId, ui.SemanticsAction action, Object? args);

  /// Whether the render tree associated with this binding should produce a tree
  /// of [SemanticsNode] objects.
  void setSemanticsEnabled(bool enabled) {
    if (enabled) {
      _semanticsHandle ??= semanticsCoordinator.ensureSemantics();
    } else {
      _semanticsHandle?.dispose();
      _semanticsHandle = null;
    }
  }

  /// The current [SemanticsBinding], if one has been created.
  ///
  /// Provides access to the features exposed by this mixin. The binding must
  /// be initialized before using this getter; this is typically done by calling
  /// [runApp] or [WidgetsFlutterBinding.ensureInitialized].
  static SemanticsBinding get instance => BindingBase.checkInstance(_instance);
  static SemanticsBinding? _instance;

  /// Called when the platform accessibility features change.
  ///
  /// See [dart:ui.PlatformDispatcher.onAccessibilityFeaturesChanged].
  @protected
  void handleAccessibilityFeaturesChanged() {
    _accessibilityFeatures = platformDispatcher.accessibilityFeatures;
  }

  /// Creates an empty semantics update builder.
  ///
  /// The caller is responsible for filling out the semantics node updates.
  ///
  /// This method is used by the [SemanticsOwner] to create builder for all its
  /// semantics updates.
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() {
    return ui.SemanticsUpdateBuilder();
  }

  /// The currently active set of [AccessibilityFeatures].
  ///
  /// This is initialized the first time [runApp] is called and updated whenever
  /// a flag is changed.
  ///
  /// To listen to changes to accessibility features, create a
  /// [WidgetsBindingObserver] and listen to
  /// [WidgetsBindingObserver.didChangeAccessibilityFeatures].
  ui.AccessibilityFeatures get accessibilityFeatures => _accessibilityFeatures;
  late ui.AccessibilityFeatures _accessibilityFeatures;

  /// The platform is requesting that animations be disabled or simplified.
  ///
  /// This setting can be overridden for testing or debugging by setting
  /// [debugSemanticsDisableAnimations].
  bool get disableAnimations {
    bool value = _accessibilityFeatures.disableAnimations;
    assert(() {
      if (debugSemanticsDisableAnimations != null) {
        value = debugSemanticsDisableAnimations!;
      }
      return true;
    }());
    return value;
  }
}

/// A reference to the semantics tree.
///
/// The framework maintains the semantics tree (used for accessibility and
/// indexing) only when there is at least one client holding an open
/// [SemanticsHandle].
///
/// The framework notifies the client that it has updated the semantics tree by
/// calling the [listener] callback. When the client no longer needs the
/// semantics tree, the client can call [dispose] on the [SemanticsHandle],
/// which stops these callbacks and closes the [SemanticsHandle]. When all the
/// outstanding [SemanticsHandle] objects are closed, the framework stops
/// updating the semantics tree.
///
/// To obtain a [SemanticsHandle], call [PipelineOwner.ensureSemantics] on the
/// [PipelineOwner] for the render tree from which you wish to read semantics.
/// You can obtain the [PipelineOwner] using the [RenderObject.owner] property.
// TODO(window): Update the doc above.
class SemanticsHandle {
  SemanticsHandle._(SemanticsCoordinator coordinator)
      : assert(coordinator != null),
        _coordinator = coordinator;

  final SemanticsCoordinator _coordinator;

  ///
  @mustCallSuper
  void dispose() {
    _coordinator._didDisposeSemanticsHandle();
  }
}

///
class SemanticsCoordinator extends ChangeNotifier {
  SemanticsCoordinator._();

  ///
  bool get enabled => _outstandingHandles > 0;

  ///
  int get debugOutstandingSemanticsHandles => _outstandingHandles;
  int _outstandingHandles = 0;

  ///
  SemanticsHandle ensureSemantics() {
    assert(_outstandingHandles >= 0);
    _outstandingHandles++;
    assert(_outstandingHandles > 0);
    if (_outstandingHandles == 1) {
      notifyListeners();
    }
    return SemanticsHandle._(this);
  }

  void _didDisposeSemanticsHandle() {
    assert(_outstandingHandles > 0);
    _outstandingHandles--;
    assert(_outstandingHandles >= 0);
    if (_outstandingHandles == 0) {
      notifyListeners();
    }
  }
}
