import 'package:flutter/material.dart';

class SOSButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SOSButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      onPressed: onPressed,
      backgroundColor: Colors.red,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sos, color: Colors.white, size: 32),
          Text(
            "SOS",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
