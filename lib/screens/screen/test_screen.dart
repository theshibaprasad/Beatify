import 'package:flutter/material.dart';
import 'package:bloomee/theme_data/default.dart';

class TestView extends StatelessWidget {
  const TestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultTheme.themeColor,
      appBar: AppBar(
        backgroundColor: DefaultTheme.themeColor,
        foregroundColor: DefaultTheme.primaryColor1,
        title: Text(
          'Tests',
          style: const TextStyle(
                  color: DefaultTheme.primaryColor1,
                  fontSize: 25,
                  fontWeight: FontWeight.bold)
              .merge(DefaultTheme.secondoryTextStyle),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const Text(
              "Test View",
              style: TextStyle(color: Colors.white),
            ),
            ElevatedButton(
              onPressed: () async {},
              child: const Text(
                "Test API",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
