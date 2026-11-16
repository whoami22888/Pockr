import 'package:flutter_test/flutter_test.dart';
import 'package:pockr/services/vm_resource_profile.dart';

void main() {
  test('Standard retains the original 2 CPU, 2 GiB configuration', () {
    final p = vmResourceProfile('standard');
    expect(p.vcpus, 2);
    expect(p.memoryMb, 2048);
  });

  test('Turbo offers additional CPU and RAM, not a speed guarantee', () {
    final p = vmResourceProfile('turbo');
    expect(p.vcpus, 4);
    expect(p.memoryMb, 3072);
  });

  test('Eco remains explicitly opt-in', () {
    final p = vmResourceProfile('economy');
    expect(p.vcpus, 2);
    expect(p.memoryMb, 1536);
  });

  test('Unknown profile falls back to original capacity', () {
    expect(vmResourceProfile('unspecified').memoryMb, 2048);
  });
}
