import 'package:flutter_test/flutter_test.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'package:yc_product_plugin/yc_product_plugin_platform_interface.dart';
import 'package:yc_product_plugin/yc_product_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockYcProductPluginPlatform
    with MockPlatformInterfaceMixin
    implements YcProductPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final YcProductPluginPlatform initialPlatform = YcProductPluginPlatform.instance;

  test('$MethodChannelYcProductPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelYcProductPlugin>());
  });

  test('getPlatformVersion', () async {
    YcProductPlugin ycProductPlugin = YcProductPlugin();
    MockYcProductPluginPlatform fakePlatform = MockYcProductPluginPlatform();
    YcProductPluginPlatform.instance = fakePlatform;

    expect(await ycProductPlugin.getPlatformVersion(), '42');
  });
}
