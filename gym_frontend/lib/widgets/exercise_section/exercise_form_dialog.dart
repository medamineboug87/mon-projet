import 'package:flutter/material.dart';
import 'exercise_entry_model.dart';

// ─── Design tokens ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kRedL = Color(0xFFFFEBEE);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

const List<String> _kMuscleOptions = [
  'Pectoraux', 'Dorsaux', 'Épaules', 'Biceps', 'Biceps droit',
  'Triceps', 'Triceps droit', 'Abdominaux', 'Quadriceps', 'Quadriceps droit',
  'Ischio-jambiers', 'Ischio-jambiers droits', 'Fessiers', 'Mollets', 'Mollets droits',
  'Lombaires', 'Trapèzes',
];

class ExerciseFormDialog extends StatefulWidget {
  final ExerciseEntry entry;
  final bool isEdit;
  final Function(ExerciseEntry) onSave;

  const ExerciseFormDialog({
    super.key,
    required this.entry,
    this.isEdit = false,
    required this.onSave,
  });

  @override
  State<ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<ExerciseFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _notesCtrl;
  late int _sets;
  late int? _rpe;
  late bool _failure;
  late int _rest;
  late String _muscle;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.entry.exerciseName);
    _weightCtrl = TextEditingController(text: widget.entry.weightKg > 0 ? widget.entry.weightKg.toString() : '');
    _repsCtrl = TextEditingController(text: widget.entry.repsCompleted);
    _notesCtrl = TextEditingController(text: widget.entry.notes);
    _sets = widget.entry.setsCompleted;
    _rpe = widget.entry.rpe;
    _failure = widget.entry.failureReached;
    _rest = widget.entry.restSeconds;
    _muscle = widget.entry.muscleName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(context),
          const Divider(height: 20, color: _kBorder),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameField(),
                  const SizedBox(height: 14),
                  _buildMuscleDropdown(),
                  const SizedBox(height: 14),
                  _buildWeightField(),
                  const SizedBox(height: 14),
                  _buildSetsRepsRow(),
                  const SizedBox(height: 14),
                  _buildRpeSection(),
                  const SizedBox(height: 14),
                  _buildRestSection(),
                  const SizedBox(height: 14),
                  _buildFailureSwitch(),
                  const SizedBox(height: 14),
                  _buildNotesField(),
                  const SizedBox(height: 20),
                  _buildSubmitButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _kGreenL, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.fitness_center_rounded, color: _kGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            widget.isEdit ? 'Modifier l\'exercice' : 'Ajouter un exercice',
            style: const TextStyle(color: _kText, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _kTextSub),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nom de l\'exercice *', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: _kText, fontSize: 13),
          decoration: _inputDecoration('Ex: Développé couché, Squat...', Icons.fitness_center_rounded),
        ),
      ],
    );
  }

  Widget _buildMuscleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Muscle ciblé', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _muscle.isNotEmpty && _kMuscleOptions.contains(_muscle) ? _muscle : null,
          decoration: _inputDecoration('Sélectionner...', Icons.person_rounded),
          dropdownColor: _kSurface,
          style: const TextStyle(color: _kText, fontSize: 13),
          items: _kMuscleOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _muscle = v ?? ''),
        ),
      ],
    );
  }

  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Poids utilisé (kg)', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _kText, fontSize: 13),
          decoration: _inputDecoration('Ex: 60.0', Icons.monitor_weight_rounded),
        ),
      ],
    );
  }

  Widget _buildSetsRepsRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Séries', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _SetsSelector(value: _sets, onChanged: (v) => setState(() => _sets = v)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Répétitions', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _repsCtrl,
                style: const TextStyle(color: _kText, fontSize: 13),
                decoration: _inputDecoration('Ex: 10 ou 8-12', Icons.numbers_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRpeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('RPE (effort ressenti 1-10)', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
            if (_rpe != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_rpe! >= 9 ? _kRed : _rpe! >= 7 ? _kOrange : _kGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_rpe/10', style: TextStyle(color: _rpe! >= 9 ? _kRed : _rpe! >= 7 ? _kOrange : _kGreen, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _rpe == null ? _kBorder : (_rpe! >= 9 ? _kRed : _rpe! >= 7 ? _kOrange : _kGreen),
            inactiveTrackColor: _kBorder,
            thumbColor: _rpe == null ? _kBorder : (_rpe! >= 9 ? _kRed : _rpe! >= 7 ? _kOrange : _kGreen),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: _rpe?.toDouble() ?? 0,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => setState(() => _rpe = v.round() == 0 ? null : v.round()),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Non évalué', style: TextStyle(color: _kTextSub, fontSize: 9)),
            Text('Modéré', style: TextStyle(color: _kTextSub, fontSize: 9)),
            Text('Maximal', style: TextStyle(color: _kTextSub, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  Widget _buildRestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Repos entre séries', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
            Text('${_rest}s', style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        _RestSelector(value: _rest, onChanged: (v) => setState(() => _rest = v)),
      ],
    );
  }

  Widget _buildFailureSwitch() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _failure ? _kRedL : _kSurf2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _failure ? _kRed.withValues(alpha: 0.4) : _kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Échec musculaire atteint', style: TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(
                  _failure ? '⚠️ Récupération accrue nécessaire' : 'Charge non maximale',
                  style: TextStyle(color: _failure ? _kRed : _kTextSub, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(value: _failure, onChanged: (v) => setState(() => _failure = v), activeColor: _kRed),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes (optionnel)', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          style: const TextStyle(color: _kText, fontSize: 13),
          decoration: _inputDecoration('Observations, sensations, points techniques...', Icons.notes_rounded),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_nameCtrl.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Le nom de l\'exercice est requis'), backgroundColor: _kRed),
            );
            return;
          }
          final saved = ExerciseEntry(
            exerciseName: _nameCtrl.text.trim(),
            muscleName: _muscle,
            weightKg: double.tryParse(_weightCtrl.text) ?? 0.0,
            setsCompleted: _sets,
            repsCompleted: _repsCtrl.text.trim().isEmpty ? '10' : _repsCtrl.text.trim(),
            rpe: _rpe,
            failureReached: _failure,
            restSeconds: _rest,
            notes: _notesCtrl.text.trim(),
          );
          Navigator.pop(context);
          widget.onSave(saved);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        child: Text(
          widget.isEdit ? 'Mettre à jour' : 'Ajouter l\'exercice',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kTextSub, fontSize: 12),
      prefixIcon: Icon(icon, color: _kGreen, size: 18),
      filled: true,
      fillColor: _kSurf2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kGreen, width: 1.5),
      ),
    );
  }
}

class _SetsSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _SetsSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: _kSurf2, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 18, color: _kRed),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          constraints: const BoxConstraints(),
        ),
        Text('$value', style: const TextStyle(color: _kText, fontWeight: FontWeight.w800, fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.add, size: 18, color: _kGreen),
          onPressed: value < 20 ? () => onChanged(value + 1) : null,
          constraints: const BoxConstraints(),
        ),
      ],
    ),
  );
}

class _RestSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _RestSelector({required this.value, required this.onChanged});

  static const List<int> _options = [30, 60, 90, 120, 180, 240, 300];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 6,
    children: _options.map((seconds) {
      final isSelected = value == seconds;
      final label = seconds >= 60 ? '${seconds ~/ 60}min${seconds % 60 > 0 ? '${seconds % 60}s' : ''}' : '${seconds}s';
      return GestureDetector(
        onTap: () => onChanged(seconds),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? _kGreen.withValues(alpha: 0.15) : _kSurf2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? _kGreen.withValues(alpha: 0.5) : _kBorder, width: isSelected ? 1.5 : 1),
          ),
          child: Text(label, style: TextStyle(color: isSelected ? _kGreen : _kTextSub, fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
        ),
      );
    }).toList(),
  );
}