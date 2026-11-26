import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _itemCtrl = TextEditingController();
  List<String> _items = [
    'Pechuga de pollo sin piel (Proteína)',
    'Claras de huevo y huevo entero (Proteína)',
    'Atún en agua en lata (Proteína)',
    'Yogur griego natural sin azúcar (Proteína)',
    'Avena en hojuelas naturales (Carbohidrato)',
    'Arroz integral y quinoa (Carbohidrato)',
    'Aguacate Hass y nueces (Grasa saludable)',
    'Espinacas, brócoli y pepino (Verduras)',
    'Manzana verde y frutos rojos (Frutas)',
  ];
  List<String> _checked = [];

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _items = prefs.getStringList('fit_shop_items') ?? _items;
      _checked = prefs.getStringList('fit_shop_checked') ?? [];
    });
  }

  Future<void> _saveList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fit_shop_items', _items);
    await prefs.setStringList('fit_shop_checked', _checked);
  }

  void _addItem() {
    final text = _itemCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.insert(0, text);
      _itemCtrl.clear();
    });
    _saveList();
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Compras Fitness',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _itemCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Agregar alimento saludable...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E9E6B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._items.map((item) {
            final isDone = _checked.contains(item);
            return Card(
              color: cardBg,
              elevation: 0,
              child: CheckboxListTile(
                value: isDone,
                activeColor: const Color(0xFF2E9E6B),
                title: Text(
                  item,
                  style: TextStyle(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _checked.add(item);
                    } else {
                      _checked.remove(item);
                    }
                  });
                  _saveList();
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}