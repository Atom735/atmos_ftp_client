import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:atmos_logger/atmos_logger.dart';

class FtpSocket {
  FtpSocket(this.host, this.port, this.timeout, this.debugLogger);

  bool closed = true;

  final String host;
  final int port;
  final int timeout;
  late RawSocket? _socket;
  late StreamSubscription<RawSocketEvent> _subscription;
  final _recivedChunks = DoubleLinkedQueue<MapEntry<int, String>>();
  final _waitersChunks = DoubleLinkedQueue<Completer<MapEntry<int, String>>>();
  final Logger debugLogger;

  @override
  String toString() => 'SOCKET[${hashCode.toRadixString(16)}]';

  static int getCode(String data) {
    var i = 0;
    for (; i < data.length && '0123456789'.contains(data[i]); i++) {}
    return int.parse(data.substring(0, i));
  }

  void _onRead() {
    final data = String.fromCharCodes(_socket!.read()!);
    final code = getCode(data);
    debugLogger.trace('$this RECV ($code)', data);
    if (_waitersChunks.isNotEmpty) {
      _waitersChunks.removeFirst().complete(MapEntry<int, String>(code, data));
    } else {
      _recivedChunks.add(MapEntry<int, String>(code, data));
    }
  }

  Future<MapEntry<int, String>> recive() {
    if (_recivedChunks.isNotEmpty) {
      return Future.value(_recivedChunks.removeFirst());
    }
    final o = Completer<MapEntry<int, String>>();
    _waitersChunks.addLast(o);
    return o.future;
  }

  void _listner(RawSocketEvent event) {
    debugLogger.trace('$this EVENT: ${event.toString().split('.').last}');
    switch (event) {
      case RawSocketEvent.read:
        return _onRead();
      case RawSocketEvent.readClosed:
        disconnect();
        return;
      default:
    }
  }

  void send(String data) {
    _socket!.write(data.codeUnits);
    debugLogger.trace('$this SEND', data);
  }

  Future<void> connect() async {
    if (!closed) disconnect();
    debugLogger.trace('$this CONNECTING...');
    _socket = await RawSocket.connect(host, port,
        timeout: Duration(seconds: timeout));
    _subscription = _socket!.listen(_listner);
    debugLogger.trace('$this CONNECTED');
    closed = false;
  }

  void disconnect() {
    closed = true;
    debugLogger.trace('$this DISSCONECTING...');
    _socket!
      ..shutdown(SocketDirection.both)
      ..close();
    _subscription.cancel();
    debugLogger.trace('$this DISSCONECTED');
  }
}
