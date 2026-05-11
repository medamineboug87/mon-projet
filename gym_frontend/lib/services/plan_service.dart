// FILE: lib/services/plan_service.dart

import 'dart:convert';
import 'logger_service.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Modèle pour les plans d'abonnement
class SubscriptionPlanModel {
  final int id;
  final String name;
  final String displayName;
  final String? description;
  final double price;
  final int duration;
  final bool active;
  final String color;
  final String emoji;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.price,
    required this.duration,
    required this.active,
    required this.color,
    required this.emoji,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'UNKNOWN',
      displayName: json['displayName'] ?? json['name'] ?? 'Plan',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] ?? 1,
      active: json['active'] ?? true,
      color: json['color'] != null && json['color'].toString().isNotEmpty 
          ? json['color'] 
          : '#4CAF50',
      emoji: json['emoji'] != null && json['emoji'].toString().isNotEmpty 
          ? json['emoji'] 
          : '💪',
    );
  }

  String get durationLabel => '$duration mois';
  
  bool get isCustom => !['BASIC', 'STANDARD', 'PREMIUM', 'ANNUAL'].contains(name);
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'displayName': displayName,
    'description': description,
    'price': price,
    'duration': duration,
    'active': active,
    'color': color,
    'emoji': emoji,
  };
}

class PlanService {
  static const String _plansEndpoint = '/admin/plans/active';
  static const Duration _timeout = Duration(seconds: 15);

  // ✅ Méthode publique pour les plans standards (fallback)
  static List<SubscriptionPlanModel> getStandardPlans() => [
    SubscriptionPlanModel(
      id: -1,
      name: 'BASIC',
      displayName: 'Basic',
      price: 60,
      duration: 1,
      description: 'Accès simple à la salle',
      active: true,
      color: '#2196F3',
      emoji: '💪',
    ),
    SubscriptionPlanModel(
      id: -2,
      name: 'STANDARD',
      displayName: 'Standard',
      price: 150,
      duration: 3,
      description: 'Accès + coaching personnalisé',
      active: true,
      color: '#9C27B0',
      emoji: '🏋️',
    ),
    SubscriptionPlanModel(
      id: -3,
      name: 'PREMIUM',
      displayName: 'Premium',
      price: 300,
      duration: 6,
      description: 'Accès illimité + coaching + programmes exclusifs',
      active: true,
      color: '#4CAF50',
      emoji: '👑',
    ),
    SubscriptionPlanModel(
      id: -4,
      name: 'ANNUAL',
      displayName: 'Annuel',
      price: 490,
      duration: 12,
      description: 'Meilleur rapport qualité/prix',
      active: true,
      color: '#FF9800',
      emoji: '📅',
    ),
  ];

  // Récupère tous les plans actifs (API + fallback fusionnés)
  static Future<List<SubscriptionPlanModel>> getActivePlans() async {
    List<SubscriptionPlanModel> apiPlans = [];
    
    // 1. Tenter de charger les plans depuis l'API
    try {
      AppLogger.d('🔄 Chargement des plans depuis: ${ApiConfig.baseUrl}$_plansEndpoint');
      
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}$_plansEndpoint'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      AppLogger.d('📡 Status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        AppLogger.d('✅ ${data.length} plans chargés depuis l\'API');
        apiPlans = data.map((json) => SubscriptionPlanModel.fromJson(json)).toList();
        
        for (var plan in apiPlans) {
          AppLogger.d('   - API: ${plan.displayName} (${plan.price} DT / ${plan.duration} mois)');
        }
      } else {
        AppLogger.d('⚠️ API retourne status ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.d('❌ Erreur chargement API: $e');
    }
    
    // 2. FUSION : Plans API + Plans standards (sans doublons)
    final Map<String, SubscriptionPlanModel> mergedPlans = {};
    
    // Ajouter les plans de l'API d'abord
    for (var plan in apiPlans) {
      mergedPlans[plan.name] = plan;
    }
    
    // Ajouter les plans standards qui n'existent pas déjà
    final standardPlansList = getStandardPlans();
    for (var plan in standardPlansList) {
      if (!mergedPlans.containsKey(plan.name)) {
        mergedPlans[plan.name] = plan;
        AppLogger.d('   - FALLBACK: ${plan.displayName} (${plan.price} DT / ${plan.duration} mois)');
      }
    }
    
    final List<SubscriptionPlanModel> allPlans = mergedPlans.values.toList();
    
    // Trier les plans par prix
    allPlans.sort((a, b) => a.price.compareTo(b.price));
    
    AppLogger.d('📊 Total final: ${allPlans.length} plans');
    
    return allPlans;
  }

  // Récupère un plan par son nom
  static Future<SubscriptionPlanModel?> getPlanByName(String name) async {
    final plans = await getActivePlans();
    try {
      return plans.firstWhere((plan) => plan.name == name.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  // Vérifie si l'API est accessible
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/admin/plans/active'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  
  // Méthodes utilitaires
  static List<SubscriptionPlanModel> getActiveOnly(List<SubscriptionPlanModel> plans) {
    return plans.where((plan) => plan.active).toList();
  }
  
  static List<SubscriptionPlanModel> filterByMinDuration(List<SubscriptionPlanModel> plans, int minMonths) {
    return plans.where((plan) => plan.duration >= minMonths).toList();
  }
  
  static List<SubscriptionPlanModel> filterByMaxPrice(List<SubscriptionPlanModel> plans, double maxPrice) {
    return plans.where((plan) => plan.price <= maxPrice).toList();
  }
}

// Extension pour faciliter l'utilisation
extension PlanListExtension on List<SubscriptionPlanModel> {
  SubscriptionPlanModel? getByName(String name) {
    try {
      return firstWhere((plan) => plan.name == name.toUpperCase());
    } catch (_) {
      return null;
    }
  }
  
  List<SubscriptionPlanModel> get active => where((p) => p.active).toList();
  List<SubscriptionPlanModel> get custom => where((p) => p.isCustom).toList();
  List<SubscriptionPlanModel> get standard => where((p) => !p.isCustom).toList();
}