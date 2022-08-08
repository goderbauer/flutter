// ignore_for_file: public_member_api_docs

import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'framework.dart';

class TopLevelView extends SingleChildRenderObjectWidget {
  TopLevelView({
    required this.view,
    required super.child,
  }) : super(
    key: GlobalObjectKey(view),
  );

  final FlutterView view;

  @override
  SingleChildRenderObjectElement createElement() => _TopLevelViewElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderView(
      view: view,
    );
  }
}

class _TopLevelViewElement extends SingleChildRenderObjectElement {
  _TopLevelViewElement(super.widget);

  @override
  RenderView get renderObject => super.renderObject as RenderView;

  final PipelineOwner pipelineOwner = PipelineOwner(
    onNeedVisualUpdate: RendererBinding.instance.ensureVisualUpdate,
  );

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    RendererBinding.instance.rootPipelineOwner.adoptChild(pipelineOwner);
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
