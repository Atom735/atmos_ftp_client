import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:atmos_logger/atmos_logger.dart';

import 'entity.dart';
import 'socket.dart';

class FtpClient {
  FtpClient(
    this.host, {
    this.port = 21,
    this.timeout = 30,
    this.user = 'anonymous',
    this.pass = '',
    this.debugLogger = const LoggerVoid(),
  }) : _socket = FtpSocket(host, port, timeout, debugLogger);

  final String host;
  final int port;
  final int timeout;
  final String user;
  final String pass;
  final FtpSocket _socket;
  final Logger debugLogger;

  @override
  String toString() => 'FTP_CLIENT[${hashCode.toRadixString(16)}]';

  static String _bts(Uint8List e) => String.fromCharCodes(e);
  static FtpEntity _ste(String e) => FtpEntity.fromString(e);

  Stream<FtpEntity> list([String path = '']) async* {
    final dataSocket = await _pasv();
    _socket.send(path.isEmpty ? 'LIST\r\n' : 'LIST $path\r\n');
    int code;
    code = (await _socket.recive()).key;
    if (code != 150) {
      throw Exception('Failed to start downloading');
    }
    yield* const LineSplitter().bind(dataSocket.map(_bts)).map(_ste);

    code = (await _socket.recive()).key;
    if (code != 226) {
      throw Exception('Failed to downloading end');
    }

    await dataSocket.close();
  }

  Future<void> quit() async {
    _socket.send('QUIT\r\n');
    final code = (await _socket.recive()).key;
    if (code != 221) {
      throw Exception('Failed to quit');
    }
  }

  Stream<Uint8List> retr(String path) async* {
    final dataSocket = await _pasv();
    _socket.send('RETR $path\r\n');
    int code;
    code = (await _socket.recive()).key;
    if (code != 150) {
      throw Exception('Failed to start downloading');
    }
    yield* dataSocket;

    code = (await _socket.recive()).key;
    if (code != 226) {
      throw Exception('Failed to downloading end');
    }
    await dataSocket.close();
  }

  Future<void> _connect() async {
    if (_socket.closed) {
      await _socket.connect();
      int code;
      code = (await _socket.recive()).key;
      if (code != 220) {
        throw Exception(
            'The welcome message for the FTP connection was not received');
      }
      _socket.send('USER $user\r\nPASS $pass\r\n');
      code = (await _socket.recive()).key;
      if (code == 331) {
        code = (await _socket.recive()).key;
      }
      if (code != 230) {
        throw Exception(
            'Failed to register FTP-connections incorrect username or password');
      }
    }
  }

  Future<Socket> _pasv() async {
    await _connect();
    _socket.send('PASV\r\n');
    String data;
    int code;
    {
      final r = await _socket.recive();
      data = r.value;
      code = r.key;
    }

    if (code != 227 && code != 27) {
      throw Exception('Failed to enter passive mode FTP-connections, '
          'IP for connect was not received');
    }
    final iParOpen = data.indexOf('(');
    final iParClose = data.indexOf(')');

    if (iParClose == -1 || iParOpen == -1) {
      throw Exception('Failed to enter passive mode FTP-connections, '
          'received data does not contain IP');
    }
    final ipData = data
        .substring(iParOpen + 1, iParClose)
        .split(',')
        .map(int.parse)
        .toList();

    return Socket.connect(
      InternetAddress(ipData.take(4).join('.'), type: InternetAddressType.IPv4),
      (ipData[4] << 8) + ipData[5],
      timeout: Duration(seconds: timeout),
    );
  }
}

// final print = const LoggerPrint().trace;
