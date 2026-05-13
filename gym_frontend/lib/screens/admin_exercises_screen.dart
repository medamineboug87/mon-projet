import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────
// LIGHT DESIGN TOKENS
// ─────────────────────────────────────────────
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00C853);
// const _kGreenDark = Color(0xFF00963E); // unused
const Color _kBlue = Color(0xFF1976D2);
const Color _kRed = Color(0xFFE53935);
const Color _kOrange = Color(0xFFF57C00);
const Color _kBorder = Color(0xFFDDE2EE);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);

class AdminExercisesScreen extends StatefulWidget {
  const AdminExercisesScreen({super.key});

  @override
  State<AdminExercisesScreen> createState() => _AdminExercisesScreenState();
}

class _AdminExercisesScreenState extends State<AdminExercisesScreen> {
  List<dynamic> _exercises = [];
  bool _isLoading = true;
  String _selectedMuscle = 'Tous';

  static const List<String> _muscles = [
    'Tous',
    'Pectoraux',
    'Biceps',
    'Biceps droit',
    'Épaules',
    'Abdominaux',
    'Quadriceps',
    'Quadriceps droit',
    'Mollets',
    'Mollets droits',
    'Dorsaux',
    'Triceps',
    'Triceps droit',
    'Trapèzes',
    'Lombaires',
    'Ischio-jambiers',
    'Ischio-jambiers droits',
    'Fessiers',
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/exercises'),
        headers: headers,
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _exercises = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredExercises {
    if (_selectedMuscle == 'Tous') return _exercises;
    return _exercises
        .where(
          (e) =>
              e['muscleName']?.toString().toLowerCase() ==
              _selectedMuscle.toLowerCase(),
        )
        .toList();
  }

  Future<void> _deleteExercise(int id) async {
    final confirmed = await _confirmDialog(
      'Supprimer l\'exercice ?',
      'Cette action est irréversible.',
    );
    if (!confirmed) return;

    final headers = await _headers();
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/exercises/$id'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      _snack('Exercice supprimé', _kGreen);
      _loadExercises();
    } else {
      _snack('Erreur', _kRed);
    }
  }

  void _showFormDialog({Map<String, dynamic>? exercise}) {
    final isEdit = exercise != null;
    final nameCtrl = TextEditingController(text: exercise?['name'] ?? '');
    final secondaryCtrl = TextEditingController(
      text: exercise?['secondaryMuscles'] ?? '',
    );
    final descCtrl = TextEditingController(
      text: exercise?['description'] ?? '',
    );
    final videoCtrl = TextEditingController(text: exercise?['videoUrl'] ?? '');

    String selectedMuscle =
        exercise?['muscleName'] ??
        (_selectedMuscle == 'Tous' ? 'Pectoraux' : _selectedMuscle);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: _kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  decoration: BoxDecoration(
                    color: isEdit ? _kBlue : _kGreen,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEdit ? 'Modifier l\'exercice' : 'Nouvel exercice',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // ── Body ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lightField(
                          nameCtrl,
                          'Nom de l\'exercice *',
                          Icons.fitness_center_rounded,
                        ),
                        const SizedBox(height: 12),

                        // Muscle dropdown
                        _LightDropdown<String>(
                          value: selectedMuscle,
                          label: 'Muscle ciblé *',
                          icon: Icons.person_rounded,
                          items: _muscles.where((m) => m != 'Tous').toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedMuscle = v!),
                        ),
                        const SizedBox(height: 12),

                        _lightField(
                          secondaryCtrl,
                          'Muscles secondaires',
                          Icons.account_tree_rounded,
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: _kText, fontSize: 13),
                          decoration: _lightDecoration(
                            'Description / Technique',
                            Icons.description_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── VIDEO URL ──
                        const _SectionLabel('Vidéo de démonstration'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: videoCtrl,
                          style: const TextStyle(color: _kText, fontSize: 13),
                          decoration:
                              _lightDecoration(
                                'URL YouTube / Vimeo (optionnel)',
                                Icons.play_circle_rounded,
                              ).copyWith(
                                hintText: 'https://youtube.com/watch?v=...',
                                hintStyle: const TextStyle(
                                  color: _kTextSub,
                                  fontSize: 12,
                                ),
                                suffixIcon: videoCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 18,
                                          color: _kTextSub,
                                        ),
                                        onPressed: () {
                                          videoCtrl.clear();
                                          setDialogState(() {});
                                        },
                                      )
                                    : null,
                              ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                        if (videoCtrl.text.isNotEmpty &&
                            !videoCtrl.text.startsWith('http'))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: _kOrange,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'L\'URL doit commencer par https://',
                                  style: TextStyle(
                                    color: _kOrange,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // ── Footer ──
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kTextSub,
                            side: const BorderSide(color: _kBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (nameCtrl.text.trim().isEmpty) {
                                    _snack('Le nom est requis', _kRed);
                                    return;
                                  }
                                  final videoUrl = videoCtrl.text.trim();
                                  if (videoUrl.isNotEmpty &&
                                      !videoUrl.startsWith('http')) {
                                    _snack('URL vidéo invalide', _kRed);
                                    return;
                                  }
                                  setDialogState(() => isLoading = true);
                                  final headers = await _headers();
                                  final body = jsonEncode({
                                    'name': nameCtrl.text.trim(),
                                    'muscleName': selectedMuscle,
                                    'secondaryMuscles': secondaryCtrl.text
                                        .trim(),
                                    'description': descCtrl.text.trim(),
                                    'videoUrl': videoUrl.isEmpty
                                        ? null
                                        : videoUrl,
                                  });

                                  http.Response res;
                                  if (isEdit) {
                                    res = await http.put(
                                      Uri.parse(
                                        '${ApiConfig.baseUrl}/admin/exercises/${exercise['id']}',
                                      ),
                                      headers: headers,
                                      body: body,
                                    );
                                  } else {
                                    res = await http.post(
                                      Uri.parse(
                                        '${ApiConfig.baseUrl}/admin/exercises',
                                      ),
                                      headers: headers,
                                      body: body,
                                    );
                                  }
                                  setDialogState(() => isLoading = false);
                                  if (res.statusCode == 200) {
                                    Navigator.pop(ctx);
                                    _snack(
                                      isEdit
                                          ? 'Exercice modifié !'
                                          : 'Exercice créé !',
                                      _kGreen,
                                    );
                                    _loadExercises();
                                  } else {
                                    try {
                                      final err =
                                          jsonDecode(res.body)['error'] ??
                                          'Erreur';
                                      _snack(err, _kRed);
                                    } catch (_) {
                                      _snack('Erreur serveur', _kRed);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEdit ? _kBlue : _kGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEdit ? 'Enregistrer' : 'Créer l\'exercice',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _lightDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextSub, fontSize: 12),
      prefixIcon: Icon(icon, color: _kGreen, size: 18),
      filled: true,
      fillColor: _kSurf2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kGreen, width: 1.5),
      ),
    );
  }

