import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:rxdart/subjects.dart';
import 'package:universal_socket/universal_socket.dart';

import 'i_tcp_socket.dart';

base mixin _ComunicationOverSocket {
  late final _handler = SocketHandler(_onReceived);
  Callback<TCPRequest>? _callback;

  void _onReceived(TCPRequest request) {
    if (_callback != null) {
      _callback!(request);
    }
  }

  Future<bool> connectWithSocket(ConnectionConfig config) async {
    final isConnected = await _handler.connect(config);
    if (!isConnected) return false;
    _handler.listenToSocket();
    return true;
  }

  Future<void> disconnectFromSocket() => _handler.disconnect();

  void listenToSocket(Callback<TCPRequest> callback) => _callback = callback;

  // Future<void> sendThroughSocket(
  //   Object body, {
  //   BodyType type = BodyType.string,
  // }) async {
  //   switch (type) {
  //     case BodyType.file:
  //       await _handler.sendFile(body as File);
  //     case BodyType.string:
  //       await _handler.sendMessage(body as String);
  //     case BodyType.unknown:
  //       throw UnimplementedError('body must be string or file');
  //   }
  // }

  Future<void> sendMessageThroughSocket(Object body) =>
      _handler.sendMessage(body as String);

  Stream<double> uploadFileThroughSocket(File file) => _handler.sendFile(file);

  bool get isConnected => _handler.isConnected;
}

final class TcpSocket with _ComunicationOverSocket implements IComunication {
  @override
  Future<bool> connect(ConnectionConfig config) => connectWithSocket(config);

  @override
  Future<void> disconnect() => disconnectFromSocket();
  @override
  void addListener(Callback<TCPRequest> callback) => listenToSocket(callback);

  @override
  Future<void> sendMessage(String message) => sendMessageThroughSocket(message);

  @override
  Stream<double> uploadFile(Object file) =>
      uploadFileThroughSocket(file as File);
}

final class SocketHandler {
  final void Function(TCPRequest) onReceived;
  SocketHandler(this.onReceived);

  Socket? _socket;
  bool _connected = false;
  final _bytes = List<int>.empty(growable: true);
  StreamSubscription? _sub;
  static const _dividerString = '||';
  static const _tokenIdentifier = 'TOKEN:';
  StreamController<double>? _progressController;

  Future<bool> connect(ConnectionConfig config) async {
    int k = 1;
    while (true) {
      try {
        _socket = await Socket.connect(
          config.ipAddress,
          config.port,
          timeout: Duration(milliseconds: config.timeout),
        );
        _connected = true;
        Logger.log('$k attemps. Socket connected successfully');
        return true;
      } on Exception catch (error) {
        Logger.log('$k attemps. Socket not connected (Timeout reached)');
        Logger.log('Details:');
        Logger.log(error);
        if (k >= config.attempts) {
          await disconnect();
          return false;
        }
        k++;
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close();
      _sub?.cancel();
    } on Exception catch (error) {
      Logger.log(error);
    }
    _connected = false;
    Logger.log('Socket disconnected.');
  }

  void listenToSocket() {
    assert(_connected, 'call `connectWithSocket` first');
    assert(_socket != null, 'call `connectWithSocket` first');
    _sub = _socket!.listen(_mapper);
  }

  Future<void> sendMessage(String message) async {
    assert(_connected, 'call `connectWithSocket` first');
    assert(_socket != null, 'call `connectWithSocket` first');
    _socket!.add(utf8.encode('$_dividerString$message$_dividerString'));
  }

  Stream<double> sendFile(File file) async* {
    assert(_connected, 'call `connectWithSocket` first');
    assert(_socket != null, 'call `connectWithSocket` first');
    final size = await file.length();
    if (size == 0) return;
    int temp = 0;
    _progressController = BehaviorSubject<double>();
    _socket!
        .addStream(file.openRead().map((data) {
      temp += data.length;
      final progress = temp / size;
      if (_progressController != null && !_progressController!.isClosed) {
        _progressController!.add(progress);
      }
      return data;
    }))
        .then((_) async {
      await Future.delayed(const Duration(seconds: 2));
      _socket!.add(utf8.encode(
        '$_dividerString${TCPCommand.eom.stringValue}$_dividerString',
      ));
    });
    if (_progressController != null) yield* _progressController!.stream;
  }

  void _mapper(Uint8List bytes) {
    Logger.log('New packet received');
    try {
      _handleStringMessage(bytes);
    } catch (error) {
      // _handleFile(bytes);
      _bytes.addAll(bytes);
      Logger.log(error);
    }
  }

  void _handleStringMessage(Uint8List bytes) {
    final data = utf8.decode(bytes);
    Logger.log('Data received: $data');
    if (data.contains(_tokenIdentifier)) {
      final body = data.substring(2, data.length - 2);
      final request = TCPRequest(
        body: body,
        command: TCPCommand.token,
      );
      onReceived(request);
      return;
    }
    if (!data.startsWith(_dividerString) || !data.endsWith(_dividerString)) {
      throw Exception('Not A Command');
    }
    final body = data.substring(2, data.length - 2);
    final TCPRequest request;
    if (body == TCPCommand.eom.stringValue) {
      request = TCPRequest(
        body: _bytes.toList(),
        command: TCPCommand.sendFile,
      );
      _handleEOM();
    } else {
      request = TCPRequest(
        body: body,
        command: TCPCommand.sendMessage,
      );
    }
    onReceived(request);
  }

  void _handleEOM() {
    _bytes.clear();
    _progressController?.close();
  }

  bool get isConnected => _connected;
}
