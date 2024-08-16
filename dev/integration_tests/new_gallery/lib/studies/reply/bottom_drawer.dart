// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'colors.dart';

class BottomDrawer extends StatelessWidget {
  const BottomDrawer({
    super.key,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    required this.leading,
    required this.trailing,
  });

  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: Material(
        color: theme.bottomSheetTheme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: ListView(
          padding: EdgeInsets.all(12),
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: 28),
            leading,
            SizedBox(height: 8),
            Divider(
              color: ReplyColors.blue200,
              thickness: 0.25,
              indent: 18,
              endIndent: 160,
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 18),
              child: Text(
                'FOLDERS',
                style: theme.textTheme.bodySmall!.copyWith(
                  color:
                      theme.navigationRailTheme.unselectedLabelTextStyle!.color,
                ),
              ),
            ),
            SizedBox(height: 4),
            trailing,
          ],
        ),
      ),
    );
  }
}
