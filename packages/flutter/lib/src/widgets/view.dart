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

  static FlutterView of(BuildContext context) {
    return maybeOf(context)!;
  }

  static FlutterView? maybeOf(BuildContext context) {
    assert(context != null);
    return context.dependOnInheritedWidgetOfExactType<ViewScope>()!.view;
  }

  final FlutterView view;
  final Widget child;

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  // Pulled out of _ViewElement so we can configure ViewScope.
  final PipelineOwner _pipelineOwner = PipelineOwner();

  late ViewHooks _ancestorHooks;
  late ViewHooks _descendantHooks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ancestorHooks = ViewHooks.of(context);
    _descendantHooks = _ancestorHooks.copyWith(pipelineOwner: _pipelineOwner);
  }

  @override
  Widget build(BuildContext context) {
    return _View(
      view: widget.view,
      hooks: _ancestorHooks,
      pipelineOwner: _pipelineOwner,
      child: ViewScope(
        view: widget.view,
        hooks: _descendantHooks,
        child: widget.child,
      ),
    );
  }
}

class _View extends SingleChildRenderObjectWidget {
  // TODO(window): consider keying this or View with the provided FlutterView? Or implement updateRenderObject for changing views.
  const _View({
    required this.view,
    required this.hooks,
    required this.pipelineOwner,
    required super.child,
  });

  final FlutterView view;
  final ViewHooks hooks;
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
    final _View viewWidget = widget as _View;
    viewWidget.hooks.pipelineOwner.adoptChild(viewWidget.pipelineOwner);
    super.mount(parent, newSlot);
    renderObject.prepareInitialFrame();
    // TODO(goderbauer): semantics.
  }

  @override
  void unmount() {
    final _View viewWidget = widget as _View;
    viewWidget.hooks.pipelineOwner.dropChild(viewWidget.pipelineOwner);
    super.unmount();
  }

  @override
  void attachRenderObject(Object? newSlot) {
    final _View viewWidget = widget as _View;
    assert(viewWidget.pipelineOwner.rootNode == null);
    viewWidget.pipelineOwner.rootNode = renderObject;
    viewWidget.hooks.renderViewManager.addRenderView(renderObject);
  }

  @override
  void detachRenderObject() {
    final _View viewWidget = widget as _View;
    assert(viewWidget.pipelineOwner.rootNode == renderObject);
    viewWidget.hooks.renderViewManager.removeRenderView(renderObject);
    viewWidget.pipelineOwner.rootNode = null;
  }

  @override
  void update(_View oldWidget) {
    super.update(oldWidget);
    final _View viewWidget = widget as _View;
    assert(oldWidget.pipelineOwner == viewWidget.pipelineOwner);
    final ViewHooks oldHooks = oldWidget.hooks;
    final ViewHooks newHooks = viewWidget.hooks;
    if (oldHooks.pipelineOwner != newHooks.pipelineOwner) {
      oldHooks.pipelineOwner.dropChild(viewWidget.pipelineOwner);
      newHooks.pipelineOwner.adoptChild(viewWidget.pipelineOwner);
    }
    if (oldHooks.renderViewManager != newHooks.renderViewManager) {
      oldHooks.renderViewManager.addRenderView(renderObject);
      newHooks.renderViewManager.removeRenderView(renderObject);
    }
    // TODO(goderbauer): Do we need to mark anything dirty here? Or schedule a frame? Probably no.
  }
}

// TODO(goderbauer): consider an InheritedModel?
class ViewScope extends InheritedWidget {
  const ViewScope({
    super.key,
    this.view,
    required this.hooks,
    required super.child,
  });

  final FlutterView? view;
  final ViewHooks hooks;

  @override
  bool updateShouldNotify(ViewScope oldWidget) => view != oldWidget.view || hooks != oldWidget.hooks;
}

@immutable
class ViewHooks {
  const ViewHooks({
    required this.renderViewManager,
    required this.pipelineOwner,
  });

  static ViewHooks of(BuildContext context) {
    assert(context != null);
    return context.dependOnInheritedWidgetOfExactType<ViewScope>()!.hooks;
  }

  final RenderViewManager renderViewManager;
  final PipelineOwner pipelineOwner;

  ViewHooks copyWith({
    RenderViewManager? renderViewManager,
    PipelineOwner? pipelineOwner,
  }) {
    assert(renderViewManager != null || pipelineOwner != null);
    return ViewHooks(
      renderViewManager: renderViewManager ?? this.renderViewManager,
      pipelineOwner: pipelineOwner ?? this.pipelineOwner,
    );
  }

  @override
  int get hashCode => Object.hash(renderViewManager, pipelineOwner);

  @override
  bool operator ==(Object other) {
    return other is ViewHooks
        && renderViewManager == other.renderViewManager
        && pipelineOwner == other.pipelineOwner;
  }
}
