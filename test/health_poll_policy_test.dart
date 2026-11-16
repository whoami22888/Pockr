import 'package:flutter_test/flutter_test.dart';
import 'package:pockr/services/health_poll_policy.dart';

void main() {
  test('Startup polls every five seconds', () {
    expect(vmHealthPollInterval(false), const Duration(seconds: 5));
  });
  test('Healthy VM polls six times less frequently', () {
    expect(vmHealthPollInterval(true), const Duration(seconds: 30));
    expect(healthyHealthPollInterval.inSeconds ~/
        bootHealthPollInterval.inSeconds, 6);
  });
}
