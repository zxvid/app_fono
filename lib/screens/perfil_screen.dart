import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'bienvenida_screen.dart';
import '../api_service.dart';

class PerfilScreen extends StatefulWidget {
  final String? userEmail;
  const PerfilScreen({super.key, this.userEmail});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late bool _isLoggedIn;
  late String _email;
  
  // Para la pestaña Configuración interactiva
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _email = widget.userEmail ?? "Invitado";
    _isLoggedIn = _email != "Invitado" && _email.trim().isNotEmpty;
  }

  void _showGuestWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Acceso Restringido'),
            ],
          ),
          content: const Text(
            'Inicia sesión o regístrate para poder acceder a esta opción y guardar tu historial médico de forma segura.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Iniciar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _showDatosPersonales(BuildContext context) {
    final name = _email.contains('@') ? _email.split('@')[0] : _email;
    final capitalizedName = name[0].toUpperCase() + name.substring(1);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mis Datos Personales',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 20),
              _buildDataRow(Icons.person_outline, 'Nombre Completo', '$capitalizedName Gómez'),
              _buildDataRow(Icons.email_outlined, 'Correo Electrónico', _email),
              _buildDataRow(Icons.badge_outlined, 'Rol del Usuario', 'Paciente FonoSalud'),
              _buildDataRow(Icons.phone_iphone_outlined, 'Número de Contacto', '+57 301 555 4321'),
              _buildDataRow(Icons.calendar_month_outlined, 'Miembro desde', '17 de Mayo de 2026'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  void _showHistorialMedico(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Historial Médico Clínico',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Resumen Clínico Reciente:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: const Text(
                  'Paciente actualmente en terapia de lenguaje por Lic. Sofía Delgado. Presenta avances notables en la fluidez del habla y articulación de fonemas. Próxima evaluación programada.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(height: 16),
              _buildDataRow(Icons.done_all, 'Diagnósticos Clínicos', 'Ninguno pendiente'),
              _buildDataRow(Icons.checklist, 'Tratamientos Activos', 'Ejercicios de vocalización diarios'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showConfiguracion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ajustes de Configuración',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Notificaciones Push', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Alertas médicas, recordatorios de citas y reportes.'),
                    value: _notificationsEnabled,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (bool value) {
                      setModalState(() {
                        _notificationsEnabled = value;
                      });
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Modo Oscuro', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Cambia el aspecto visual de la aplicación.'),
                    value: _darkModeEnabled,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (bool value) {
                      setModalState(() {
                        _darkModeEnabled = value;
                      });
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      // Pequeña notificación divertida
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? 'Modo oscuro activado (simulación)' : 'Modo claro activado (simulación)'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSoporte(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Soporte Técnico & Ayuda',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Tienes inconvenientes con FonoSalud? Nuestro equipo médico y técnico está disponible para atenderte.',
                style: TextStyle(color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildDataRow(Icons.support_agent_outlined, 'Línea de Atención', '+57 (601) 765-4321'),
              _buildDataRow(Icons.contact_mail_outlined, 'Correo electrónico', 'soporte@fonosalud.com'),
              _buildDataRow(Icons.map_outlined, 'Dirección Clínica Principal', 'Av. 19 # 104-50, Bogotá D.C.'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = _email.contains('@') ? _email.split('@')[0] : _email;
    final capitalizedName = name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : "Invitado";

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Profile Header (Dynamic)
          if (_isLoggedIn) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "I",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              capitalizedName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Paciente Activo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _email,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey[100],
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Usuario Invitado',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const Text(
                  '/',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'Registrarse',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 28),

          // Options List
          _buildOptionCard(
            context: context,
            icon: Icons.person_outline,
            title: 'Datos Personales',
            onTap: () {
              if (_isLoggedIn) {
                _showDatosPersonales(context);
              } else {
                _showGuestWarning(context);
              }
            },
          ),
          _buildOptionCard(
            context: context,
            icon: Icons.medical_information_outlined,
            title: 'Historial Médico',
            onTap: () {
              if (_isLoggedIn) {
                _showHistorialMedico(context);
              } else {
                _showGuestWarning(context);
              }
            },
          ),
          _buildOptionCard(
            context: context,
            icon: Icons.settings_outlined,
            title: 'Configuración',
            onTap: () {
              if (_isLoggedIn) {
                _showConfiguracion(context);
              } else {
                _showGuestWarning(context);
              }
            },
          ),
          _buildOptionCard(
            context: context,
            icon: Icons.help_outline,
            title: 'Ayuda y Soporte',
            onTap: () {
              _showSoporte(context);
            },
          ),
          
          const SizedBox(height: 28),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                ApiService.logout(); // Asegurar que se limpia la sesión
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const BienvenidaScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _isLoggedIn ? Colors.red : colorScheme.primary),
                foregroundColor: _isLoggedIn ? Colors.red : colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isLoggedIn ? Icons.logout : Icons.arrow_back),
                  const SizedBox(width: 8),
                  Text(
                    _isLoggedIn ? 'Cerrar Sesión' : 'Volver a Bienvenida',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
        onTap: onTap,
      ),
    );
  }
}
