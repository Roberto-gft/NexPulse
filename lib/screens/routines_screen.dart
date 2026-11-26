import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExerciseItem {
  final String name;
  final String setsReps;
  final String rest;
  final String muscleGroup;
  final String instructions;
  final int durationSeconds;
  int remainingSeconds;
  bool isRunning;
  bool completed;

  ExerciseItem({
    required this.name,
    required this.setsReps,
    required this.rest,
    required this.muscleGroup,
    required this.instructions,
    required this.durationSeconds,
    this.isRunning = false,
    this.completed = false,
  }) : remainingSeconds = durationSeconds;
}

class WorkoutRoutine {
  final String title;
  final String level;
  final String duration;
  final int estimatedKcal;
  final Color accentColor;
  final List<ExerciseItem> exercises;

  WorkoutRoutine({
    required this.title,
    required this.level,
    required this.duration,
    required this.estimatedKcal,
    required this.accentColor,
    required this.exercises,
  });
}

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final List<WorkoutRoutine> _routines = [
    WorkoutRoutine(
      title: 'Quema Grasa Full Body en Casa',
      level: 'Principiante',
      duration: '20 min',
      estimatedKcal: 210,
      accentColor: const Color(0xFF2E9E6B),
      exercises: [
        ExerciseItem(
          name: 'Jumping Jacks (Saltos de Tijera)',
          setsReps: '3 series x 40 seg',
          rest: '20 seg descanso',
          muscleGroup: 'Cardio / Cuerpo Completo',
          durationSeconds: 40,
          instructions:
          'Mantén la espalda recta, abre piernas y sube brazos al mismo tiempo amortiguando con las puntas de los pies.',
        ),
        ExerciseItem(
          name: 'Sentadillas con Peso Corporal',
          setsReps: '4 series x 45 seg',
          rest: '30 seg descanso',
          muscleGroup: 'Cuádriceps y Glúteos',
          durationSeconds: 45,
          instructions:
          'Baja llevando la cadera hacia atrás como si te sentaras en una silla sin que las rodillas pasen la punta de los pies.',
        ),
        ExerciseItem(
          name: 'Escaladores (Mountain Climbers)',
          setsReps: '3 series x 30 seg',
          rest: '25 seg descanso',
          muscleGroup: 'Abdomen y Cardio',
          durationSeconds: 30,
          instructions:
          'En posición de plancha alta, lleva una rodilla al pecho de forma alternada manteniendo el abdomen contraído.',
        ),
        ExerciseItem(
          name: 'Zancadas Alternas (Lunges)',
          setsReps: '3 series x 45 seg',
          rest: '30 seg descanso',
          muscleGroup: 'Piernas y Glúteos',
          durationSeconds: 45,
          instructions:
          'Da un paso amplio al frente y flexiona ambas rodillas a 90 grados manteniendo el torso erguido.',
        ),
      ],
    ),
    WorkoutRoutine(
      title: 'Cardio HIIT Metabólico Intenso',
      level: 'Intermedio',
      duration: '15 min',
      estimatedKcal: 260,
      accentColor: Colors.deepOrange,
      exercises: [
        ExerciseItem(
          name: 'Burpees sin Flexión',
          setsReps: '4 series x 40 seg',
          rest: '30 seg descanso',
          muscleGroup: 'Cuerpo Completo / Alta Quema',
          durationSeconds: 40,
          instructions:
          'Agáchate, apoya manos en el suelo, extiende piernas atrás a plancha, regresa y da un salto vertical.',
        ),
        ExerciseItem(
          name: 'Rodillas Arriba (High Knees)',
          setsReps: '4 series x 35 seg',
          rest: '20 seg descanso',
          muscleGroup: 'Cardio / Piernas',
          durationSeconds: 35,
          instructions:
          'Corre en tu lugar elevando las rodillas hasta la altura de la cintura acompañando con braceo rápido.',
        ),
        ExerciseItem(
          name: 'Plancha con Toque de Hombros',
          setsReps: '3 series x 40 seg',
          rest: '25 seg descanso',
          muscleGroup: 'Core y Hombros',
          durationSeconds: 40,
          instructions:
          'En plancha alta con pies separados, toca el hombro contrario sin balancear la cadera.',
        ),
      ],
    ),
    WorkoutRoutine(
      title: 'Abdomen y Cintura Definida',
      level: 'Todos los niveles',
      duration: '14 min',
      estimatedKcal: 130,
      accentColor: Colors.indigo,
      exercises: [
        ExerciseItem(
          name: 'Plancha Isométrica Frontal',
          setsReps: '3 series x 45 seg',
          rest: '20 seg descanso',
          muscleGroup: 'Core Profundo',
          durationSeconds: 45,
          instructions:
          'Apoya antebrazos y puntas de los pies formando una línea recta de cabeza a talones.',
        ),
        ExerciseItem(
          name: 'Bicicleta Abdominal',
          setsReps: '3 series x 40 seg',
          rest: '25 seg descanso',
          muscleGroup: 'Oblicuos y Recto Abdominal',
          durationSeconds: 40,
          instructions:
          'Acostado boca arriba, lleva el codo derecho hacia la rodilla izquierda mientras extiendes la otra pierna.',
        ),
        ExerciseItem(
          name: 'Elevación de Piernas Acostado',
          setsReps: '3 series x 35 seg',
          rest: '30 seg descanso',
          muscleGroup: 'Abdomen Inferior',
          durationSeconds: 35,
          instructions:
          'Coloca las manos debajo de los glúteos y sube las piernas rectas sin despegar la zona lumbar.',
        ),
      ],
    ),
  ];

  int _selectedIndex = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      bool changed = false;

      for (final routine in _routines) {
        for (final ex in routine.exercises) {
          if (ex.isRunning) {
            changed = true;
            if (ex.remainingSeconds > 1) {
              ex.remainingSeconds--;
            } else {
              ex.remainingSeconds = 0;
              ex.isRunning = false;
              ex.completed = true;
              _playCompletionAlert(ex.name);
            }
          }
        }
      }

      if (changed) {
        setState(() {});
      }
    });
  }

  Future<void> _playCompletionAlert(String exerciseName) async {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Tiempo terminado! Completaste: $exerciseName'),
        backgroundColor: const Color(0xFF2E9E6B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleExerciseTimer(ExerciseItem ex) {
    setState(() {
      if (!ex.isRunning && ex.remainingSeconds == 0) {
        ex.remainingSeconds = ex.durationSeconds;
      }
      ex.isRunning = !ex.isRunning;
    });
  }

  void _resetExerciseTimer(ExerciseItem ex) {
    setState(() {
      ex.isRunning = false;
      ex.remainingSeconds = ex.durationSeconds;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    final routine = _routines[_selectedIndex];
    final completedCount =
        routine.exercises.where((element) => element.completed).length;
    final progress = routine.exercises.isEmpty
        ? 0.0
        : completedCount / routine.exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rutinas con Cronómetro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _routines.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _routines[index];
                final isSelected = index == _selectedIndex;
                return ChoiceChip(
                  label: Text(item.title),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2E9E6B),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: routine.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        routine.level,
                        style: TextStyle(
                          color: routine.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.timer_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      routine.duration,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${routine.estimatedKcal} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  routine.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso: $completedCount de ${routine.exercises.length} ejercicios',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E9E6B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2E9E6B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          ...routine.exercises.map((exercise) {
            final timerProgress = exercise.durationSeconds == 0
                ? 0.0
                : exercise.remainingSeconds / exercise.durationSeconds;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: exercise.completed
                      ? const Color(0xFF2E9E6B)
                      : (exercise.isRunning ? Colors.orange : borderCol),
                  width: exercise.isRunning ? 1.8 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: exercise.completed,
                        activeColor: const Color(0xFF2E9E6B),
                        onChanged: (val) {
                          setState(() => exercise.completed = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                decoration: exercise.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            Text(
                              exercise.muscleGroup,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _TagChip(text: exercise.setsReps, color: Colors.blue),
                      const SizedBox(width: 8),
                      _TagChip(text: exercise.rest, color: Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise.instructions,
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 12),

                  // Cronómetro individual del ejercicio
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0E1416)
                          : const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.alarm,
                              size: 20,
                              color: exercise.isRunning
                                  ? Colors.orange
                                  : const Color(0xFF2E9E6B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '00:${exercise.remainingSeconds.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () => _toggleExerciseTimer(exercise),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: exercise.isRunning
                                    ? Colors.orange.shade700
                                    : const Color(0xFF2E9E6B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              icon: Icon(
                                exercise.isRunning
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 18,
                              ),
                              label: Text(
                                exercise.isRunning ? 'Pausar' : 'Iniciar',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'Reiniciar tiempo',
                              onPressed: () => _resetExerciseTimer(exercise),
                              icon: const Icon(Icons.refresh, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: timerProgress,
                            minHeight: 5,
                            backgroundColor: isDark
                                ? Colors.white12
                                : Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              exercise.isRunning
                                  ? Colors.orange
                                  : const Color(0xFF2E9E6B),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _TagChip extends StatelessWidget {
  final String text;
  final MaterialColor color;

  const _TagChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color.shade400,
        ),
      ),
    );
  }
}