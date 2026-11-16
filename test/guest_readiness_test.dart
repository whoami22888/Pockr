import 'package:flutter_test/flutter_test.dart';
import 'package:pockr/services/guest_readiness.dart';

void main() {
  test('Degraded Docker still has a reachable management terminal', () {
    final state = GuestReadiness.fromPlatform({'apiReachable': true, 'dockerHealthy': false});
    expect(state.apiReachable, isTrue);
    expect(state.dockerHealthy, isFalse);
  });
  test('Healthy runtime exposes both states', () {
    final state = GuestReadiness.fromPlatform({'apiReachable': true, 'dockerHealthy': true});
    expect(state.apiReachable, isTrue);
    expect(state.dockerHealthy, isTrue);
  });
  test('Malformed or missing response fails closed', () {
    expect(GuestReadiness.fromPlatform(null).apiReachable, isFalse);
    expect(GuestReadiness.fromPlatform({'apiReachable': 'true'}).apiReachable, isFalse);
  });
}
