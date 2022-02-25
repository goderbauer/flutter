// ignore_for_file: public_member_api_docs

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
  ViewElement(SingleChildRenderObjectWidget widget) : super(widget) {
    print('creting veiw element');
  }

  @override
  void attachRenderObject(Object? newSlot) {
    // Internationally left empty since RenderView is a root of a render tree
    // and hence has no parent to attach to.
  }
}
