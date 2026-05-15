package com.example.project_backend.Controller;

import com.example.project_backend.DTO.LoginRequest;
import com.example.project_backend.DTO.RegisterRequest;
import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.Role;
import com.example.project_backend.Entity.Subscription;
import com.example.project_backend.Entity.User;
import com.example.project_backend.Repository.SubscriptionPlanRepository;
import com.example.project_backend.Repository.SubscriptionRepository;
import com.example.project_backend.Repository.UserRepository;
import com.example.project_backend.Security.JwtService;
import com.example.project_backend.Service.MemberService;
import com.example.project_backend.Service.SubscriptionService;
import com.example.project_backend.Service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/auth")
@CrossOrigin
public class AuthController {

    private final UserService userService;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final MemberService memberService;
    private final SubscriptionService subscriptionService;
    private final UserRepository userRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final SubscriptionPlanRepository planRepository;

    public AuthController(UserService userService,
                          JwtService jwtService,
                          AuthenticationManager authenticationManager,
                          MemberService memberService,
                          SubscriptionService subscriptionService,
                          UserRepository userRepository,
                          SubscriptionRepository subscriptionRepository,
                          SubscriptionPlanRepository planRepository) {
        this.userService = userService;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
        this.memberService = memberService;
        this.subscriptionService = subscriptionService;
        this.userRepository = userRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.planRepository = planRepository;
    }

