import 'dart:async';

import 'request/tcp_request.dart';
import 'tcp_universal_socket.dart';

abstract interface class IComunication {
  Future<bool> connect(ConnectionConfig config);

  Future<void> disconnect();

  Future<void> sendMessage(String body);

  Stream<double> uploadFile(Object file);

  void addListener(Callback<TCPRequest> callback);
}
