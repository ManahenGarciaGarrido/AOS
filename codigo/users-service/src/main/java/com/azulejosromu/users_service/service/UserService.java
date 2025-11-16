package com.azulejosromu.users_service.service;

import com.azulejosromu.users_service.model.User;
import com.azulejosromu.users_service.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public List<User> findAll() {
        return userRepository.findAll();
    }

    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }

    public Optional<User> findByUsername(String username) {
        return userRepository.findByUsername(username);
    }

    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    public List<User> findByRole(User.UserRole role) {
        return userRepository.findByRole(role);
    }

    public List<User> findActiveUsers() {
        return userRepository.findByActiveTrue();
    }

    public List<User> findByDepartment(String department) {
        return userRepository.findByDepartment(department);
    }

    @Transactional
    public User save(User user) {
        user.setUpdatedAt(LocalDateTime.now());
        if (user.getId() == null) {
            user.setCreatedAt(LocalDateTime.now());
            // Encriptar contraseña solo para usuarios nuevos
            if (user.getPassword() != null && !user.getPassword().startsWith("$2a$")) {
                user.setPassword(passwordEncoder.encode(user.getPassword()));
            }
        }
        return userRepository.save(user);
    }

    @Transactional
    public User updatePassword(Long userId, String newPassword) {
        User user = findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
        user.setPassword(passwordEncoder.encode(newPassword));
        user.setUpdatedAt(LocalDateTime.now());
        return userRepository.save(user);
    }

    @Transactional
    public void deleteById(Long id) {
        User user = findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        user.setActive(false);
        user.setUpdatedAt(LocalDateTime.now());
        save(user);
    }

    public boolean validatePassword(String rawPassword, String encodedPassword) {
        return passwordEncoder.matches(rawPassword, encodedPassword);
    }

    @Transactional
    public void updateLastLogin(Long userId) {
        User user = findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
        user.setLastLogin(LocalDateTime.now());
        userRepository.save(user);
    }
}
