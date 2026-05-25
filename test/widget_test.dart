import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:education_guidance_app/constants/app_constants.dart';
import 'package:education_guidance_app/main.dart';

void main() {
  testWidgets('AppRoot shows splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());
    await tester.pump();

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.appTagline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
