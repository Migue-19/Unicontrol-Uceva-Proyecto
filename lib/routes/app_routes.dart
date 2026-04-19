import 'package:flutter/material.dart';
import '../views/home_view.dart';
import '../views/async_view.dart';
import '../views/timer_view.dart';
import '../views/isolate_view.dart';

class AppRoutes {
  static const String home = '/';
  static const String async = '/async';
  static const String timer = '/timer';
  static const String isolate = '/isolate';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const HomeView(),
        async: (_) => const AsyncView(),
        timer: (_) => const TimerView(),
        isolate: (_) => const IsolateView(),
      };
}