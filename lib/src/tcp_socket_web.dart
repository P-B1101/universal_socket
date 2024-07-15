import 'dart:async';

import '../universal_socket.dart';
import 'i_tcp_socket.dart';

final class TcpSocket implements IComunication {
  @override
  Future<bool> connect(ConnectionConfig config) async {
    Logger.log('not implemented in web');
    return false;
  }

  @override
  Future<void> disconnect() async {
    Logger.log('not implemented in web');
  }

  @override
  void addListener(Callback<TCPRequest> callback) {
    Logger.log('not implemented in web');
  }

  @override
  Future<void> sendMessage(String body) async {
    Logger.log('not implemented in web');
  }

  @override
  Stream<double> uploadFile(Object file) {
    Logger.log('not implemented in web');
    return const Stream<double>.empty();
  }
}
