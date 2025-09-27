import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SafeWebView extends StatefulWidget {
  final String? url;
  const SafeWebView({Key? key, this.url}) : super(key: key);

  @override
  State<SafeWebView> createState() => _SafeWebViewState();
}

class _SafeWebViewState extends State<SafeWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url ?? "https://flutter.dev"));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WebViewWidget(controller: _controller),
    );
  }
}
