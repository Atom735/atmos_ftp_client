import 'dart:io';

import 'package:atmos_ftp_client/atmos_ftp_client.dart';
import 'package:atmos_logger/atmos_logger.dart';

final ftp = FtpClient('ftp.zakupki.gov.ru', user: 'free', pass: 'free');
Future<void> main(List<String> arguments) async {
  await ftp.list().forEach((e) => const LoggerPrint()(e.toString()));
  await ftp
      .list('/fcs_regions')
      .forEach((e) => const LoggerPrint()(e.toString()));

  await ftp
      .list('/fcs_regions/Tatarstan_Resp')
      .forEach((e) => const LoggerPrint()(e.toString()));
  await ftp
      .list('/fcs_regions/Tatarstan_Resp/notifications')
      .forEach((e) => const LoggerPrint()(e.toString()));
  await File('test.zip').openWrite().addStream(ftp.retr(
      '/fcs_regions/Tatarstan_Resp/notifications/notification_Tatarstan_Resp_2021100100_2021110100_007.xml.zip'));

  await ftp.quit();
}
