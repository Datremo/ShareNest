import 'package:flutter/material.dart';

class AnimatedSendIcon extends StatelessWidget {
  final String text;
  
  const AnimatedSendIcon({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ],
    );
  }
}
