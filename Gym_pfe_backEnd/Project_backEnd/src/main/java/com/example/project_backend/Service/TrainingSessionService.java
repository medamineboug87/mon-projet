package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.TrainingSession;
import com.example.project_backend.Repository.MemberRepository;
import com.example.project_backend.Repository.TrainingSessionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
public class TrainingSessionService {

    private static final Logger log = LoggerFactory.getLogger(TrainingSessionService.class);

    private final TrainingSessionRepository sessionRepository;
    private final MemberRepository          memberRepository;

    public TrainingSessionService(TrainingSessionRepository sessionRepository,
                                  MemberRepository memberRepository) {
        this.sessionRepository = sessionRepository;
        this.memberRepository  = memberRepository;
    }

    // ── Créer une séance ──
    @Transactional
    public TrainingSession createSession(Long memberId, TrainingSession session) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new RuntimeException("Member not found"));
        session.setMember(member);

        // Date par défaut si absente
        if (session.getDate() == null) {
            session.setDate(LocalDate.now());
        }

        // ── NIVEAU 2 : log de debug pour vérifier la persistance ──
        log.debug("📝 Session créée — memberId={} | painLevel={} | warmupDone={} | hasCardio={} | duration={}",
                memberId,
                session.getPainLevel()  != null ? session.getPainLevel()  : "non renseigné",
                session.getWarmupDone() != null ? session.getWarmupDone() : "non renseigné",
                session.getHasCardio(),
                session.getDuration());

        TrainingSession saved = sessionRepository.save(session);

        log.info("✅ Session [id={}] persistée — painLevel={} | warmupDone={}",
                saved.getId(),
                saved.getPainLevel(),
                saved.getWarmupDone());

        return saved;
    }

    // ── Toutes les séances ──
    public List<TrainingSession> getAllSessions() {
        return sessionRepository.findAll();
    }

    // ── Séance par ID ──
    public TrainingSession getById(Long id) {
        return sessionRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Session not found: " + id));
    }

    // ── Séances d'un membre ──
    public List<TrainingSession> getSessionsByMember(Long memberId) {
        return sessionRepository.findByMemberId(memberId);
    }

    // ── Séances de la dernière semaine ──
    public List<TrainingSession> getSessionsLastWeek(Long memberId) {
        LocalDate oneWeekAgo = LocalDate.now().minusDays(7);

        List<TrainingSession> all = sessionRepository.findByMemberId(memberId);

        List<TrainingSession> lastWeek = all.stream()
                .filter(s -> s.getDate() != null
                        && !s.getDate().isBefore(oneWeekAgo))
                .sorted((a, b) -> b.getDate().compareTo(a.getDate()))
                .toList();

        if (!lastWeek.isEmpty()) return lastWeek;

        // Fallback modifié : retourne une liste vide
        return List.of();

    }

    // ── Supprimer une séance ──
    @Transactional
    public void deleteSession(Long id) {
        if (!sessionRepository.existsById(id)) {
            throw new RuntimeException("Training session not found");
        }
        sessionRepository.deleteById(id);
    }

    // ── Mettre à jour une séance ──
    @Transactional
    public TrainingSession updateSession(Long sessionId,
                                         TrainingSession updated) {
        TrainingSession existing = sessionRepository.findById(sessionId)
                .orElseThrow(() ->
                        new RuntimeException("Training session not found"));

        existing.setDate(updated.getDate());
        existing.setDuration(updated.getDuration());
        existing.setIntensity(updated.getIntensity());
        existing.setWeightLifted(updated.getWeightLifted());
        existing.setFatigueScore(updated.getFatigueScore());
        existing.setLoadBalanceScore(updated.getLoadBalanceScore());
        existing.setAclRiskScore(updated.getAclRiskScore());
        existing.setRecoveryDaysPerWeek(updated.getRecoveryDaysPerWeek());

        // ── NIVEAU 2 : mise à jour painLevel et warmupDone ──
        if (updated.getPainLevel() != null)  existing.setPainLevel(updated.getPainLevel());
        if (updated.getWarmupDone() != null) existing.setWarmupDone(updated.getWarmupDone());

        return sessionRepository.save(existing);
    }
}