// ignore_for_file: public_member_api_docs

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

class View extends StatefulWidget {
  const View({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  late final PipelineOwner pipelineOwner;

  late final RenderView renderView;

  @override
  void initState() {
    super.initState();
    // TODO(goderbauer): create a new backing view instead of hardcoding it here.
    final FlutterView view = RendererBinding.instance.window;

    final double devicePixelRatio = window.devicePixelRatio;
    renderView = RenderView(window: view, configuration: ViewConfiguration(
      size: window.physicalSize / devicePixelRatio,
      devicePixelRatio: devicePixelRatio,
    ));
    pipelineOwner.rootNode = renderView;

    pipelineOwner = PipelineOwner(
      onNeedVisualUpdate: RendererBinding.instance.ensureVisualUpdate,
      onCompositeFrame: renderView.compositeFrame,
    );

    RendererBinding.instance.addPipelineOwner(pipelineOwner);
    renderView.prepareInitialFrame();
  }

  @override
  void dispose() {
    RendererBinding.instance.removePipelineOwner(pipelineOwner);
    pipelineOwner.rootNode = null;
    renderView.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _View(
      renderView: renderView,
      pipelineOwner: pipelineOwner,
      child: widget.child,
    );
  }
}

class _View extends SingleChildRenderObjectWidget {
  _View({
    required this.renderView,
    required this.pipelineOwner,
    required Widget child,
  }) : super(
          key: GlobalObjectKey(renderView),
          child: child,
        );

  final RenderView renderView;
  final PipelineOwner pipelineOwner;

  @override
  SingleChildRenderObjectElement createElement() => _ViewElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) => renderView;
}

class _ViewElement extends SingleChildRenderObjectElement {
  _ViewElement(SingleChildRenderObjectWidget widget) : super(widget);

  @override
  void attachRenderObject(Object? newSlot) {
    final _View widget = this.widget as _View;
    // TODO(goderbauer): the second part shouldn't exist.
    assert(widget.pipelineOwner.rootNode == null || widget.pipelineOwner.rootNode == widget.renderView);
    widget.pipelineOwner.rootNode = widget.renderView;
    print('attach ${describeIdentity(this)}');
  }

  @override
  void detachRenderObject() {
    final _View widget = this.widget as _View;
    assert(widget.pipelineOwner.rootNode == widget.renderView);
    widget.pipelineOwner.rootNode = null;
    print('detach ${describeIdentity(this)}');
  }
}
