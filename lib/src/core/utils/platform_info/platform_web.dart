import 'platform_interface.dart';

class PlatformInfoImpl implements PlatformInfo {
  @override
  bool get isMacOS => false;

  @override
  bool get isAndroid => false;

  @override
  bool get isIOS => false;

  @override
  bool get isWeb => true;
}
