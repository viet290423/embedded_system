import 'package:flutter/material.dart';

class ControlTileWidget extends StatelessWidget {
  final String title;
  final bool status;
  final ValueChanged<bool> onChanged;
  final Color color;
  const ControlTileWidget(
      {super.key,
      required this.title,
      required this.status,
      required this.onChanged,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
        ),
        Switch(
          value: status,
          onChanged: onChanged,
          activeColor: color,
        ),
      ],
    );
  }
}
