package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.Subscription;
import com.example.project_backend.Entity.User;
import com.example.project_backend.Repository.MemberProfileRepository;
import com.example.project_backend.Repository.MemberRepository;
import com.example.project_backend.Repository.MessageRepository;
import com.example.project_backend.Repository.SubscriptionRepository;
import com.example.project_backend.Repository.TrainingSessionRepository;
import com.example.project_backend.Repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class MemberService {

    private final MemberRepository memberRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final MessageRepository messageRepository;
    private final TrainingSessionRepository trainingSessionRepository;
    private final UserRepository userRepository;
    private final MemberProfileRepository memberProfileRepository; // ← NOUVEAU

    public MemberService(MemberRepository memberRepository,
                         SubscriptionRepository subscriptionRepository,
                         MessageRepository messageRepository,
                         TrainingSessionRepository trainingSessionRepository,
                         UserRepository userRepository,
                         MemberProfileRepository memberProfileRepository) {
        this.memberRepository        = memberRepository;
        this.subscriptionRepository  = subscriptionRepository;
        this.messageRepository       = messageRepository;
        this.trainingSessionRepository = trainingSessionRepository;
        this.userRepository          = userRepository;
        this.memberProfileRepository = memberProfileRepository;
    }

    // ➜ Créer un membre sans abonnement
    public Member createMember(Member member) {
        return memberRepository.save(member);
    }

    // ➜ Ajouter une subscription à un membre existant
    public Subscription addSubscriptionToMember(Long memberId, Subscription subscription) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new RuntimeException("Member not found"));
        subscription.setMember(member);
        return subscriptionRepository.save(subscription);
    }

    // ➜ Get tous les membres
    public List<Member> getAllMembers() {
        return memberRepository.findAll();
    }

    // ➜ Get membre par ID
    public Member getMemberById(Long id) {
        return memberRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Member not found"));
    }

    // ➜ Supprimer membre — ordre correct pour respecter les FK
    @Transactional
    public void deleteMember(Long id) {
        if (!memberRepository.existsById(id)) {
            throw new RuntimeException("Member not found");
        }

        // 1. Supprimer les messages liés au membre (FK message.member_id)
        messageRepository.deleteByMemberId(id);

        // 2. Trouver le User lié et dissocier + supprimer ses messages admin
        userRepository.findAll().stream()
                .filter(u -> u.getMember() != null && u.getMember().getId().equals(id))
                .findFirst()
                .ifPresent(user -> {
                    messageRepository.deleteBySenderId(user.getId());
                    messageRepository.deleteByReceiverId(user.getId());
                    user.setMember(null);
                    userRepository.save(user);
                    userRepository.delete(user);
                });

        // 3. Supprimer les séances
        trainingSessionRepository.deleteAll(
                trainingSessionRepository.findByMemberId(id));

        // 4. Supprimer les abonnements
        subscriptionRepository.deleteAll(
                subscriptionRepository.findByMemberId(id));

        // 5. ← NOUVEAU : Supprimer le profil IA si il existe
        if (memberProfileRepository.existsByMemberId(id)) {
            memberProfileRepository.deleteByMemberId(id);
        }

        // 6. Supprimer le membre
        memberRepository.deleteById(id);
    }

    // ➜ Update membre (uniquement infos de base, pas abonnement)
    public Member updateMember(Long memberId, Member updatedMember) {
        Member existingMember = memberRepository.findById(memberId)
                .orElseThrow(() -> new RuntimeException("Member not found"));

        existingMember.setFullName(updatedMember.getFullName());
        existingMember.setAge(updatedMember.getAge());
        existingMember.setWeight(updatedMember.getWeight());
        existingMember.setHeight(updatedMember.getHeight());
        existingMember.setRegistrationDate(updatedMember.getRegistrationDate());
        existingMember.setGender(updatedMember.getGender());

        return memberRepository.save(existingMember);
    }
}