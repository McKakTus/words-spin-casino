import 'package:casinowordsspin/crash_and_usage/crash_and_usage_check.dart';
import 'package:casinowordsspin/crash_and_usage/crash_and_usage_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CrashAndUsageWebView extends StatefulWidget {
  const CrashAndUsageWebView({super.key});

  @override
  State<CrashAndUsageWebView> createState() => _CrashAndUsageWebViewState();
}

class _CrashAndUsageWebViewState extends State<CrashAndUsageWebView> {
  late InAppWebViewController webViewController;

  bool showLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: showLoading ? 0 : 1,

          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(crashAndUsageLink!),
                      ),
                      initialSettings: InAppWebViewSettings(
                        allowsBackForwardNavigationGestures: false,
                        javaScriptEnabled: true,
                      ),
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      onLoadStop: (controller, url) async {
                        showLoading = false;
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: OrientationBuilder(
              builder: (BuildContext context, Orientation orientation) {
                return buildWebBottomBar(orientation);
              },
            ),
          ),
        ),
        if (showLoading) const CrashAndUsageSplash(),
      ],
    );
  }

  Widget buildWebBottomBar(Orientation orientation) {
    return Container(
      color: Colors.black,
      height: orientation == Orientation.portrait ? 25 : 30,
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            color: Colors.white,
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await webViewController.canGoBack()) {
                webViewController.goBack();
              }
            },
          ),
          const SizedBox.shrink(),
          IconButton(
            padding: EdgeInsets.zero,
            color: Colors.white,
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async {
              if (await webViewController.canGoForward()) {
                webViewController.goForward();
              }
            },
          ),
        ],
      ),
    );
  }
}
