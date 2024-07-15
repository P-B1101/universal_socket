enum TCPCommand {
  sendMessage,
  sendFile,
  authentication,
  token,
  eom,
  unknown;

  String get stringValue => switch (this) {
        token => 'TOKEN',
        sendMessage => 'SEND_MESSAGE',
        sendFile => 'SEND_FILE',
        authentication => 'AUTHENTICATION',
        eom => 'END_OF_MESSAGE',
        unknown => 'UNKNOWN',
      };

  static TCPCommand fromString(String value) => switch (value) {
        'TOKEN' => token,
        'SEND_MESSAGE' => sendMessage,
        'SEND_FILE' => sendFile,
        'AUTHENTICATION' => authentication,
        'END_OF_MESSAGE' => eom,
        _ => unknown,
      };
}
