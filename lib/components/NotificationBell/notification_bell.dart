import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NotificationBell extends StatefulWidget {
  final VoidCallback? onTap;
  final double size;

  const NotificationBell({
    super.key,
    this.onTap,
    this.size = 20,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isDark
        ? (_hovered ? Colors.grey[300] : Colors.white)
        : (_hovered ? const Color(0xFF0F6AD1) : const Color(0xFF137FEC));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            FontAwesomeIcons.bell,
            size: widget.size,
            color: color,
          ),
        ),
      ),
    );
  }
}
