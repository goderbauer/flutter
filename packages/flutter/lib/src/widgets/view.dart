// ignore_for_file: public_member_api_docs

import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

class View extends SingleChildRenderObjectWidget {
  View({
    required this.view,
    required Widget child,
  }) : super(
          key: GlobalObjectKey(view),
          child: child,
        );

  final FlutterView view;

  @override
  SingleChildRenderObjectElement createElement() => _ViewElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    final double devicePixelRatio = view.devicePixelRatio;
    // TODO(goderbauer): Handle config updates.
    return RenderView(
      window: view,
      configuration: ViewConfiguration(
        size: view.physicalSize / devicePixelRatio,
        devicePixelRatio: devicePixelRatio,
      ),
    );
  }
}

class _ViewElement extends SingleChildRenderObjectElement {
  _ViewElement(SingleChildRenderObjectWidget widget) : super(widget);

  @override
  RenderView get renderObject => super.renderObject as RenderView;

  final PipelineOwner pipelineOwner = PipelineOwner(
    onNeedVisualUpdate: RendererBinding.instance.ensureVisualUpdate,
  );

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    RendererBinding.instance.addPipelineOwner(pipelineOwner, renderObject.compositeFrame);
    renderObject.prepareInitialFrame();
  }

  @override
  void unmount() {
    RendererBinding.instance.removePipelineOwner(pipelineOwner);
    super.unmount();
  }

  @override
  void attachRenderObject(Object? newSlot) {
    assert(pipelineOwner.rootNode == null);
    pipelineOwner.rootNode = renderObject;
    print('attach ${describeIdentity(this)}');
  }

  @override
  void detachRenderObject() {
    assert(pipelineOwner.rootNode == renderObject);
    pipelineOwner.rootNode = null;
    print('detach ${describeIdentity(this)}');
  }
}

// TODO(goderbauer): naming is hard.
class Collection extends Widget {
  const Collection({Key? key, required this.children}) : super(key: key);

  final List<Widget> children;

  @override
  Element createElement() => MultiChildComponentElement(this);
}

class MultiChildComponentElement extends Element {
  MultiChildComponentElement(Widget widget) : super(widget);

  List<Element> _children = <Element>[];
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    assert(_children.isEmpty);
    _updateChildren();
  }

  @override
  bool get debugDoingBuild => false;

  void _updateChildren() {
    _children = updateChildren(_children, (widget as Collection).children, forgottenChildren: _forgottenChildren);
    _forgottenChildren.clear();
    assert(_children.length == (widget as Collection).children.length);
  }

  @override
  void performRebuild() {
    // nothing to do here?
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    _updateChildren();
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final Element child in _children) {
      if (!_forgottenChildren.contains(child))
        visitor(child);
    }
  }

  @override
  RenderObject? get renderObject {
    // TODO(goderbauer): there are multiple renderObjects here.
    return null;
  }

  @override
  void forgetChild(Element child) {
    assert(_children.contains(child));
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
    super.forgetChild(child);
  }
}
