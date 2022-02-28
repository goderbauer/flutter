// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

class View extends SingleChildRenderObjectWidget {
  View({
    required this.renderView,
    required Widget child,
  }) : super(
          key: GlobalObjectKey(renderView),
          child: child,
        );

  final RenderView renderView;

  @override
  SingleChildRenderObjectElement createElement() => ViewElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) => renderView;
}

class ViewElement extends SingleChildRenderObjectElement {
  ViewElement(SingleChildRenderObjectWidget widget) : super(widget);

  @override
  void attachRenderObject(Object? newSlot) {
    // assert that we don't have a parent to attach to?
    visitChildren((Element child) {
      child.attachRenderObject(null);
    });
  }

  @override
  void detachRenderObject() {
    visitChildren((Element child) {
      child.detachRenderObject();
    });
  }
}
