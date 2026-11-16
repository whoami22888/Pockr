import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about.dart';
import '../services/vm_resource_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _vcpuCount = 2;
  int _ramMb = 2048;
  String _performanceProfile = 'standard';
  bool _autoStart = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _vcpuCount = prefs.getInt('vcpu_count') ?? 2;
      _ramMb = prefs.getInt('ram_mb') ?? 2048;
      _performanceProfile = prefs.getString('performance_profile') ?? 'standard';
      _autoStart = prefs.getBool('auto_start') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vcpu_count', _vcpuCount);
    await prefs.setInt('ram_mb', _ramMb);
    await prefs.setString('performance_profile', _performanceProfile);
    await prefs.setBool('auto_start', _autoStart);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'VM Resources',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('vCPU Count'),
            subtitle: Text('$_vcpuCount cores'),
            trailing: SizedBox(
              width: 120,
              child: Slider(
                value: _vcpuCount.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                label: '$_vcpuCount',
                onChanged: (value) {
                  setState(() {
                    _vcpuCount = value.toInt();
                  });
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('RAM'),
            subtitle: Text('${_ramMb}MB'),
            trailing: SizedBox(
              width: 120,
              child: Slider(
                value: _ramMb.toDouble(),
                min: 512,
                max: 4096,
                divisions: 7,
                label: '${_ramMb}MB',
                onChanged: (value) {
                  setState(() {
                    _ramMb = value.toInt();
                  });
                },
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Profiles change CPU and memory limits, not guaranteed speed. '
              'Compare boot time and container throughput on your device. '
              'Changes take effect after restarting the VM.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          ListTile(
            title: const Text('Performance profile'),
            subtitle: Text(
              _performanceProfile == 'turbo'
                  ? 'Experimental: 4 vCPUs / 3072 MB (higher heat)'
                  : _performanceProfile == 'economy'
                      ? 'Low memory: 2 vCPUs / 1536 MB'
                      : 'Original capacity: 2 vCPUs / 2048 MB',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'economy', label: Text('Eco')),
                ButtonSegment(value: 'standard', label: Text('Original')),
                ButtonSegment(value: 'turbo', label: Text('Turbo')),
              ],
              selected: {_performanceProfile},
              onSelectionChanged: (selected) {
                setState(() {
                  _performanceProfile = selected.first;
                  final profile = vmResourceProfile(_performanceProfile);
                  _vcpuCount = profile.vcpus;
                  _ramMb = profile.memoryMb;
                });
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Startup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.power_settings_new),
            title: const Text('Auto-start VM'),
            subtitle: const Text('Start VM when app launches'),
            value: _autoStart,
            onChanged: (value) {
              setState(() {
                _autoStart = value;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Pockr'),
            subtitle: const Text('Version, licenses, project info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
