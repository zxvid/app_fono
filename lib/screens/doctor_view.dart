import 'package:flutter/material.dart';
import '../api_service.dart';
import 'm&p_screen.dart';

class DoctorView extends StatefulWidget {
  final String doctorName;
  final Map<String, dynamic>? activeAppointment;
  final void Function(int) onTabChange;

  const DoctorView({
    super.key,
    required this.doctorName,
    required this.activeAppointment,
    required this.onTabChange,
  });

  @override
  State<DoctorView> createState() => _DoctorViewState();
}

class _DoctorViewState extends State<DoctorView> {
  int _currentTab = 0;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotificationsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
    _fetchNotifications();
  }

  Future<void> _fetchDoctorData() async {
    setState(() => _isLoading = true);
    try {
      final appointments = await ApiService.obtenerCitasDoctor();
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching doctor data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifs = await ApiService.obtenerNotificaciones();
      setState(() {
        _notifications = notifs;
        _unreadNotificationsCount = notifs.where((n) => n['leida'] == 0).length;
      });
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }

  void _showNotificationsPanel() {
    // Marcar como leídas en el backend
    ApiService.marcarNotificacionesLeidas();
    setState(() {
      _unreadNotificationsCount = 0;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Notificaciones Médicas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_notifications.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text('No hay notificaciones recientes'),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.grey[100]),
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          final isAgendada = n['tipo'] == 'AGENDADA';
                          
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isAgendada ? Colors.green : Colors.red).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAgendada ? Icons.event_available : Icons.event_busy,
                                color: isAgendada ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(
                              n['titulo'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(n['descripcion'] ?? ''),
                          );
                        },
                      ),
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

  String _formatTime(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      int hour = dt.hour;
      String ampm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (e) {
      return "--:--";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.medical_services, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel Médico',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  widget.doctorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _unreadNotificationsCount > 0
                ? Badge(
                    backgroundColor: Colors.red,
                    label: Text(
                      '$_unreadNotificationsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    child: const Icon(Icons.notifications_none_outlined, color: Colors.black54),
                  )
                : const Icon(Icons.notifications_none_outlined, color: Colors.black54),
            onPressed: _showNotificationsPanel,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildAgendaTab(),
          _buildPacientesTab(),
          const HistorialScreen(),
          _buildPerfilTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) {
            setState(() {
              _currentTab = index;
            });
          },
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Pacientes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'M&P',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _fetchDoctorData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildDoctorHero(),
          const SizedBox(height: 24),
          const Text(
            'Resumen de Hoy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Citas Hoy', _appointments.length.toString(), Icons.event, Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard('Pacientes', _appointments.map((e) => e['idPaciente']['id']).toSet().length.toString(), Icons.people, Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Próximas Citas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _fetchDoctorData,
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_appointments.isEmpty)
            _buildEmptyState()
          else
            ..._appointments.map((cita) {
              final paciente = cita['idPaciente'] ?? {};
              return _buildAppointmentItem(
                paciente['nombre'] ?? 'Paciente',
                _formatTime(cita['fecha_hora'] ?? ''),
                cita['sintomas'] ?? 'Sin síntomas reportados',
                'https://i.pravatar.cc/150?u=${paciente['id']}',
                onTap: () => _showAppointmentDetails(cita),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildDoctorHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Hola de nuevo!',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            widget.doctorName,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Text(
                  'Especialista Verificado',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(Icons.add_chart, 'Nuevo\nReporte', Colors.purple),
            _buildActionButton(Icons.history, 'Historial\nClínico', Colors.teal),
            _buildActionButton(Icons.videocam, 'Tele\nconsulta', Colors.indigo),
            _buildActionButton(Icons.more_horiz, 'Más', Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No tienes citas para hoy',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const Text(
              '¡Aprovecha para revisar tus reportes!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> cita) {
    final paciente = cita['idPaciente'] ?? {};
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Cita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paciente: ${paciente['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Correo: ${paciente['user']}'),
            const SizedBox(height: 12),
            const Text('Síntomas / Motivo:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(cita['sintomas'] ?? 'No especificado'),
            const SizedBox(height: 12),
            Text('Fecha: ${cita['fecha_hora'].toString().split('T')[0]}'),
            Text('Hora: ${_formatTime(cita['fecha_hora'])}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad de diagnóstico próximamente')),
              );
            },
            child: const Text('Atender'),
          ),
        ],
      ),
    );
  }

  Widget _buildPacientesTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Obtener pacientes únicos de las citas
    final pacientesUnicos = <int, Map<String, dynamic>>{};
    for (var cita in _appointments) {
      final p = cita['idPaciente'];
      if (p != null && p['id'] != null) {
        pacientesUnicos[p['id']] = p;
      }
    }

    final listaPacientes = pacientesUnicos.values.toList();

    return RefreshIndicator(
      onRefresh: _fetchDoctorData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar paciente...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (listaPacientes.isEmpty)
            const Center(child: Text('No hay pacientes registrados.', style: TextStyle(color: Colors.grey)))
          else
            ...listaPacientes.map((p) => _buildPatientCard(
              p['nombre'] ?? 'Sin nombre',
              'ID: #${p['id']}',
              'Rol: ${p['role']}',
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildPerfilTab() {
    String profileImg = 'https://img.freepik.com/free-photo/doctor-offering-medical-tele-consultation-v_23-2149329007.jpg';
    if (widget.doctorName.contains('Orozco')) {
      profileImg = 'https://img.freepik.com/free-photo/handsome-young-male-doctor-with-stethoscope-standing-against-blue-background_662251-343.jpg';
    } else if (widget.doctorName.contains('Toscano')) {
      profileImg = 'https://img.freepik.com/free-photo/expressive-young-man-posing-studio_23-2148886043.jpg';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(profileImg),
          ),
          const SizedBox(height: 16),
          Text(
            widget.doctorName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Especialista en Fonoaudiología',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildProfileOption(Icons.badge_outlined, 'Información Profesional'),
          _buildProfileOption(Icons.schedule, 'Horarios de Atención'),
          _buildProfileOption(Icons.settings_outlined, 'Configuración'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(String patient, String time, String type, String img, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(img)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(type, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(String name, String id, String lastVisit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$id • $lastVisit'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {},
    );
  }
}
