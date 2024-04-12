import 'package:flutter/material.dart';

class LeftScreen extends StatefulWidget {
  const LeftScreen({super.key});

  @override
  State<LeftScreen> createState() => _LeftScreenState();
}

class _LeftScreenState extends State<LeftScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          children: [
            Container(height: 75),
          ],
        ),
      ),
    );
  }

  /*
  return SizedBox(
      height: 75,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          decoration: const BoxDecoration(
            color: opaqueBackgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Row(),
        ),
      ),
  );
  */
}
