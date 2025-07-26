import 'dart:io';
import 'platform_interface.dart';

class PlatformInfoImpl implements PlatformInfo {
  @override
  bool get isMacOS => Platform.isMacOS;

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;

  @override
  bool get isWeb => false;
}
