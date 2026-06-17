import 'dart:async';

import 'package:flutter/material.dart';

class TransientSystemMessageCard extends StatefulWidget {
  const TransientSystemMessageCard({
    super.key,
    required this.message,
    required this.timestamp,
    this.backgroundColor = const Color(0xFF221229),
    this.textColor = Colors.white70,
    this.icon = Icons.campaign,
    this.iconColor = const Color(0xFFE7C76F),
    this.duration = const Duration(seconds: 3),
  });

  final String message;
  final DateTime? timestamp;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final Duration duration;

  @override
  State<TransientSystemMessageCard> createState() =>
      _TransientSystemMessageCardState();
}

class _TransientSystemMessageCardState extends State<TransientSystemMessageCard> {
  Timer? _hideTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _scheduleVisibility();
  }

  @override
  void didUpdateWidget(covariant TransientSystemMessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.message != widget.message ||
        oldWidget.timestamp != widget.timestamp) {
      _scheduleVisibility();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleVisibility() {
    _hideTimer?.cancel();

    final timestamp = widget.timestamp;

    if (timestamp == null) {
      setState(() {
        _visible = true;
      });
      return;
    }

    final visibleUntil = timestamp.add(widget.duration);
    final remaining = visibleUntil.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      setState(() {
        _visible = false;
      });
      return;
    }

    setState(() {
      _visible = true;
    });

    _hideTimer = Timer(remaining, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _visible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    return Card(
      color: widget.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(widget.icon, color: widget.iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(color: widget.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
