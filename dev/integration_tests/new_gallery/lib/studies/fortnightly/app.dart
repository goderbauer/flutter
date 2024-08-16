// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../data/gallery_options.dart';
import '../../gallery_localizations.dart';
import '../../layout/adaptive.dart';
import '../../layout/image_placeholder.dart';
import '../../layout/text_scale.dart';
import 'routes.dart' as routes;
import 'shared.dart';

String _fortnightlyTitle = 'Fortnightly';

class FortnightlyApp extends StatelessWidget {
  const FortnightlyApp({super.key});

  static String defaultRoute = routes.defaultRoute;

  @override
  Widget build(BuildContext context) {
    final StatelessWidget home = isDisplayDesktop(context)
        ? _FortnightlyHomeDesktop()
        : _FortnightlyHomeMobile();
    return MaterialApp(
      restorationScopeId: 'fortnightly_app',
      title: _fortnightlyTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(context).copyWith(
        platform: GalleryOptions.of(context).platform,
      ),
      home: ApplyTextOptions(child: home),
      routes: <String, WidgetBuilder>{
        FortnightlyApp.defaultRoute: (BuildContext context) => ApplyTextOptions(child: home),
      },
      initialRoute: FortnightlyApp.defaultRoute,
      // L10n settings.
      localizationsDelegates: GalleryLocalizations.localizationsDelegates,
      supportedLocales: GalleryLocalizations.supportedLocales,
      locale: GalleryOptions.of(context).locale,
    );
  }
}

class _FortnightlyHomeMobile extends StatelessWidget {
  const _FortnightlyHomeMobile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: NavigationMenu(isCloseable: true),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Semantics(
          label: _fortnightlyTitle,
          child: FadeInImagePlaceholder(
            image: AssetImage(
              'fortnightly/fortnightly_title.png',
              package: 'flutter_gallery_assets',
            ),
            placeholder: SizedBox.shrink(),
            excludeFromSemantics: true,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            tooltip: GalleryLocalizations.of(context)!.shrineTooltipSearch,
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          restorationId: 'list_view',
          children: <Widget>[
            HashtagBar(),
            for (final Widget item in buildArticlePreviewItems(context))
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: item,
              ),
          ],
        ),
      ),
    );
  }
}

class _FortnightlyHomeDesktop extends StatelessWidget {
  const _FortnightlyHomeDesktop();

  @override
  Widget build(BuildContext context) {
    final double menuWidth = 200.0;
    final SizedBox spacer = SizedBox(width: 20);
    final double headerHeight = 40 * reducedTextScale(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: headerHeight,
              child: Row(
                children: <Widget>[
                  Container(
                    width: menuWidth,
                    alignment: AlignmentDirectional.centerStart,
                    margin: EdgeInsets.only(left: 12),
                    child: Semantics(
                      label: _fortnightlyTitle,
                      child: Image.asset(
                        'fortnightly/fortnightly_title.png',
                        package: 'flutter_gallery_assets',
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  spacer,
                  Flexible(
                    flex: 2,
                    child: HashtagBar(),
                  ),
                  spacer,
                  Flexible(
                    fit: FlexFit.tight,
                    child: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        icon: Icon(Icons.search),
                        tooltip: GalleryLocalizations.of(context)!
                            .shrineTooltipSearch,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: menuWidth,
                    child: NavigationMenu(),
                  ),
                  spacer,
                  Flexible(
                    flex: 2,
                    child: ListView(
                      children: buildArticlePreviewItems(context),
                    ),
                  ),
                  spacer,
                  Flexible(
                    fit: FlexFit.tight,
                    child: ListView(
                      children: <Widget>[
                        ...buildStockItems(context),
                        SizedBox(height: 32),
                        ...buildVideoPreviewItems(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
