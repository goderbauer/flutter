import 'dart:ui';

import 'package:flutter/material.dart';

import 'framework.dart';

// ignore_for_file: public_member_api_docs

class TwoDViewport extends RenderObjectWidget {
  const TwoDViewport({
    required this.delegate,
  });

  final TwoDViewportDelegate delegate;

  @override
  _TwoDViewportElement createElement() => _TwoDViewportElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    // TODO: implement createRenderObject
    throw UnimplementedError();
  }
}

class _TwoDViewportElement extends RenderObjectElement {
  _TwoDViewportElement(TwoDViewport widget) : super(widget);

  @override
  TwoDViewport get widget => super.widget as TwoDViewport;

  // @override
  // RenderSliverMultiBoxAdaptor get renderObject => super.renderObject as RenderSliverMultiBoxAdaptor;

  @override
  void update(covariant TwoDViewport newWidget) {
    final TwoDViewport oldWidget = widget;
    super.update(newWidget);
    final TwoDViewportDelegate newDelegate = newWidget.delegate;
    final TwoDViewportDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRebuild(oldDelegate)))
      performRebuild();
  }
}

abstract class TwoDViewportDelegate {
  List<Widget> buildChildren(Rect rect);

  bool shouldRebuild(TwoDViewportDelegate oldDelegate) => true;
}

class TestDelegate extends TwoDViewportDelegate {
  final double _height = 10;

  double _m(double d) => d * 10;

  late final Map<Rect, Color> _content = <Rect, Color>{
    Rect.fromLTWH(_m(0), _m(0), _m(3), _height) : Colors.green,
    Rect.fromLTWH(_m(5), _m(0), _m(5), _height) : Colors.blue,
    Rect.fromLTWH(_m(3), _m(2), _m(3), _height) : Colors.yellow,
    Rect.fromLTWH(_m(1), _m(4), _m(2), _height) : Colors.red,
    Rect.fromLTWH(_m(6), _m(5), _m(3), _height) : Colors.pink,
    Rect.fromLTWH(_m(1), _m(7), _m(7), _height) : Colors.green,
    Rect.fromLTWH(_m(5), _m(8), _m(5), _height) : Colors.blue,
  };

  @override
  List<Widget> buildChildren(Rect rect) {
    final Iterable<Rect> childRects = _content.keys.where((Rect element) => element.overlaps(rect));
    return <Widget>[
      for (final Rect childRect in childRects)
        Positioned.fromRect(
          rect: childRect,
          child: Container(color: _content[childRect]),
        ),
    ];
  }
}


