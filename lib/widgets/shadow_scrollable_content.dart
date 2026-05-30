import 'package:flutter/material.dart';

class ShadowScrollableContent extends StatelessWidget {
  const ShadowScrollableContent({
    super.key,
    required this.child,
    this.centerContent = true,
  });

  final Widget child;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: centerContent
                  ? Center(
                child: child,
              )
                  : child,
            ),
          );
        },
      ),
    );
  }
}