package com.example.project_backend.Repository;

import com.example.project_backend.Entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MemberRepository extends JpaRepository<Member,Long> {
}