    // ── REGISTER SIMPLE ──
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        User user = new User();
        user.setUsername(request.getUsername());
        user.setPassword(request.getPassword());
        if (request.getRole() != null) {
            user.setRole(request.getRole());
        }
        userService.register(user, request.getMemberId());
        return ResponseEntity.ok(Map.of("message", "Utilisateur créé avec succès"));
    }

    // ── LOGIN ──
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            User user = userService.findByIdentifier(request.getIdentifier());

            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            user.getUsername(),
                            request.getPassword()
                    )
            );

            // Bloquer les membres avec abonnement PENDING uniquement
            if (user.getRole() == Role.MEMBER && user.getMember() != null) {
                Long memberId = user.getMember().getId();
                List<Subscription> allSubs = subscriptionRepository.findByMemberId(memberId);

                boolean hasActive  = allSubs.stream().anyMatch(s -> "ACTIVE".equals(s.getStatus()));
                boolean hasPending = allSubs.stream().anyMatch(s -> "PENDING".equals(s.getStatus()));

                if (hasPending && !hasActive) {
                    return ResponseEntity.status(403).body(Map.of(
                            "error", "PENDING",
                            "message", "Votre abonnement est en attente de paiement. Présentez-vous à la réception."
                    ));
                }
                // Optionnel : bloquer si aucun abonnement du tout
                 if (allSubs.isEmpty()) {
                     return ResponseEntity.status(403).body(Map.of(
                         "error", "NO_SUBSCRIPTION",
                         "message", "Aucun abonnement actif."
                     ));
                 }

            }

            String token = jwtService.generateToken(user.getUsername(), user.getRole().name());

            Long memberId = user.getMember() != null ? user.getMember().getId() : null;
            Long coachId  = user.getCoach()  != null ? user.getCoach().getId()  : null;

            Map<String, Object> response = new HashMap<>();
            response.put("token",    token);
            response.put("role",     user.getRole().name());
            response.put("username", user.getUsername());
            response.put("memberId", memberId != null ? memberId : 0);
            response.put("coachId",  coachId  != null ? coachId  : 0);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(401).body(
                    Map.of("error", "Identifiants incorrects"));
        }
    }

    // ── GET COACH USERNAME ──
    @GetMapping("/coach-username")
    public ResponseEntity<?> getCoachUsername() {
        try {
            String currentUsername = SecurityContextHolder.getContext()
                    .getAuthentication().getName();

            User currentUser = userRepository.findByUsername(currentUsername)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            User coachUser;

            if (currentUser.getRole() == Role.MEMBER) {
                coachUser = userRepository.findFirstByRole(Role.COACH)
                        .orElseThrow(() -> new RuntimeException("Aucun coach disponible"));
            } else {
                return ResponseEntity.badRequest().body(Map.of("error", "Réservé aux membres"));
            }

            return ResponseEntity.ok(Map.of("username", coachUser.getUsername()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET MEMBER USERNAME ──
    @GetMapping("/member-username/{memberId}")
    public ResponseEntity<?> getMemberUsername(@PathVariable Long memberId) {
        try {
            User user = userRepository.findByMemberId(memberId)
                    .orElseThrow(() -> new RuntimeException("User not found for memberId: " + memberId));
            return ResponseEntity.ok(Map.of("username", user.getUsername()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── REGISTER COMPLET ──
    // FIX : supporte désormais les plans custom (pas seulement BASIC/STANDARD/PREMIUM/ANNUAL)
    @PostMapping("/register-complete")
    public ResponseEntity<?> registerComplete(@RequestBody Map<String, Object> request) {
        try {
            // 1. Créer le membre
            Member member = new Member();
            member.setFullName((String) request.get("fullName"));
            member.setAge(Integer.parseInt(request.get("age").toString()));
            member.setGender((String) request.get("gender"));
            member.setWeight(Double.parseDouble(request.get("weight").toString()));
            member.setHeight(Double.parseDouble(request.get("height").toString()));
            member.setEmail((String) request.get("email"));
            member.setPhone((String) request.get("phone"));
            member.setRegistrationDate(LocalDate.now());
            Member savedMember = memberService.createMember(member);

            // 2. Créer le user lié
            User user = new User();
            user.setUsername((String) request.get("username"));
            user.setPassword((String) request.get("password"));
            user.setEmail((String) request.get("email"));
            user.setPhone((String) request.get("phone"));
            user.setRole(Role.MEMBER);
            userService.register(user, savedMember.getId());

            // 3. Résoudre prix et durée du plan
            String subscriptionType = (String) request.get("subscriptionType");
            String paymentRef        = (String) request.get("paymentRef");

            // ── Résolution prix/durée : custom plan BDD > standard hardcodé > fallback Flutter ──
            double[] priceAndDuration = resolvePlanPriceAndDuration(
                    subscriptionType,
                    request.get("subscriptionPrice"),
                    request.get("subscriptionDuration")
            );
            double price    = priceAndDuration[0];
            int    duration = (int) priceAndDuration[1];

            // 4. Créer l'abonnement PENDING
            Subscription subscription = new Subscription();
            subscription.setType(subscriptionType);
            subscription.setStartDate(LocalDate.now());
            subscription.setStatus("PENDING");
            subscription.setAutoRenew(false);
            subscription.setPrice(price);
            subscription.setDuration(duration);
            subscription.setPaymentRef(paymentRef != null ? paymentRef : "");

            subscriptionService.createSubscriptionPending(savedMember.getId(), subscription);

            // 5. Générer JWT
            String token = jwtService.generateToken(user.getUsername(), "MEMBER");

            return ResponseEntity.ok(Map.of(
                    "message",  "Compte créé avec succès",
                    "token",    token,
                    "role",     "MEMBER",
                    "memberId", savedMember.getId(),
                    "coachId",  0,
                    "username", user.getUsername()
            ));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/coach-username/{coachId}")
    public ResponseEntity<?> getCoachUsernameById(@PathVariable Long coachId) {
        try {
            User coach = userRepository.findById(coachId)
                    .orElseThrow(() -> new RuntimeException("Coach non trouvé"));
            if (coach.getRole() != Role.COACH) {
                return ResponseEntity.badRequest().body(Map.of("error", "User n'est pas un coach"));
            }
            return ResponseEntity.ok(Map.of("username", coach.getUsername()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ──────────────────────────────────────────────────────────
    // HELPER : résolution prix + durée dans l'ordre de priorité
    //   1. Plan custom en BDD (par nom)
    //   2. Plans standard hardcodés (BASIC, STANDARD, PREMIUM, ANNUAL)
    //   3. Valeurs envoyées par le Flutter (subscriptionPrice / subscriptionDuration)
    //   4. Valeurs par défaut de sécurité (60 DT / 1 mois)
    // ──────────────────────────────────────────────────────────
    private double[] resolvePlanPriceAndDuration(String type,
                                                 Object priceObj,
                                                 Object durationObj) {
        // 1. Chercher dans les plans custom de la BDD
        var customPlan = planRepository.findByName(type.toUpperCase());
        if (customPlan.isPresent()) {
            return new double[]{ customPlan.get().getPrice(), customPlan.get().getDuration() };
        }

        // 2. Plans standard hardcodés
        return switch (type.toUpperCase()) {
            case "BASIC"    -> new double[]{ 60,  1  };
            case "STANDARD" -> new double[]{ 150, 3  };
            case "PREMIUM"  -> new double[]{ 300, 6  };
            case "ANNUAL"   -> new double[]{ 490, 12 };
            default -> {
                // 3. Utiliser les valeurs envoyées depuis Flutter si disponibles
                double price    = priceObj    != null ? Double.parseDouble(priceObj.toString())    : 60;
                int    duration = durationObj != null ? Integer.parseInt(durationObj.toString()) : 1;
                yield new double[]{ price, duration };
            }
        };
    }
}