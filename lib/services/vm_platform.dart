import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'health_poll_policy.dart';
import 'guest_readiness.dart';

class VmPlatform {
  static const platform = MethodChannel('com.example.dockerapp/vm');

  static Future<void> startVm() async {
    try {
      await platform.invokeMethod('startVm');
    } on PlatformException catch (e) {
      debugPrint("Failed to start VM: ${e.message}");
      rethrow;
    }
  }

  static Future<void> stopVm() async {
    try {
      await platform.invokeMethod('stopVm');
    } on PlatformException catch (e) {
      debugPrint("Failed to stop VM: ${e.message}");
      rethrow;
    }
  }

  static Future<GuestReadiness> getVmReadiness() async {
    try {
      final payload = await platform.invokeMethod<Map<dynamic, dynamic>>('getVmReadiness');
      return GuestReadiness.fromPlatform(payload);
    } on PlatformException catch (e) {
      debugPrint("Guest readiness unavailable: ${e.message}");
      return const GuestReadiness.unavailable();
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final bool result = await platform.invokeMethod('checkHealth');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to check health: ${e.message}");
      return false;
    }
  }

  static Future<void> writeSerialCommand(String command) async {
    await platform.invokeMethod<void>('writeSerialCommand', {'command': command});
  }

  static Future<String> getBootLog() async {
    final String? result = await platform.invokeMethod<String>('getBootLog');
    return result ?? '';
  }

  static Future<String> getVmStatus() async {
    try {
      final String result = await platform.invokeMethod('getVmStatus');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to get VM status: ${e.message}");
      return 'unknown';
    }
  }

  static Future<void> startContainer(
      String image, String name, List<String> cmd) async {
    try {
      await platform.invokeMethod('startContainer', {
        'image': image,
        'name': name,
        'cmd': cmd,
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to start container: ${e.message}");
      rethrow;
    }
  }

  static Future<void> stopContainer(String name) async {
    try {
      await platform.invokeMethod('stopContainer', {'name': name});
    } on PlatformException catch (e) {
      debugPrint("Failed to stop container: ${e.message}");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> listContainers() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('listContainers');
      return result.cast<Map<String, dynamic>>();
    } on PlatformException catch (e) {
      debugPrint("Failed to list containers: ${e.message}");
      return [];
    }
  }

  static Future<Map<String, dynamic>> vmExec(String cmd) async {
    try {
      final result = await platform.invokeMethod('vmExec', {'cmd': cmd});
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      debugPrint("Failed to vmExec: ${e.message}");
      rethrow;
    }
  }

  static Future<String> getLogs(String name, int tail) async {
    try {
      final String result = await platform.invokeMethod('getLogs', {
        'name': name,
        'tail': tail,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to get logs: ${e.message}");
      return '';
    }
  }
}

class VmState extends ChangeNotifier {
  String _status = 'stopped';
  bool _isHealthy = false;
  bool _isApiReachable = false;
  bool _isSerialReady = false;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _healthPollTimer;
  int _healthGeneration = 0;
  bool _pollPaused = false;

  /// Poll only when the UI is visible; the QEMU foreground service is separate.
  void pauseHealthPolling() {
    if (_pollPaused) return;
    _pollPaused = true;
    _stopHealthPolling();
  }

  void resumeHealthPolling() {
    if (!_pollPaused) return;
    _pollPaused = false;
    refreshStatus();
  }

  String get status => _status;
  bool get isHealthy => _isHealthy;
  bool get isApiReachable => _isApiReachable;
  bool get isSerialReady => _isSerialReady;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // -------------------------------------------------------------------------
  // VM lifecycle
  // -------------------------------------------------------------------------

  Future<void> startVm() async {
    if (_status == 'running' || _status == 'starting') return;
    _isLoading = true;
    _status = 'starting';
    _isHealthy = false;
    _isApiReachable = false;
    _isSerialReady = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await VmPlatform.startVm();
      _status = 'running';
      notifyListeners();
      _startHealthPolling();
    } catch (e) {
      _status = 'error';
      _errorMessage = e.toString();
      debugPrint("Error starting VM: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> stopVm() async {
    _isLoading = true;
    notifyListeners();

    _stopHealthPolling();

    try {
      await VmPlatform.stopVm();
      _status = 'stopped';
      _isHealthy = false;
      _isApiReachable = false;
      _isSerialReady = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error stopping VM: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkHealth() async {
    try {
      final readiness = await VmPlatform.getVmReadiness();
      if (_status != 'running' && _status != 'starting') return;
      _isHealthy = readiness.dockerHealthy;
      _isApiReachable = readiness.apiReachable;
      _isSerialReady = readiness.serialReady;
      if (_isHealthy && _status == 'starting') _status = 'running';
      notifyListeners();
    } catch (e) {
      if (_status == 'running' || _status == 'starting') {
        _isHealthy = false;
        _isApiReachable = false;
        _isSerialReady = false;
        notifyListeners();
      }
      debugPrint("Error checking health: $e");
    }
  }

  Future<void> refreshStatus() async {
    try {
      _status = await VmPlatform.getVmStatus();
      if (_status == 'running') {
        await checkHealth();
        _startHealthPolling();
      } else {
        _isHealthy = false;
        _isApiReachable = false;
        _isSerialReady = false;
        _stopHealthPolling();
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error refreshing status: $e");
    }
  }

  // -------------------------------------------------------------------------
  // Non-overlapping, adaptive health polling
  // -------------------------------------------------------------------------

  void _startHealthPolling() {
    _stopHealthPolling();
    if (_pollPaused || (_status != 'running' && _status != 'starting')) return;
    final generation = _healthGeneration;
    _healthPollTimer = Timer(vmHealthPollInterval(_isHealthy), () async {
      _healthPollTimer = null;
      if (generation != _healthGeneration || _pollPaused) return;
      try {
        final readiness = await VmPlatform.getVmReadiness();
        if (generation != _healthGeneration || _pollPaused) return;
        if (readiness.dockerHealthy != _isHealthy ||
            readiness.apiReachable != _isApiReachable ||
            readiness.serialReady != _isSerialReady) {
          _isHealthy = readiness.dockerHealthy;
          _isApiReachable = readiness.apiReachable;
          _isSerialReady = readiness.serialReady;
          notifyListeners();
        }
      } catch (error) {
        if (generation != _healthGeneration || _pollPaused) return;
        if (_isHealthy || _isApiReachable || _isSerialReady) {
          _isHealthy = false;
          _isApiReachable = false;
          _isSerialReady = false;
          notifyListeners();
        }
        debugPrint('VM health probe failed: $error');
      } finally {
        // Reschedule after completion, never queue concurrent Docker probes.
        if (generation == _healthGeneration) _startHealthPolling();
      }
    });
  }

  void _stopHealthPolling() {
    _healthGeneration++;
    _healthPollTimer?.cancel();
    _healthPollTimer = null;
  }

  @override
  void dispose() {
    _stopHealthPolling();
    super.dispose();
  }
}
