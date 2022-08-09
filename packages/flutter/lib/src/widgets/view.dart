// ignore_for_file: public_member_api_docs

import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'framework.dart';

class View extends StatefulWidget {
  const View({
    super.key,
    required this.view,
    required this.child,
  });

  final FlutterView view;
  final Widget child;

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  // Pulled out of _ViewElement so we can configure ViewHooks.
  final PipelineOwner _pipelineOwner = PipelineOwner(
    // TODO(goderbauer): This static access is annoying. Grab it from ViewHooks.pipelineOwner? How about updating it?
    // Alternative: Adopt child could copy it from its parent if it is null.
    onNeedVisualUpdate: RendererBinding.instance.ensureVisualUpdate,
  );

  @override
  Widget build(BuildContext context) {
    final ViewHooksData hooks = ViewHooks.of(context);
    return _View(
      view: widget.view,
      hooks: hooks,
      pipelineOwner: _pipelineOwner,
      child: ViewHooks(
        hooks: hooks.copyWith(pipelineOwner: _pipelineOwner),
        child: widget.child,
      ),
    );
  }
}

class _View extends SingleChildRenderObjectWidget {
  // TODO(window): consider keying this or View with the provided FlutterView?
  const _View({
    required this.view,
    required this.hooks,
    required this.pipelineOwner,
    required super.child,
  });

  final FlutterView view;
  final ViewHooksData hooks;
  final PipelineOwner pipelineOwner;

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

  // TODO(goderbauer): inline these casts.
  ViewHooksData get _hooks => (widget as _View).hooks;
  PipelineOwner get _pipelineOwner => (widget as _View).pipelineOwner;

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
    _hooks.pipelineOwner.adoptChild(_pipelineOwner);
    super.mount(parent, newSlot);
    renderObject.prepareInitialFrame();
    // TODO(goderbauer): semantics.
  }

  @override
  void unmount() {
    _hooks.pipelineOwner.dropChild(_pipelineOwner);
    super.unmount();
  }

  @override
  void attachRenderObject(Object? newSlot) {
    assert(_pipelineOwner.rootNode == null);
    _pipelineOwner.rootNode = renderObject;
    _hooks.renderViewManager.addRenderView(renderObject);
  }

  @override
  void detachRenderObject() {
    assert(_pipelineOwner.rootNode == renderObject);
    _hooks.renderViewManager.removeRenderView(renderObject);
    _pipelineOwner.rootNode = null;
  }

  @override
  void update(_View oldWidget) {
    super.update(oldWidget);
    assert(oldWidget.pipelineOwner == _pipelineOwner);
    final ViewHooksData oldHooks = oldWidget.hooks;
    final ViewHooksData newHooks = _hooks;
    if (oldHooks.pipelineOwner != newHooks.pipelineOwner) {
      oldHooks.pipelineOwner.dropChild(_pipelineOwner);
      newHooks.pipelineOwner.adoptChild(_pipelineOwner);
    }
    if (oldHooks.renderViewManager != newHooks.renderViewManager) {
      oldHooks.renderViewManager.addRenderView(renderObject);
      newHooks.renderViewManager.removeRenderView(renderObject);
    }
    // TODO(goderbauer): Do we need to mark anything dirty here? Or schedule a frame? Probably no.
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
