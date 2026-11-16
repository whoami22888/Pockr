/// The guest shell needs the API, but not a functioning Docker daemon.
class GuestReadiness {
  final bool apiReachable;
  final bool dockerHealthy;
  final bool serialReady;

  const GuestReadiness({
    required this.apiReachable,
    required this.dockerHealthy,
    this.serialReady = false,
  });

  const GuestReadiness.unavailable()
      : apiReachable = false,
        dockerHealthy = false,
        serialReady = false;

  factory GuestReadiness.fromPlatform(Map<dynamic, dynamic>? payload) {
    return GuestReadiness(
      apiReachable: payload?['apiReachable'] == true,
      dockerHealthy: payload?['dockerHealthy'] == true,
      serialReady: payload?['serialReady'] == true,
    );
  }
}
