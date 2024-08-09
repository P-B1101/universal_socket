import 'dart:async';

import 'package:rxdart/subjects.dart';

final class LogObserver {
  LogObserver._();

  static final LogObserver _instance = LogObserver._();

  static String preText = '';

  static LogObserver get instance => _instance;

  final _controller = BehaviorSubject<String>();
  final StringBuffer _buffer = StringBuffer();

  set setPreText(String text) => preText = text;

  void add(String message) {
    _buffer.writeln('$preText$message');
    _controller.add(_buffer.toString());
  }

  Stream<String> get observer => _controller.stream;
}
