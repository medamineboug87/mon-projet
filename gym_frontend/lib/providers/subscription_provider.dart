import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';

final activeSubscriptionProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, memberId) async {
      return await SubscriptionService.getActiveSubscription(memberId);
    });

final renewSubscriptionProvider = FutureProvider.family<bool, int>((
  ref,
  subscriptionId,
) async {
  return await SubscriptionService.renewSubscription(subscriptionId);
});

final cancelSubscriptionProvider = FutureProvider.family<bool, int>((
  ref,
  subscriptionId,
) async {
  return await SubscriptionService.cancelSubscription(subscriptionId);
});
