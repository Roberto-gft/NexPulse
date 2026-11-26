import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BodyMeasurementsScreen extends StatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  final _waistCtrl = TextEditingController(text: '82');
  final _neckCtrl = TextEditingController(text: '37');
  final _hipCtrl = TextEditingController(text: '94');
  final _armCtrl = TextEditingController(text: '31');
  bool _isMale = true;
  double _bodyFatPercent = 16.5;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waistCtrl.text = prefs.getString('meas_waist') ?? '82';
      _neckCtrl.text = prefs.getString('meas_neck') ?? '37';
      _hipCtrl.text = prefs.getString('meas_hip') ?? '94';
      _armCtrl.text = prefs.getString('meas_arm') ?? '31';
      _logs = prefs.getStringList('meas_logs') ?? [];
    });
    _calculateBodyFat(save: false);
  }

  Future<void> _calculateBodyFat({required bool save}) async {
    final prefs = await SharedPreferences.getInstance();
    final height = double.tryParse(prefs.getString('user_height') ?? '170') ?? 170.0;
    final waist = double.tryParse(_waistCtrl.text) ?? 82.0;
    final neck = double.tryParse(_neckCtrl.text) ?? 37.0;
    final hip = double.tryParse(_hipCtrl.text) ?? 94.0;

    double bf = 18.0;
    if (_isMale && (waist - neck) > 1 && height > 50) {
      final logWaistNeck = log(waist - neck) / ln10;
      final logHeight = log(height) / ln10;
      bf = 495 / (1.0324 - 0.19077 * logWaistNeck + 0.15456 * logHeight) - 450;
    } else if (!_isMale && (waist + hip - neck) > 1 && height > 50) {
      final logWaistHipNeck = log(waist + hip - neck) / ln10;
      final logHeight = log(height) / ln10;
      bf = 495 / (1.29579 - 0.35004 * logWaistHipNeck + 0.22100 * logHeight) - 450;
    }

    bf = bf.clamp(4.0, 55.0);

    await prefs.setString('meas_waist', _waistCtrl.text.trim());
    await prefs.setString('meas_neck', _neckCtrl.text.trim());
    await prefs.setString('meas_hip', _hipCtrl.text.trim());
    await prefs.setString('meas_arm', _armCtrl.text.trim());

    if (save) {
      final now = DateTime.now();
      final entry =
          '${now.day}/${now.month}/${now.year} · Cintura: ${waist}cm · Brazo: ${_armCtrl.text}cm · Grasa: ${bf.toStringAsFixed(1)}%';
      _logs.insert(0, entry);
      await prefs.setStringList('meas_logs', _logs);
    }

    if (!mounted) return;
    setState(() => _bodyFatPercent = bf);
  }

  @override
  void dispose() {
    _waistCtrl.dispose();
    _neckCtrl.dispose();
    _hipCtrl.dispose();
    _armCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medidas y % Grasa Corporal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                const Text(
                  'PORCENTAJE ESTIMADO DE GRASA CORPORAL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_bodyFatPercent.toStringAsFixed(1)} %',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E9E6B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Hombre'),
                      selected: _isMale,
                      onSelected: (_) {
                        setState(() => _isMale = true);
                        _calculateBodyFat(save: false);
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Mujer'),
                      selected: !_isMale,
                      onSelected: (_) {
                        setState(() => _isMale = false);
                        _calculateBodyFat(save: false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _waistCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cintura (cm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _neckCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cuello (cm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hipCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cadera (cm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _armCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Brazo (cm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _calculateBodyFat(save: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E9E6B),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.straighten),
                    label: const Text(
                      'Calcular y Guardar Medidas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ..._logs.map(
                (e) => Card(
              color: cardBg,
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Color(0xFF2E9E6B)),
                title: Text(e, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}