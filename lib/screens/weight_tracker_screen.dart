import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  final TextEditingController _weightController = TextEditingController(text: '72');
  final TextEditingController _heightController = TextEditingController(text: '170');
  final TextEditingController _goalWeightController = TextEditingController(text: '66');

  double _bmi = 24.9;
  String _bmiCategory = 'Peso saludable';
  Color _bmiColor = const Color(0xFF2E9E6B);
  int _recommendedDeficitKcal = 1850;
  List<String> _weightHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWeight = prefs.getString('user_weight') ?? '72';
    final savedHeight = prefs.getString('user_height') ?? '170';
    final savedGoal = prefs.getString('user_goal_weight') ?? '66';
    final history = prefs.getStringList('weight_history') ?? [];

    _weightController.text = savedWeight;
    _heightController.text = savedHeight;
    _goalWeightController.text = savedGoal;

    setState(() {
      _weightHistory = history;
    });
    _calculateMetrics(saveRecord: false);
  }

  Future<void> _calculateMetrics({required bool saveRecord}) async {
    final weight = double.tryParse(_weightController.text.trim()) ?? 70.0;
    final heightCm = double.tryParse(_heightController.text.trim()) ?? 170.0;
    final heightM = heightCm / 100.0;

    if (heightM <= 0 || weight <= 0) return;

    final bmi = weight / (heightM * heightM);
    String category;
    Color color;

    if (bmi < 18.5) {
      category = 'Bajo peso';
      color = Colors.blue;
    } else if (bmi < 25.0) {
      category = 'Peso saludable';
      color = const Color(0xFF2E9E6B);
    } else if (bmi < 30.0) {
      category = 'Sobrepeso';
      color = Colors.orange.shade800;
    } else {
      category = 'Obesidad';
      color = Colors.red.shade700;
    }

    // Estimación de calorías diarias recomendadas para déficit saludable
    final maintenance = (weight * 28).round();
    final deficit = (maintenance - 400).clamp(1300, 3000);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_weight', _weightController.text.trim());
    await prefs.setString('user_height', _heightController.text.trim());
    await prefs.setString('user_goal_weight', _goalWeightController.text.trim());

    if (saveRecord) {
      final now = DateTime.now();
      final dateStr = '${now.day}/${now.month}/${now.year}';
      _weightHistory.insert(
        0,
        '$dateStr — ${weight.toStringAsFixed(1)} kg (IMC: ${bmi.toStringAsFixed(1)})',
      );
      await prefs.setStringList('weight_history', _weightHistory);
    }

    if (!mounted) return;
    setState(() {
      _bmi = bmi;
      _bmiCategory = category;
      _bmiColor = color;
      _recommendedDeficitKcal = deficit;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWeight = double.tryParse(_weightController.text) ?? 72.0;
    final goalWeight = double.tryParse(_goalWeightController.text) ?? 66.0;
    final diff = (currentWeight - goalWeight).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text(
          'IMC y Control de Peso',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resultado IMC y Meta
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'ÍNDICE DE MASA CORPORAL (IMC)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  _bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: _bmiColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _bmiColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _bmiCategory,
                    style: TextStyle(
                      color: _bmiColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Meta para bajar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '$diff kg',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Calorías déficit', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '$_recommendedDeficitKcal kcal/día',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Formulario de actualización
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peso actual (kg)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Estatura (cm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _goalWeightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso objetivo (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _calculateMetrics(saveRecord: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E9E6B),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Calcular y Guardar Progreso',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Historial de peso',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          if (_weightHistory.isEmpty)
            const Text(
              'Guarda tu primer registro de peso para ver tu evolución.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._weightHistory.map(
                  (item) => Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF2E9E6B)),
                  title: Text(item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}