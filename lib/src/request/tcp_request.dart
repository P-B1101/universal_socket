import 'package:universal_socket/universal_socket.dart';

class TCPRequest {
  final TCPCommand command;
  final Object? body;

  const TCPRequest({
    required this.body,
    required this.command,
  });

  factory TCPRequest.create(TCPCommand command) =>
      TCPRequest(body: null, command: command);

  @override
  String toString() {
    switch (command) {
      case TCPCommand.sendMessage:
      case TCPCommand.token:
        return body.toString();
      case TCPCommand.sendFile:
      case TCPCommand.eom:
      case TCPCommand.authentication:
      case TCPCommand.unknown:
        return command.stringValue;
    }
  }
}
