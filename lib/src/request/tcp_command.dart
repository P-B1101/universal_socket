enum TCPCommand {
  sendMessage,
  sendFile,
  token,
  unknown;

  String get stringValue => switch (this) {
        token => 'TOKEN',
        sendMessage => 'SEND_MESSAGE',
        sendFile => 'SEND_FILE',
        unknown => 'UNKNOWN',
      };

  static TCPCommand fromString(String value) => switch (value) {
        'TOKEN' => token,
        'SEND_MESSAGE' => sendMessage,
        'SEND_FILE' => sendFile,
        _ => unknown,
      };
}