  Widget _lightField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _kText, fontSize: 13),
      decoration: _lightDecoration(label, icon),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Avancé':
        return _kRed;
      case 'Intermédiaire':
        return _kOrange;
      default:
        return _kGreen;
    }
  }

  Future<bool> _confirmDialog(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _kSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(msg, style: const TextStyle(color: _kTextSub)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: _kTextSub),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: _kRed, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _filteredExercises.length;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Gestion Exercices',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _kSurface,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kTextSub),
            onPressed: _loadExercises,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: _kGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nouvel exercice',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : Column(
              children: [
                // ── Stats bar ──
                Container(
                  color: _kSurface,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      _StatChip(
                        '$total exercice${total != 1 ? 's' : ''}',
                        Icons.fitness_center_rounded,
                        _kGreen,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        '${_muscles.length - 1} muscles',
                        Icons.person_rounded,
                        _kBlue,
                      ),
                    ],
                  ),
                ),

                // ── Muscle filter chips ──
                Container(
                  color: _kSurface,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _muscles.length,
                      itemBuilder: (_, i) {
                        final m = _muscles[i];
                        final isSelected = _selectedMuscle == m;
                        return Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: FilterChip(
                            label: Text(
                              m,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected ? Colors.white : _kTextSub,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedMuscle = m),
                            backgroundColor: _kSurf2,
                            selectedColor: _kGreen,
                            checkmarkColor: Colors.white,
                            showCheckmark: false,
                            side: BorderSide(
                              color: isSelected ? _kGreen : _kBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Container(height: 1, color: _kBorder),

                // ── Exercise list ──
                Expanded(
                  child: _filteredExercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: _kSurf2,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.fitness_center_rounded,
                                  size: 32,
                                  color: _kTextSub,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedMuscle == 'Tous'
                                    ? 'Aucun exercice'
                                    : 'Aucun exercice pour $_selectedMuscle',
                                style: const TextStyle(
                                  color: _kTextSub,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: () => _showFormDialog(),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: _kGreen,
                                ),
                                label: const Text(
                                  'Ajouter un exercice',
                                  style: TextStyle(color: _kGreen),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadExercises,
                          color: _kGreen,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _filteredExercises.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _buildExerciseCard(_filteredExercises[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> ex) {
    final difficulty = ex['difficulty'] ?? 'Intermédiaire';
    final diffColor = _difficultyColor(difficulty);
    final hasVideo = (ex['videoUrl'] ?? '').toString().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Icon ──
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: _kGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex['name'] ?? '',
                        style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _DiffBadge(difficulty, diffColor),
                          const SizedBox(width: 6),
                          Text(
                            ex['muscleName'] ?? '',
                            style: const TextStyle(
                              color: _kTextSub,
                              fontSize: 11,
                            ),
                          ),
                          if (hasVideo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _kRed.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.play_circle_rounded,
                                    color: _kRed,
                                    size: 11,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Vidéo',
                                    style: TextStyle(
                                      color: _kRed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Actions menu ──
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: _kTextSub),
                  color: _kSurface,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    if (v == 'edit') _showFormDialog(exercise: ex);
                    if (v == 'delete')
                      _deleteExercise((ex['id'] as num).toInt());
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: _kBlue, size: 17),
                          const SizedBox(width: 10),
                          const Text(
                            'Modifier',
                            style: TextStyle(color: _kText, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: _kRed,
                            size: 17,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Supprimer',
                            style: TextStyle(color: _kText, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Secondary muscles ──
          if ((ex['secondaryMuscles'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_tree_rounded,
                    size: 12,
                    color: _kTextSub,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Secondaires : ${ex['secondaryMuscles']}',
                      style: const TextStyle(color: _kTextSub, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // ── Description ──
          if ((ex['description'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                ex['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _kTextSub, fontSize: 12),
              ),
            ),

          // ── Video URL bar ──
          if (hasVideo)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline_rounded,
                    color: _kRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ex['videoUrl'] ?? '',
                      style: const TextStyle(
                        color: _kRed,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        decorationColor: _kRed,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _DiffBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _kTextSub,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LightDropdown<T> extends StatelessWidget {
  final T value;
  final String label;
  final IconData icon;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final Color Function(T)? itemColor;

  const _LightDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: _kSurface,
      style: const TextStyle(color: _kText, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextSub, fontSize: 12),
        prefixIcon: Icon(icon, color: _kGreen, size: 18),
        filled: true,
        fillColor: _kSurf2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item.toString(),
                style: TextStyle(
                  color: itemColor != null ? itemColor!(item) : _kText,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
