import 'package:flutter/material.dart';

class MealPlanItem {
  final String mealTime;
  final String title;
  final List<String> ingredients;
  final String preparation;
  final String nutritionTip;
  final int kcal;
  final int proteinGrams;
  final int carbsGrams;
  final int fatsGrams;
  final int fiberGrams;
  bool consumed;

  MealPlanItem({
    required this.mealTime,
    required this.title,
    required this.ingredients,
    required this.preparation,
    required this.nutritionTip,
    required this.kcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatsGrams,
    required this.fiberGrams,
    this.consumed = false,
  });
}

class DietPlanProfile {
  final String name;
  final String objective;
  final int targetKcal;
  final List<MealPlanItem> meals;

  DietPlanProfile({
    required this.name,
    required this.objective,
    required this.targetKcal,
    required this.meals,
  });
}

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _selectedPlanIndex = 0;

  late final List<DietPlanProfile> _plans = [
    DietPlanProfile(
      name: 'Déficit Equilibrado (1,750 kcal)',
      objective: 'Pérdida de grasa constante de 0.5 a 0.8 kg por semana sin pasar hambre.',
      targetKcal: 1750,
      meals: [
        MealPlanItem(
          mealTime: '1. Desayuno · 8:00 AM',
          title: 'Omelette de espinacas con avena cocida',
          ingredients: [
            '3 claras de huevo + 1 huevo entero (140 kcal)',
            '1 taza de espinacas frescas y jitomate picado (25 kcal)',
            '45 g (1/2 taza) de hojuelas de avena natural cocidas en agua con canela (165 kcal)',
            '1/2 plátano rebanado encima de la avena (55 kcal)',
            '1 cucharadita de aceite de oliva para cocinar (40 kcal)',
          ],
          preparation:
          'Bate las claras con el huevo entero, saltea las espinacas 1 minuto y vierte el huevo hasta cuajar. Aparte hierve la avena en 1 taza de agua durante 5 minutos y sirve con canela y plátano.',
          nutritionTip:
          'La combinación de proteína de huevo y fibra soluble de la avena mantiene la saciedad por más de 3 horas.',
          kcal: 425,
          proteinGrams: 30,
          carbsGrams: 48,
          fatsGrams: 12,
          fiberGrams: 7,
        ),
        MealPlanItem(
          mealTime: '2. Colación Matutina · 11:30 AM',
          title: 'Bowl de yogur griego natural con frutos rojos',
          ingredients: [
            '150 g de yogur griego natural sin azúcar añadida (95 kcal)',
            '80 g de fresas o moras frescas picadas (30 kcal)',
            '10 g (3 mitades) de nuez picada (65 kcal)',
            '1 cucharadita de semillas de chía (25 kcal)',
          ],
          preparation:
          'Mezcla el yogur frío con las semillas de chía, deja reposar 5 minutos y agrega las fresas y nueces picadas.',
          nutritionTip:
          'Aporta probióticos y ácidos grasos omega-3 que reducen la inflamación muscular.',
          kcal: 215,
          proteinGrams: 17,
          carbsGrams: 15,
          fatsGrams: 9,
          fiberGrams: 5,
        ),
        MealPlanItem(
          mealTime: '3. Comida Fuerte · 2:30 PM',
          title: 'Pechuga asada, arroz integral y ensalada verde',
          ingredients: [
            '160 g de pechuga de pollo sin piel sazonada con limón y ajo (260 kcal)',
            '100 g (1/2 taza) de arroz integral cocido (115 kcal)',
            '2 tazas de lechuga, pepino y zanahoria rallada (45 kcal)',
            '40 g (1/4 pieza) de aguacate Hass (65 kcal)',
            '1 tortilla de maíz caliente (60 kcal)',
          ],
          preparation:
          'Asa la pechuga a la plancha 4 minutos por lado sin aceite extra. Acompaña con el arroz integral, la ensalada fresca aderezada con limón y el aguacate.',
          nutritionTip:
          'Comer primero la ensalada disminuye el pico de glucosa después de la comida.',
          kcal: 545,
          proteinGrams: 48,
          carbsGrams: 50,
          fatsGrams: 16,
          fiberGrams: 8,
        ),
        MealPlanItem(
          mealTime: '4. Colación Vespertina · 6:00 PM',
          title: 'Manzana verde con crema de cacahuate natural',
          ingredients: [
            '1 manzana verde mediana en gajos (85 kcal)',
            '15 g (1 cucharada) de crema de cacahuate 100% maní sin azúcar (95 kcal)',
            'Té verde o infusión sin azúcar (0 kcal)',
          ],
          preparation:
          'Lava y corta la manzana en rebanadas delgadas y úntalas con la crema de cacahuate.',
          nutritionTip:
          'Ideal 45 minutos antes de entrenar para darte energía sostenida.',
          kcal: 180,
          proteinGrams: 5,
          carbsGrams: 24,
          fatsGrams: 8,
          fiberGrams: 5,
        ),
        MealPlanItem(
          mealTime: '5. Cena Ligera · 8:30 PM',
          title: 'Tostadas horneadas de ceviche de atún',
          ingredients: [
            '1 lata (140 g drenado) de atún en agua (150 kcal)',
            '1/2 taza de jitomate, cebolla morada, cilantro y pepino picados (35 kcal)',
            '2 tostadas de maíz horneadas (130 kcal)',
            'Jugo de 1 limón y 1/4 de aguacate pequeño (70 kcal)',
          ],
          preparation:
          'Escurre bien el atún, mézclalo con la verdura picada y el jugo de limón. Sirve sobre las tostadas horneadas.',
          nutritionTip:
          'Cena alta en proteína magra y baja en grasas saturadas para favorecer la recuperación nocturna.',
          kcal: 385,
          proteinGrams: 34,
          carbsGrams: 36,
          fatsGrams: 10,
          fiberGrams: 6,
        ),
      ],
    ),
    DietPlanProfile(
      name: 'Déficit Acelerado (1,450 kcal)',
      objective: 'Enfocado en reducción rápida de grasa corporal con alto aporte proteico.',
      targetKcal: 1450,
      meals: [
        MealPlanItem(
          mealTime: '1. Desayuno · 8:00 AM',
          title: 'Claras a la mexicana con pan integral tostado',
          ingredients: [
            '4 claras de huevo + 1 huevo entero (140 kcal)',
            'Jitomate, cebolla y chile verde al gusto (25 kcal)',
            '1 rebanada de pan integral de grano entero (80 kcal)',
            '1 taza de papaya picada (60 kcal)',
          ],
          preparation:
          'Sofríe la verdura con spray antiadherente, agrega los huevos batidos y sirve junto con el pan tostado y la papaya.',
          nutritionTip: 'La papaya mejora la digestión matutina con muy pocas calorías.',
          kcal: 305,
          proteinGrams: 25,
          carbsGrams: 34,
          fatsGrams: 7,
          fiberGrams: 6,
        ),
        MealPlanItem(
          mealTime: '2. Colación · 11:30 AM',
          title: 'Pepino y jícama con limón y chile en polvo',
          ingredients: [
            '1 taza de pepino en rodajas (20 kcal)',
            '1 taza de jícama en tiras (50 kcal)',
            '10 almendras naturales (70 kcal)',
          ],
          preparation:
          'Corta las verduras frescas, agrega limón y acompáñalas con las almendras.',
          nutritionTip: 'Gran volumen de alimento con mínima densidad calórica.',
          kcal: 140,
          proteinGrams: 4,
          carbsGrams: 16,
          fatsGrams: 6,
          fiberGrams: 6,
        ),
        MealPlanItem(
          mealTime: '3. Comida · 2:30 PM',
          title: 'Filete de pescado al horno con calabacitas y quinoa',
          ingredients: [
            '180 g de filete de tilapia o blanco del Nilo (210 kcal)',
            '80 g de quinoa cocida (95 kcal)',
            '1 taza de calabacitas y brócoli al vapor (55 kcal)',
            '1 cucharadita de aceite de oliva (45 kcal)',
          ],
          preparation:
          'Hornea o asa el filete con limón, pimienta y ajo por 10 minutos. Sirve con las verduras al vapor y la quinoa.',
          nutritionTip: 'El pescado blanco aporta proteína de rápida digestión.',
          kcal: 405,
          proteinGrams: 42,
          carbsGrams: 30,
          fatsGrams: 11,
          fiberGrams: 6,
        ),
        MealPlanItem(
          mealTime: '4. Colación · 6:00 PM',
          title: 'Gelatina light con queso cottage',
          ingredients: [
            '1 taza de gelatina sin azúcar (10 kcal)',
            '100 g de queso cottage bajo en grasa (85 kcal)',
          ],
          preparation: 'Sirve el queso cottage frío acompañado de la gelatina.',
          nutritionTip: 'Aporta caseína de absorción lenta que quita el antojo dulce.',
          kcal: 95,
          proteinGrams: 13,
          carbsGrams: 5,
          fatsGrams: 2,
          fiberGrams: 0,
        ),
        MealPlanItem(
          mealTime: '5. Cena · 8:30 PM',
          title: 'Rollitos de pechuga de pavo con aguacate y ensalada',
          ingredients: [
            '120 g de pechuga de pavo natural en rebanadas (135 kcal)',
            '40 g de aguacate (65 kcal)',
            '2 tazas de espinaca, lechuga y tomate cherry (45 kcal)',
            '1 taza de caldo de verduras desgrasado (60 kcal)',
          ],
          preparation:
          'Rellena las láminas de pechuga de pavo con tiras de aguacate y espinaca; acompaña con el caldo caliente.',
          nutritionTip: 'Evita carbohidratos pesados antes de dormir para optimizar el déficit.',
          kcal: 305,
          proteinGrams: 28,
          carbsGrams: 14,
          fatsGrams: 13,
          fiberGrams: 6,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    final currentPlan = _plans[_selectedPlanIndex];
    final consumedKcal = currentPlan.meals
        .where((m) => m.consumed)
        .fold(0, (sum, item) => sum + item.kcal);
    final consumedProtein = currentPlan.meals
        .where((m) => m.consumed)
        .fold(0, (sum, item) => sum + item.proteinGrams);
    final consumedCarbs = currentPlan.meals
        .where((m) => m.consumed)
        .fold(0, (sum, item) => sum + item.carbsGrams);
    final consumedFats = currentPlan.meals
        .where((m) => m.consumed)
        .fold(0, (sum, item) => sum + item.fatsGrams);

    final progress =
    (consumedKcal / currentPlan.targetKcal).clamp(0.0, 1.0);
    final remaining =
    (currentPlan.targetKcal - consumedKcal).clamp(0, currentPlan.targetKcal);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plan Alimenticio Detallado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selector de plan nutricional
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _plans.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final plan = _plans[index];
                final isSelected = index == _selectedPlanIndex;
                return ChoiceChip(
                  label: Text(plan.name),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2E9E6B),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _selectedPlanIndex = index),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Panel de calorías y macronutrientes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentPlan.objective,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$consumedKcal / ${currentPlan.targetKcal} kcal',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Disponibles hoy: $remaining kcal',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2E9E6B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.restaurant_menu,
                      size: 32,
                      color: Color(0xFF2E9E6B),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2E9E6B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroBadge(label: 'Proteína', value: '${consumedProtein}g'),
                    _MacroBadge(label: 'Carbos', value: '${consumedCarbs}g'),
                    _MacroBadge(label: 'Grasas', value: '${consumedFats}g'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          ...currentPlan.meals.map((meal) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: meal.consumed ? const Color(0xFF2E9E6B) : borderCol,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: meal.consumed,
                        activeColor: const Color(0xFF2E9E6B),
                        onChanged: (val) {
                          setState(() => meal.consumed = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.mealTime,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E9E6B),
                              ),
                            ),
                            Text(
                              meal.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${meal.kcal} kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingredientes y porciones exactas:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  ...meal.ingredients.map(
                        (ing) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: Color(0xFF2E9E6B),
                                  fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              ing,
                              style: const TextStyle(fontSize: 12.5, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preparación:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal.preparation,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E9E6B).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Consejo nutricional: ${meal.nutritionTip}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E9E6B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MacroBadge(label: 'Prot', value: '${meal.proteinGrams}g'),
                      _MacroBadge(label: 'Carb', value: '${meal.carbsGrams}g'),
                      _MacroBadge(label: 'Grasa', value: '${meal.fatsGrams}g'),
                      _MacroBadge(label: 'Fibra', value: '${meal.fiberGrams}g'),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;

  const _MacroBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1416) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}