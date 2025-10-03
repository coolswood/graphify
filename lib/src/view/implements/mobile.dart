import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graphify/src/controller/implements/mobile.dart';
import 'package:graphify/src/resources/dependencies.js.dart';
import 'package:graphify/src/resources/index.html.dart';
import 'package:graphify/src/view/_interface.dart' as g_view;
import 'package:webview_flutter/webview_flutter.dart';

const _consoleChannelName = 'GraphifyConsole';

class GraphifyView extends g_view.GraphifyView {
  const GraphifyView({
    super.key,
    super.controller,
    super.initialOptions,
    super.onConsoleMessage,
    super.onCreated,
  });

  @override
  State<StatefulWidget> createState() => _GraphifyViewState();
}

class _GraphifyViewState extends g_view.GraphifyViewState<GraphifyView> {

  late final webViewController = WebViewController();
  late final controller =
      (widget.controller ?? GraphifyController()) as GraphifyController;

  @override
  void initView() {
    controller.connector = webViewController;

    webViewController
      ..addJavaScriptChannel(
        _consoleChannelName,
        onMessageReceived: (message) {
          _dispatchConsole(_parseConsolePayload(message.message));
        },
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setOnConsoleMessage((consoleMessage) {
        final level = consoleMessage.level.toString().split('.').last;
        _dispatchConsole({
          'source': 'webview',
          'level': level,
          'message': consoleMessage.message,
        });
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            widget.onCreated?.call();
            controller.update(widget.initialOptions);
          },
        ),
      );

    loadDependencies().then((deps) {
      if (!mounted) return;
      webViewController.loadHtmlString(
        indexHtml(
          id: controller.uid,
          dependencies: '<script>$deps</script>',
        ),
      );
    });
  }

  void _dispatchConsole(Object message) {
    final handler = widget.onConsoleMessage;
    if (handler != null) {
      handler(message);
    }
  }

  Object _parseConsolePayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget buildView() {
    return view = WebViewWidget(controller: webViewController);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      controller.dispose();
    }
    webViewController
      ..clearLocalStorage()
      ..clearCache();
    super.dispose();
  }
}
