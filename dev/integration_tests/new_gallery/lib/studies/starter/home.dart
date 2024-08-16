// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../gallery_localizations.dart';
import '../../layout/adaptive.dart';

double appBarDesktopHeight = 128.0;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDesktop = isDisplayDesktop(context);
    final GalleryLocalizations localizations = GalleryLocalizations.of(context)!;
    final SafeArea body = SafeArea(
      child: Padding(
        padding: isDesktop
            ? EdgeInsets.symmetric(horizontal: 72, vertical: 48)
            : EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SelectableText(
              localizations.starterAppGenericHeadline,
              style: textTheme.displaySmall!.copyWith(
                color: colorScheme.onSecondary,
              ),
            ),
            SizedBox(height: 10),
            SelectableText(
              localizations.starterAppGenericSubtitle,
              style: textTheme.titleMedium,
            ),
            SizedBox(height: 48),
            SelectableText(
              localizations.starterAppGenericBody,
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        children: <Widget>[
          ListDrawer(),
          VerticalDivider(width: 1),
          Expanded(
            child: Scaffold(
              appBar: AdaptiveAppBar(
                isDesktop: true,
              ),
              body: body,
              floatingActionButton: FloatingActionButton.extended(
                heroTag: 'Extended Add',
                onPressed: () {},
                label: Text(
                  localizations.starterAppGenericButton,
                  style: TextStyle(color: colorScheme.onSecondary),
                ),
                icon: Icon(Icons.add, color: colorScheme.onSecondary),
                tooltip: localizations.starterAppTooltipAdd,
              ),
            ),
          ),
        ],
      );
    } else {
      return Scaffold(
        appBar: AdaptiveAppBar(),
        body: body,
        drawer: ListDrawer(),
        floatingActionButton: FloatingActionButton(
          heroTag: 'Add',
          onPressed: () {},
          tooltip: localizations.starterAppTooltipAdd,
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      );
    }
  }
}

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveAppBar({
    super.key,
    this.isDesktop = false,
  });

  final bool isDesktop;

  @override
  Size get preferredSize => isDesktop
      ? Size.fromHeight(appBarDesktopHeight)
      : Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final GalleryLocalizations localizations = GalleryLocalizations.of(context)!;
    return AppBar(
      automaticallyImplyLeading: !isDesktop,
      title: isDesktop
          ? null
          : SelectableText(localizations.starterAppGenericTitle),
      bottom: isDesktop
          ? PreferredSize(
              preferredSize: Size.fromHeight(26),
              child: Container(
                alignment: AlignmentDirectional.centerStart,
                margin: EdgeInsetsDirectional.fromSTEB(72, 0, 0, 22),
                child: SelectableText(
                  localizations.starterAppGenericTitle,
                  style: themeData.textTheme.titleLarge!.copyWith(
                    color: themeData.colorScheme.onPrimary,
                  ),
                ),
              ),
            )
          : null,
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.share),
          tooltip: localizations.starterAppTooltipShare,
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.favorite),
          tooltip: localizations.starterAppTooltipFavorite,
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.search),
          tooltip: localizations.starterAppTooltipSearch,
          onPressed: () {},
        ),
      ],
    );
  }
}

class ListDrawer extends StatefulWidget {
  const ListDrawer({super.key});

  @override
  State<ListDrawer> createState() => _ListDrawerState();
}

class _ListDrawerState extends State<ListDrawer> {
  static int numItems = 9;

  int selectedItem = 0;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final GalleryLocalizations localizations = GalleryLocalizations.of(context)!;
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: SelectableText(
                localizations.starterAppTitle,
                style: textTheme.titleLarge,
              ),
              subtitle: SelectableText(
                localizations.starterAppGenericSubtitle,
                style: textTheme.bodyMedium,
              ),
            ),
            Divider(),
            ...Iterable<int>.generate(numItems).toList().map((int i) {
              return ListTile(
                selected: i == selectedItem,
                leading: Icon(Icons.favorite),
                title: Text(
                  localizations.starterAppDrawerItem(i + 1),
                ),
                onTap: () {
                  setState(() {
                    selectedItem = i;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
