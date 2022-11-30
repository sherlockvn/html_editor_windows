import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/parsing.dart';
import 'package:webview_windows/webview_windows.dart';

class HtmlEditor extends StatefulWidget {
  HtmlEditor({
    Key? key, 
    this.initialContent = """
    <!DOCTYPE html>
    <html contenteditable="true"></html>
    """,
    this.width = 640,
    this.height = 480,
    this.backgroundColor = Colors.transparent,
  }): super(key: key);

  /// Set the [initialContent] to populate the editor with some existing text
  final String initialContent;

  final double width;

  final double height;

  final Color backgroundColor;

  @override
  State<StatefulWidget> createState() => _HtmlEditorState();
}

class _HtmlEditorState extends State<HtmlEditor> {
  final _controller = WebviewController();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(widget.backgroundColor);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadStringContent(toEditableHtmlContent(widget.initialContent));
      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('Error'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${e.code}'),
                      Text('Message: ${e.message}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Continue'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ));
      });
    }
  }

  String toEditableHtmlContent(String htmlContent) {
    final htmlDocument = parseHtmlDocument(htmlContent);
    final htmlElement = htmlDocument.querySelector('html');
    htmlElement?.attributes['contenteditable'] = 'true';
    return htmlElement?.outerHtml ?? htmlContent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: ValueNotifier(_controller.value.isInitialized), 
        builder: (_, bool isInitialized, __) {
          return isInitialized ? Webview(
            _controller,
            width: widget.width,
            height: widget.height
          ) : const LinearProgressIndicator();
        }
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

}