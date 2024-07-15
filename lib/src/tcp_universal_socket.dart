import 'dart:async';

import 'request/tcp_request.dart';
import 'tcp_socket_web.dart' if (dart.library.io) 'tcp_socket_io.dart';

typedef Converter<Out, In> = Out Function(In input);
typedef Callback<E> = void Function(E event);

abstract interface class Comunication {
  Future<bool> connect();

  Future<void> disconnect();

  Future<void> sendMessage(String body);

  Stream<double> uploadFile(Object file);

  void addListener(Callback<TCPRequest> callback);
}

class UniversalSocket implements Comunication {
  final ConnectionConfig config;

  final TcpSocket _socket = TcpSocket();

  UniversalSocket(this.config);

  @override
  Future<bool> connect() => _socket.connect(config);

  @override
  Future<void> disconnect() => _socket.disconnect();

  @override
  void addListener(Callback<TCPRequest> callback) =>
      _socket.addListener(callback);

  @override
  Future<void> sendMessage(String body) => _socket.sendMessage(body);

  @override
  Stream<double> uploadFile(Object body) => _socket.uploadFile(body);
}

class ConnectionConfig {
  final String ipAddress;
  final int port;
  final int timeout;
  final int attempts;

  const ConnectionConfig({
    required this.ipAddress,
    required this.port,
    this.timeout = 500,
    this.attempts = 3,
  });

  @override
  String toString() => '$ipAddress:$port';
}
