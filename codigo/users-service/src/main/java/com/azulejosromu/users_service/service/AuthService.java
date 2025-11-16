package com.azulejosromu.users_service.service;

import com.azulejosromu.users_service.model.User;
import com.azulejosromu.users_service.security.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Service
public class AuthService {

    @Autowired
    private UserService userService;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private AuditLogService auditLogService;

    public Map<String, Object> login(String username, String password) {
        Map<String, Object> response = new HashMap<>();

        Optional<User> userOpt = userService.findByUsername(username);

        if (userOpt.isEmpty()) {
            response.put("success", false);
            response.put("message", "Usuario no encontrado");
            return response;
        }

        User user = userOpt.get();

        if (!user.getActive()) {
            response.put("success", false);
            response.put("message", "Usuario inactivo");
            return response;
        }

        if (!userService.validatePassword(password, user.getPassword())) {
            response.put("success", false);
            response.put("message", "Contraseña incorrecta");
            return response;
        }

        // Generar token JWT
        String token = jwtService.generateToken(user);

        // Actualizar último login
        userService.updateLastLogin(user.getId());

        // Registrar en audit log
        auditLogService.logAction(user.getId(), user.getUsername(), "LOGIN", "User", user.getId(), "Usuario inició sesión");

        response.put("success", true);
        response.put("token", token);
        response.put("user", user);
        response.put("message", "Login exitoso");

        return response;
    }

    public Map<String, Object> validateToken(String token) {
        Map<String, Object> response = new HashMap<>();

        if (jwtService.validateToken(token)) {
            String username = jwtService.getUsernameFromToken(token);
            String role = jwtService.getRoleFromToken(token);
            Long userId = jwtService.getUserIdFromToken(token);

            response.put("valid", true);
            response.put("username", username);
            response.put("role", role);
            response.put("userId", userId);
        } else {
            response.put("valid", false);
            response.put("message", "Token inválido o expirado");
        }

        return response;
    }
}
