package com.mangetout.repository;

import com.mangetout.model.Couple;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface CoupleRepository extends MongoRepository<Couple, String> {

    Optional<Couple> findByInviteToken(String token);

    Optional<Couple> findByUser1IdOrUser2Id(String user1Id, String user2Id);
}
