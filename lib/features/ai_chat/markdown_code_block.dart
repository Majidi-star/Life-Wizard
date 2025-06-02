import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Custom code block builder with copy button
class CodeBlockBuilder extends MarkdownElementBuilder {
  final ThemeData theme;

  CodeBlockBuilder(this.theme);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String language =
        element.attributes['class']?.replaceFirst('language-', '') ?? '';
    final String content = element.textContent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    language,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      final scaffoldContext = _findScaffoldMessengerContext();
                      if (scaffoldContext != null) {
                        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    tooltip: 'Copy to clipboard',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to find the nearest ScaffoldMessenger context
  BuildContext? _findScaffoldMessengerContext() {
    // Store the most recently used context
    BuildContext? context;

    // Listen for SnackBar notifications
    final GlobalKey<ScaffoldMessengerState> key =
        GlobalKey<ScaffoldMessengerState>();

    // Try to get the context from the global key
    try {
      context = key.currentContext;
      if (context != null) {
        return context;
      }
    } catch (e) {
      // Ignore error
    }

    // If we couldn't find a context, use a simple global key approach
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    try {
      context = navigatorKey.currentContext;
      return context;
    } catch (e) {
      // Ignore error
    }

    return null;
  }
}
