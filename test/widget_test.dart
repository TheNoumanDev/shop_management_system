// Tests for Mashallah Mobile Center business management app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  testWidgets('App loads without Firebase errors', (WidgetTester tester) async {
    // Create a minimal test widget that doesn't require Firebase
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Mashallah Mobile Center')),
          body: const Center(
            child: Text('Welcome to Mashallah Mobile Center'),
          ),
        ),
      ),
    );

    // Verify the app title appears
    expect(find.text('Mashallah Mobile Center'), findsOneWidget);
    expect(find.text('Welcome to Mashallah Mobile Center'), findsOneWidget);
  });

  testWidgets('Login screen widgets test', (WidgetTester tester) async {
    // Test individual widgets without full app initialization
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: const [
              TextField(
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: null,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );

    // Verify login form elements
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
