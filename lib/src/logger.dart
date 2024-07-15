// ignore_for_file: avoid_print

import 'package:universal_socket/src/observer/log_observer.dart';

class Logger {
  const Logger._();

  static void log(Object? object) {
    print(object);
    if (object != null) LogObserver.instance.add(object.toString());
  }
}
