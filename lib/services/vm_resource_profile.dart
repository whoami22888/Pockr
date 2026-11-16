/// Explicit resource profiles; turbo is an experiment, not a speed guarantee.
class VmResourceProfile {
  final int vcpus;
  final int memoryMb;
  const VmResourceProfile(this.vcpus, this.memoryMb);
}

VmResourceProfile vmResourceProfile(String name) {
  switch (name) {
    case 'economy':
      return const VmResourceProfile(2, 1536);
    case 'turbo':
      return const VmResourceProfile(4, 3072);
    default:
      return const VmResourceProfile(2, 2048);
  }
}
