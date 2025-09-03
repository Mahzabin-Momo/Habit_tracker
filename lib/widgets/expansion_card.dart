import 'package:flutter/material.dart';

class ExpansionCard extends StatefulWidget {
  final Widget child;
  final double elevation;
  final EdgeInsetsGeometry margin;

  const ExpansionCard({
    super.key,
    required this.child,
    this.elevation = 1.0,
    this.margin = const EdgeInsets.all(4.0),
  });

  @override
  State<ExpansionCard> createState() => _ExpansionCardState();
}

class _ExpansionCardState extends State<ExpansionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.elevation,
      margin: widget.margin,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: widget.child,
          ),
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: widget.child,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
