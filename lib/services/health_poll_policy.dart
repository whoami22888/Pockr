/// Probe frequently while booting, and less frequently once Docker is ready.
const Duration bootHealthPollInterval = Duration(seconds: 5);
const Duration healthyHealthPollInterval = Duration(seconds: 30);

Duration vmHealthPollInterval(bool healthy) =>
    healthy ? healthyHealthPollInterval : bootHealthPollInterval;
