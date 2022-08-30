// ignore_for_file: public_member_api_docs

import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
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

  static Object viewSlot = Object();

  final FlutterView view;
  final Widget child;

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  // Pulled out of _ViewElement so we can configure ViewScope.
  late final PipelineOwner _pipelineOwner = PipelineOwner(
    onSemanticsUpdate: _handleSemanticsUpdate,
  );

  late ViewHooks _ancestorHooks;
  late ViewHooks _descendantHooks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ancestorHooks = ViewHooks.of(context);
    _descendantHooks = _ancestorHooks.copyWith(pipelineOwner: _pipelineOwner);
  }

  void _handleSemanticsUpdate(SemanticsUpdate update) {
    widget.view.updateSemantics(update);
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
  // global keying would also mean that there can only be one view widget attached to a view in the tree, which would be good.
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
    assert(newSlot == View.viewSlot);
    final _View viewWidget = widget as _View;
    viewWidget.hooks.pipelineOwner.adoptChild(viewWidget.pipelineOwner);
    super.mount(parent, newSlot); // calls attachRenderObject().
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
    assert(newSlot == View.viewSlot);
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
    // TODO(goderbauer): Do we need to mark anything dirty here? Or schedule a frame? Probably no because we are in the middle of doing a frame.
  }
}

// TODO(goderbauer): consider an InheritedModel?
//   Or break up into two separate InheritedWidget for hooks and views
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

// TODO(window): Check that proper error is thrown when ViewStages.children or
//   SideViewStages.sideStages want to attach render object to parent.

abstract class _BaseStageManager extends Widget {
  const _BaseStageManager({super.key, required List<Widget> stages, Widget? child}) : _stages = stages, _child = child;

  // It is up to the subclasses to make the relevant properties public.
  final Widget? _child;
  final List<Widget> _stages;

  @override
  Element createElement() => _StageManagerElement(this);
}

class StageManager extends _BaseStageManager {
  const StageManager({super.key, required super.stages}) : assert(stages.length > 0);

  List<Widget> get stages => _stages;
}

class SideStageManager extends StatelessWidget {
  const SideStageManager({super.key, required this.stages, required this.child});

  final Widget child;
  final List<Widget> stages;

  @override
  Widget build(BuildContext context) {
    final ViewHooks hooks = ViewHooks.of(context);
    return _SideStageManager(
      stages: stages.map((Widget stage) => ViewScope(hooks: hooks, child: stage)).toList(),
      child: child,
    );
  }
}

class _SideStageManager extends _BaseStageManager {
  const _SideStageManager({required super.stages, required Widget super.child});

  List<Widget> get stages => _stages;
  Widget get child => _child!;
}

// This element has the makings of a MultiChildComponentElement (i.e. a
// ComponentElement that can manage more then one child, similar to
// MultiChildRenderObjectElement vs. RenderObjectElement). In theory, this
// functionality could be factored out into a (reusable)
// MultiChildComponentElement, but it is not clear what one would reuse this
// for. So, for the time being, Flutter does not offer a public
// MultiChildComponentElement.
class _StageManagerElement extends Element {
  _StageManagerElement(super.widget);

  List<Element> _stageElements = <Element>[];
  final Set<Element> _forgottenStageElements = HashSet<Element>();

  // This is always null for the [StageManager] and always non-null for the [SideStageManager].
  Element? _childElement;

  bool _debugAssertChildren() {
    // Each stage widget must have a corresponding element.
    assert(_stageElements.length == (widget as _BaseStageManager)._stages.length);
    // Iff there is a child widget, it must have a corresponding element.
    assert((_childElement == null) == ((widget as _BaseStageManager)._child == null));
    // The child element is not also a stage element.
    assert(!_stageElements.contains(_childElement));
    return true;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    assert(_stageElements.isEmpty);
    assert(_childElement == null);
    rebuild();
    assert(_debugAssertChildren());
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    rebuild(force: true);
    assert(_debugAssertChildren());
  }

  @override
  void performRebuild() {
    _childElement = updateChild(_childElement, (widget as _BaseStageManager)._child, slot);

    final List<Widget> stages = (widget as _BaseStageManager)._stages;
    _stageElements = updateChildren(
      _stageElements,
      stages,
      forgottenChildren: _forgottenStageElements,
      slots: List<Object>.generate(stages.length, (_) => View.viewSlot),
    );
    _forgottenStageElements.clear();

    super.performRebuild(); // clears the dirty flag
    assert(_debugAssertChildren());
  }

  @override
  void forgetChild(Element child) {
    if (child == _childElement) {
      _childElement = null;
    } else {
      assert(_stageElements.contains(child));
      assert(!_forgottenStageElements.contains(child));
      _forgottenStageElements.add(child);
    }
    super.forgetChild(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_childElement != null) {
      visitor(_childElement!);
    }
    for (final Element child in _stageElements) {
      if (!_forgottenStageElements.contains(child)) {
        visitor(child);
      }
    }
  }

  @override
  bool get debugDoingBuild => false; // This element does not have a concept of "building".

  @override
  // TODO(window): Update documentation.
  RenderObject? get renderObject {
    // If we don't have a _childElement (i.e. we are a [StageManager]) this
    // returns null on purpose because nothing above this element has an
    // associated render object. (The render tree starts with a [View] and
    // [StageManager] is there to create multiple stages for views.)
    return _childElement?.renderObject;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    String childName = 'stage';
    if (_childElement != null) {
      children.add(_childElement!.toDiagnosticsNode());
      childName = 'sidestage';
    }
    for (int i = 0; i < _stageElements.length; i++) {
      children.add(_stageElements[i].toDiagnosticsNode(
        name: '$childName ${i + 1}',
        style: DiagnosticsTreeStyle.offstage,
      ));
    }
    return children;
  }
}
