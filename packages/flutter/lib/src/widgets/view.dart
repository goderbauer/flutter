// ignore_for_file: public_member_api_docs

import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'framework.dart';

class View extends StatelessWidget {
  const View({
    super.key,
    required this.view,
    required this.child,
  });

  final FlutterView view;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _View(
      view: view,
      hooks: ViewHooks.of(context),
      child: child,
    );
  }
}

class _View extends SingleChildRenderObjectWidget {
  // TODO(window): consider keying this or View with the provided FlutterView?
  const _View({
    required this.view,
    required this.hooks,
    required super.child,
  });

  final FlutterView view;
  final ViewHooksData hooks;

  @override
  SingleChildRenderObjectElement createElement() => _ViewElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderView(
      view: view,
    );
  }
}

class _ViewElement extends SingleChildRenderObjectElement {
  _ViewElement(super.widget);

  @override
  RenderView get renderObject => super.renderObject as RenderView;

  final PipelineOwner _pipelineOwner = PipelineOwner(
    onNeedVisualUpdate: RendererBinding.instance.ensureVisualUpdate,
  );

  ViewHooksData get hooks => (widget as _View).hooks;

  @override
  void mount(Element? parent, Object? newSlot) {
    assert(() {
      bool noRenderAncestor = parent is! RenderObjectElement;
      parent?.visitAncestorElements((Element ancestor) {
        if (ancestor is RenderObjectElement) {
          noRenderAncestor = false;
          return false;
        }
        return true;
      });
      return noRenderAncestor;
    }());
    hooks.pipelineOwner.adoptChild(_pipelineOwner);
    super.mount(parent, newSlot);
    renderObject.prepareInitialFrame();
    // TODO(goderbauer): semantics.
  }

  @override
  void unmount() {
    hooks.pipelineOwner.dropChild(_pipelineOwner);
    super.unmount();
  }

  @override
  void attachRenderObject(Object? newSlot) {
    assert(_pipelineOwner.rootNode == null);
    _pipelineOwner.rootNode = renderObject;
    hooks.renderViewManager.addRenderView(renderObject);
  }

  @override
  void detachRenderObject() {
    assert(_pipelineOwner.rootNode == renderObject);
    hooks.renderViewManager.removeRenderView(renderObject);
    _pipelineOwner.rootNode = null;
  }

  @override
  void update(_View oldWidget) {
    super.update(oldWidget);
    final ViewHooksData oldHooks = oldWidget.hooks;
    final ViewHooksData newHooks = hooks;
    if (oldHooks.pipelineOwner != newHooks.pipelineOwner) {
      oldHooks.pipelineOwner.dropChild(_pipelineOwner);
      newHooks.pipelineOwner.adoptChild(_pipelineOwner);
    }
    if (oldHooks.renderViewManager != newHooks.renderViewManager) {
      oldHooks.renderViewManager.addRenderView(renderObject);
      newHooks.renderViewManager.removeRenderView(renderObject);
    }
    // TODO(goderbauer): Do we need to mark anything dirty here? Or schedule a frame?
  }
}

class ViewHooks extends InheritedWidget {
  const ViewHooks({
    super.key,
    required this.hooks,
    required super.child,
  });

  static ViewHooksData of(BuildContext context) {
    assert(context != null);
    return context.dependOnInheritedWidgetOfExactType<ViewHooks>()!.hooks;
  }

  final ViewHooksData hooks;

  @override
  bool updateShouldNotify(ViewHooks oldWidget) => hooks != oldWidget.hooks;
}

@immutable
class ViewHooksData {
  const ViewHooksData({required this.renderViewManager, required this.pipelineOwner});

  final RenderViewManager renderViewManager;
  final PipelineOwner pipelineOwner;

  ViewHooksData copyWith({RenderViewManager? renderViewManager, PipelineOwner? pipelineOwner}) {
    assert(renderViewManager != null || pipelineOwner != null);
    return ViewHooksData(
      renderViewManager: renderViewManager ?? this.renderViewManager,
      pipelineOwner: pipelineOwner ?? this.pipelineOwner,
    );
}
  @override
  int get hashCode => Object.hash(renderViewManager, pipelineOwner);

  @override
  bool operator ==(Object other) {
    return other is ViewHooksData
        && renderViewManager == other.renderViewManager
        && pipelineOwner == other.pipelineOwner;
  }
}
