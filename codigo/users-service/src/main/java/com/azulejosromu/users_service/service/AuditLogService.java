package com.azulejosromu.users_service.service;

import com.azulejosromu.users_service.model.AuditLog;
import com.azulejosromu.users_service.repository.AuditLogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AuditLogService {

    @Autowired
    private AuditLogRepository auditLogRepository;

    public List<AuditLog> findAll() {
        return auditLogRepository.findAll();
    }

    public List<AuditLog> findByUserId(Long userId) {
        return auditLogRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<AuditLog> findByEntityTypeAndEntityId(String entityType, Long entityId) {
        return auditLogRepository.findByEntityTypeAndEntityId(entityType, entityId);
    }

    public List<AuditLog> findByAction(String action) {
        return auditLogRepository.findByAction(action);
    }

    public List<AuditLog> findByDateRange(LocalDateTime start, LocalDateTime end) {
        return auditLogRepository.findByCreatedAtBetween(start, end);
    }

    @Transactional
    public AuditLog logAction(Long userId, String username, String action, String entityType, Long entityId, String description) {
        AuditLog log = new AuditLog();
        log.setUserId(userId);
        log.setUsername(username);
        log.setAction(action);
        log.setEntityType(entityType);
        log.setEntityId(entityId);
        log.setDescription(description);
        log.setCreatedAt(LocalDateTime.now());
        return auditLogRepository.save(log);
    }

    @Transactional
    public AuditLog logChange(Long userId, String username, String action, String entityType, Long entityId,
                              String oldValue, String newValue, String description) {
        AuditLog log = new AuditLog();
        log.setUserId(userId);
        log.setUsername(username);
        log.setAction(action);
        log.setEntityType(entityType);
        log.setEntityId(entityId);
        log.setOldValue(oldValue);
        log.setNewValue(newValue);
        log.setDescription(description);
        log.setCreatedAt(LocalDateTime.now());
        return auditLogRepository.save(log);
    }
}
