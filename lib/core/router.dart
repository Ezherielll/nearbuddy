import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

late final GoRouter appRouter;

GoRouter buildRouter(dynamic prefs) => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const Scaffold(
        body: Center(child: Text('NearBuddy — scaffold')))),
  ],
);
