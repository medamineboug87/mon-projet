package com.example.project_backend.Service;

import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class PaymentService {

    // 🔥 Simulation paiement en ligne (toujours succès)
    public Map<String, Object> simulateOnlinePayment(Long memberId, String subscriptionType, double amount) {

        Map<String, Object> response = new HashMap<>();

        response.put("success", true);
        response.put("paymentRef", UUID.randomUUID().toString());
        response.put("memberId", memberId);
        response.put("subscriptionType", subscriptionType);
        response.put("amount", amount);
        response.put("message", "Paiement simulé réussi");

        return response;
    }
}