// ignore_for_file: public_member_api_docs

import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'framework.dart';

class View extends SingleChildRenderObjectWidget {
  const View({
    super.key,
    required this.view,
    required super.child,
  }) : super(
    // key: GlobalObjectKey(view),
  );

  final FlutterView view;

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

  final PipelineOwner pipelineOwner = PipelineOwner(
    onNeedVisualUpdate: RendererBinding.instance.ensureVisualUpdate,
  );

  @override
  void mount(Element? parent, Object? newSlot) {
    // TODO(window): Assert that we're the start of a render tree.
    RendererBinding.instance.rootPipelineOwner.adoptChild(pipelineOwner);
    super.mount(parent, newSlot);
    renderObject.prepareInitialFrame();
  }

  @override
  void unmount() {
    RendererBinding.instance.rootPipelineOwner.dropChild(pipelineOwner);
    super.unmount();
  }

  @override
  void attachRenderObject(Object? newSlot) {
    assert(pipelineOwner.rootNode == null);
    pipelineOwner.rootNode = renderObject;
    RendererBinding.instance.addRenderView(renderObject);
  }

  @override
  void detachRenderObject() {
    assert(pipelineOwner.rootNode == renderObject);
    RendererBinding.instance.removeRenderView(renderObject);
    pipelineOwner.rootNode = null;
  }
}
