import 'package:flutter_test/flutter_test.dart';
import 'package:pockr/services/guest_readiness.dart';

void main() {
  test('Degraded Docker still has a reachable management terminal', () {
    final state = GuestReadiness.fromPlatform({'apiReachable': true, 'dockerHealthy': false});
    expect(state.apiReachable, isTrue);
    expect(state.dockerHealthy, isFalse);
    expect(state.serialReady, isFalse);
  });
  test('Healthy runtime exposes both states', () {
    final state = GuestReadiness.fromPlatform({'apiReachable': true, 'dockerHealthy': true});
    expect(state.apiReachable, isTrue);
    expect(state.dockerHealthy, isTrue);
  });
  test('Serial rescue is independent from HTTP and Docker', () {
    final state = GuestReadiness.fromPlatform({
      'apiReachable': false, 'dockerHealthy': false, 'serialReady': true,
    });
    expect(state.apiReachable, isFalse);
    expect(state.dockerHealthy, isFalse);
    expect(state.serialReady, isTrue);
  });
  test('Malformed or missing response fails closed', () {
    expect(GuestReadiness.fromPlatform(null).apiReachable, isFalse);
    expect(GuestReadiness.fromPlatform({'apiReachable': 'true'}).apiReachable, isFalse);
    expect(GuestReadiness.fromPlatform({'serialReady': 'true'}).serialReady, isFalse);
  });
}
