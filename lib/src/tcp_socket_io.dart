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
  int _fileLength = 0;
  String? _fileName;
  bool _isFile = false;
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
    final fileName = file.path.fileName;
    await sendMessage('${TCPCommand.sendFile.stringValue}:$size:$fileName');
    await Future.delayed(const Duration(seconds: 1));
    int temp = 0;
    _progressController = BehaviorSubject<double>();
    _socket!.addStream(file.openRead().map((data) {
      temp += data.length;
      final progress = temp / size;
      if (_progressController != null && !_progressController!.isClosed) {
        _progressController!.add(progress);
      }
      return data;
    }));
    if (_progressController != null) yield* _progressController!.stream;
  }

  void _mapper(Uint8List bytes) {
    Logger.log('New packet received');
    if (_handleBytes(bytes)) return;
    final command = _compileIncommingMessage(bytes);
    if (command == null) return;
    if (_handleSendFileCommand(command)) return;
    // if (_handleSendAuthenticationCommand(command)) return;
    if (_handleStringCommand(command)) return;
  }

  bool _handleBytes(List<int> bytes) {
    if (!_isFile) return false;
    _bytes.addAll(bytes);
    if (_bytes.length >= _fileLength) {
      final request = TCPRequest.file(_bytes.toList(), _fileName);
      _bytes.clear();
      _fileLength = 0;
      _isFile = false;
      _fileName = null;
      onReceived(request);
    }
    return true;
  }

  String? _compileIncommingMessage(List<int> bytes) {
    try {
      final data = utf8.decode(bytes);
      if (!data.startsWith(_dividerString) || !data.endsWith(_dividerString)) {
        Logger.log('Not A Command');
        return null;
      }
      final result = data.substring(2, data.length - 2);
      Logger.log('String Data received: $result');
      return result;
    } catch (error) {
      Logger.log(error);
      return null;
    }
  }

  bool _handleSendFileCommand(String message) {
    if (!message.startsWith(TCPCommand.sendFile.stringValue)) return false;
    final temp = message.split(':');
    if (temp.length < 2) {
      Logger.log(
          'Send File command config is not right. Invalid Messagin protocol');
      return false;
    }
    final length = int.tryParse(temp[1]);
    if (length == null) {
      Logger.log('Send File command config is not right. Invalid file length');
      return false;
    }
    _fileLength = length;
    _isFile = true;
    if (temp.length >= 3) _fileName = temp[2];
    return true;
  }

  // bool _handleSendAuthenticationCommand(String message) {
  //   if (!message.startsWith('${TCPCommand.token.stringValue}:')) return false;
  //   final request = TCPRequest.token(
  //     message.substring(message.indexOf(':') + 1),
  //   );
  //   onReceived(request);
  //   return true;
  // }

  bool _handleStringCommand(String message) {
    final request = TCPRequest.command(message);
    onReceived(request);
    return true;
  }

  bool get isConnected => _connected;
}

extension StringExt on String {
  String get fileName => substring(lastIndexOf(Platform.pathSeparator));

  String get fileExtension => substring(lastIndexOf('.'));
}
