import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Configuración de URL base para desarrollo local
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    try {
      if (Platform.isAndroid) {
        // IP de pasarela en emulador Android
        return 'http://10.0.2.2:5000';
      }
    } catch (_) {}
    return 'http://localhost:5000';
  }

  // Token en memoria para la sesión activa
  static String? sessionToken;
  static String? loggedInUserEmail;
  static String? loggedInUserName;
  static String? loggedInUserRole;
  
  // Estado en línea de la API física
  static bool isOnline = false;

  // Método para decodificar el payload del JWT
  static Map<String, dynamic> decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded);
    } catch (e) {
      print("Error decodificando JWT: $e");
      return {};
    }
  }

  // Datos mock en memoria para el modo demostración o si el servidor está caído
  static List<Map<String, dynamic>> mockFonoaudiologos = [
    {"id": 1, "nombre": "Dr. Jeison Zuñiga", "email": "jeison"},
    {"id": 2, "nombre": "Dr. Orozco", "email": "orozco"},
    {"id": 3, "nombre": "Dr. Toscano", "email": "toscano"},
  ];

  static List<Map<String, dynamic>> mockCitas = [
    {
      "id": 1001,
      "idPaciente": {
        "id": 4,
        "nombre": "Carlos",
        "user": "carlos",
        "role": "USER"
      },
      "idFonoaudiologo": {
        "id": 1,
        "nombre": "Dr. Jeison Zuñiga",
        "email": "jeison"
      },
      "sintomas": "Dificultad de articulación del fonema /r/.",
      "fecha_hora": "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}T10:30:00"
    },
    {
      "id": 1002,
      "idPaciente": {
        "id": 99,
        "nombre": "David",
        "user": "david@mail.com",
        "role": "USER"
      },
      "idFonoaudiologo": {
        "id": 1,
        "nombre": "Dr. Jeison Zuñiga",
        "email": "jeison"
      },
      "sintomas": "Zumbido persistente en el oído derecho.",
      "fecha_hora": "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${(DateTime.now().day + 1).toString().padLeft(2, '0')}T09:00:00"
    }
  ];

  // Comprobar la salud de la API local
  static Future<bool> checkServerHealth() async {
    try {
      // Intentamos el login como ping de salud (ya que Flask no tiene un / root por defecto)
      final response = await http.get(Uri.parse('$baseUrl/login')).timeout(const Duration(seconds: 2));
      // Flask responderá 405 (Method Not Allowed) porque es GET en lugar de POST, pero confirma que está vivo
      isOnline = response.statusCode != 404; 
      return isOnline;
    } catch (e) {
      isOnline = false;
      print("El servidor Flask no está activo: $e");
      return false;
    }
  }

  // Iniciar sesión
  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Forzar verificación de servidor
    await checkServerHealth();

    if (!isOnline) {
      return {
        'success': false,
        'message': 'El servidor FonoSalud no está disponible. Por favor, inicie el backend IA (api.py).'
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // El backend de IA devuelve { "success": true, "user": { ... } }
        if (data['success'] == true) {
          final user = data['user'];
          loggedInUserEmail = email;
          loggedInUserName = user['nombre'];
          loggedInUserRole = user['role'];
          sessionToken = "fake-jwt-token-${user['id']}"; // El backend IA no usa JWT aún, generamos uno local

          return {
            'success': true,
            'token': sessionToken,
            'email': loggedInUserEmail,
            'nombre': loggedInUserName,
            'role': loggedInUserRole,
            'mode': 'server'
          };
        }
      }
      
      final errorMsg = jsonDecode(response.body)['error'] ?? 'Error de credenciales';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Registro de usuario
  static Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    await checkServerHealth();

    if (!isOnline) {
      return {
        'success': false,
        'message': 'El servidor FonoSalud no está disponible.'
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'user': email,
          'contrasena': password,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        sessionToken = data['jwt'];
        
        final payload = decodeJwt(sessionToken!);
        loggedInUserEmail = payload['sub'] ?? email;
        loggedInUserName = payload['name'] ?? nombre;
        loggedInUserRole = payload['role'] ?? 'USER';

        return {
          'success': true,
          'token': sessionToken,
          'email': loggedInUserEmail,
          'nombre': loggedInUserName,
          'role': loggedInUserRole,
          'mode': 'server'
        };
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al registrar el usuario';
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener lista de fonoaudiólogos
  static Future<List<Map<String, dynamic>>> obtenerFonoaudiologos() async {
    await checkServerHealth();

    if (!isOnline) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fonoaudiologos'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print("Error al cargar fonoaudiólogos de la API: $e");
    }
    return [];
  }

  // Obtener citas del paciente autenticado
  static Future<List<Map<String, dynamic>>> obtenerCitas() async {
    if (sessionToken == null) return [];
    
    await checkServerHealth();

    if (!isOnline) return [];

    try {
      // Extraemos el ID del paciente del token falso "fake-jwt-token-<id>"
      final pacienteId = sessionToken!.split('-').last;

      final response = await http.get(
        Uri.parse('$baseUrl/paciente/$pacienteId/citas'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['citas'] ?? [];
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print("Error al cargar citas del paciente: $e");
    }
    return [];
  }

  // Obtener citas asignadas al doctor autenticado
  static Future<List<Map<String, dynamic>>> obtenerCitasDoctor() async {
    if (sessionToken == null) return [];

    await checkServerHealth();

    if (!isOnline) return [];

    try {
      // El backend IA usa el formato /doctor/<id>/citas
      // Extraemos el ID del token falso que generamos: "fake-jwt-token-<id>"
      final doctorId = sessionToken!.split('-').last;
      
      final response = await http.get(
        Uri.parse('$baseUrl/doctor/$doctorId/citas'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['citas'] ?? [];
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print("Error al cargar citas del doctor de la API: $e");
    }
    return [];
  }

  // Crear cita
  static Future<Map<String, dynamic>> crearCita(int idFonoaudiologo, String sintomas, DateTime fechaHora) async {
    if (sessionToken == null) {
      return {'success': false, 'message': 'Debe iniciar sesión para agendar una cita.'};
    }

    final fechaHoraStr = fechaHora.toIso8601String().split('.')[0]; // Formato "YYYY-MM-DDTHH:MM:SS"
    await checkServerHealth();

    if (!isOnline) {
      return {'success': false, 'message': 'Servidor no disponible para guardar la cita.'};
    }

    try {
      // Extraemos el ID del paciente del token falso "fake-jwt-token-<id>"
      final pacienteId = int.parse(sessionToken!.split('-').last);

      final response = await http.post(
        Uri.parse('$baseUrl/cita'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_paciente': pacienteId,
          'id_fono': idFonoaudiologo,
          'sintomas': sintomas,
          'fecha_hora': fechaHoraStr
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'cita': data, 'mode': 'server'};
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Error al agendar cita';
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión al agendar: $e'};
    }
  }

  // Cancelar cita
  static Future<bool> cancelarCita(int idCita) async {
    await checkServerHealth();

    if (!isOnline) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cita/$idCita'),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      print("Error al cancelar cita en servidor: $e");
      return false;
    }
  }

  // Obtener notificaciones del usuario (paciente o doctor)
  static Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    if (sessionToken == null) return [];

    await checkServerHealth();
    if (!isOnline) return [];

    try {
      final userId = sessionToken!.split('-').last;
      final response = await http.get(
        Uri.parse('$baseUrl/notificaciones/$userId'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['notificaciones'] ?? [];
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print("Error al obtener notificaciones: $e");
    }
    return [];
  }

  // Marcar notificaciones como leídas
  static Future<void> marcarNotificacionesLeidas() async {
    if (sessionToken == null) return;

    await checkServerHealth();
    if (!isOnline) return;

    try {
      final userId = sessionToken!.split('-').last;
      await http.post(
        Uri.parse('$baseUrl/notificaciones/$userId/leer'),
      ).timeout(const Duration(seconds: 2));
    } catch (e) {
      print("Error al marcar notificaciones como leídas: $e");
    }
  }

  // Cerrar sesión
  static void logout() {
    sessionToken = null;
    loggedInUserEmail = null;
    loggedInUserName = null;
    loggedInUserRole = null;
    isOnline = false;
  }
}
