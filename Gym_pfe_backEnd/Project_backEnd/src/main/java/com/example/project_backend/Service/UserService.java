package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.Role;
import com.example.project_backend.Entity.User;
import com.example.project_backend.Repository.MemberRepository;
import com.example.project_backend.Repository.UserRepository;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserService implements UserDetailsService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final MemberRepository memberRepository;

    public UserService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       MemberRepository memberRepository) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.memberRepository = memberRepository;
    }

    // REGISTER
    public User register(User user, Long memberId) {
        if (userRepository.existsByUsername(user.getUsername())) {
            throw new RuntimeException("Username déjà utilisé");
        }
        if (user.getEmail() != null &&
                userRepository.existsByEmail(user.getEmail())) {
            throw new RuntimeException("Email déjà utilisé");
        }
        if (user.getPhone() != null &&
                userRepository.existsByPhone(user.getPhone())) {
            throw new RuntimeException("Téléphone déjà utilisé");
        }

        user.setPassword(passwordEncoder.encode(user.getPassword()));

        if (user.getRole() == null) {
            user.setRole(Role.MEMBER);
        }

        if (memberId != null) {
            Member member = memberRepository.findById(memberId)
                    .orElseThrow(() ->
                            new RuntimeException("Member not found"));
            user.setMember(member);
        }

        return userRepository.save(user);
    }

    // FIND BY USERNAME
    public User findByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() ->
                        new RuntimeException("User not found"));
    }

    // FIND BY IDENTIFIER (username OU email OU téléphone)
    public User findByIdentifier(String identifier) {
        return userRepository.findByIdentifier(identifier)
                .orElseThrow(() ->
                        new RuntimeException("Utilisateur non trouvé"));
    }

    // SPRING SECURITY — supporte username OU email OU téléphone
    @Override
    public UserDetails loadUserByUsername(String identifier)
            throws UsernameNotFoundException {
        User user = userRepository.findByIdentifier(identifier)
                .orElseThrow(() ->
                        new UsernameNotFoundException(
                                "User not found: " + identifier));

        return new org.springframework.security.core.userdetails.User(
                user.getUsername(),
                user.getPassword(),
                List.of(new SimpleGrantedAuthority(
                        "ROLE_" + user.getRole().name()))
        );
    }
}