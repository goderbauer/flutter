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
      if (newSlot == View.viewSlot) {
        return true;
      }
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

// TODO(window): CHeck that proper error is thrown when ViewStages.children or
//   SideViewStages.sideStages want to attach render object to parent.

class ViewStages extends MultiChildComponentWidget {
  const ViewStages({
    super.key,
    required super.children,
  }) : assert(children.length > 0);

  @override
  MultiChildComponentElement createElement() => MultiChildComponentElement(this);
}

// TODO(window): Move MultiChildComponentWidget and MultiChildComponentElement to framework.dart.
//   On second thought: the slot thing may make this too specific.
abstract class MultiChildComponentWidget extends Widget {
  const MultiChildComponentWidget({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  MultiChildComponentElement createElement();
}

class MultiChildComponentElement extends Element {
  MultiChildComponentElement(super.widget);

  List<Element> _children = <Element>[];
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    assert(_children.isEmpty);
    rebuild();
    assert(_children.length == (widget as MultiChildComponentWidget).children.length);
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    rebuild(force: true);
    assert(_children.length == (widget as MultiChildComponentWidget).children.length);
  }

  @override
  void performRebuild() {
    final List<Widget> children = (widget as MultiChildComponentWidget).children;
    // TODO(goderbauer): slot treatment...
    _children = updateChildren(_children, children, forgottenChildren: _forgottenChildren, slots: List<Object>.generate(children.length, (_) => View.viewSlot));
    _forgottenChildren.clear();
    super.performRebuild(); // clears the dirty flag
  }

  @override
  void forgetChild(Element child) {
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
    super.forgetChild(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final Element child in _children) {
      if (!_forgottenChildren.contains(child)) {
        visitor(child);
      }
    }
  }

  @override
  bool get debugDoingBuild => false; // This element does not have a concept of "building".

  @override
  // TODO(window): Update documentation.
  RenderObject? get renderObject {
    // Nothing above this widget has an associated render object.
    return null;
  }
}

// Acts like a ProxyWidget for [child] and like a [ViewStages] for sideViews.
class ViewSideStages extends MultiChildComponentWidget {
  const ViewSideStages({
    super.key,
    required this.child,
    List<Widget> sideViews = const <Widget>[],
  }) : super(children: sideViews);

  final Widget child;
  List<Widget> get sideViews => children;

  @override
  MultiChildComponentElement createElement() => _ViewSideStagesElement(this);
}

class _ViewSideStagesElement extends MultiChildComponentElement {
  _ViewSideStagesElement(super.widget);

  Element? _child;

  @override
  void mount(Element? parent, Object? newSlot) {
    assert(_child == null);
    super.mount(parent, newSlot);
    assert(_child != null);
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    assert(_child != null);
  }

  @override
  void performRebuild() {
    _child = updateChild(_child, (widget as ViewSideStages).child, slot);
    super.performRebuild();
  }

  @override
  void forgetChild(Element child) {
    if (child == _child) {
      _child = null;
    }
    super.forgetChild(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
    super.visitChildren(visitor);
  }

  @override
  RenderObject? get renderObject {
    return _child?.renderObject;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[
      if (_child != null)
        _child!.toDiagnosticsNode(),
    ];
    super.visitChildren((Element child) {
      children.add(child.toDiagnosticsNode(
        name: 'sidestage',
        style: DiagnosticsTreeStyle.offstage,
      ));
    });
    return children;
  }
}
