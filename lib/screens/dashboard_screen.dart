import 'package:flutter/material.dart';
import 'inicio_view.dart';
import 'agendar_cita_screen.dart';
import 'perfil_screen.dart';
import 'm&p_screen.dart';
import 'doctor_view.dart';
import '../api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String? userEmail;
  final String? userRole;
  const DashboardScreen({super.key, this.userEmail, this.userRole});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late String _userEmail;
  late String _userRole;
  int? _selectedSpecialtyIndex;

  Map<String, dynamic>? _activeAppointment;
  bool _loadingAppointments = true;

  // Para controlar las notificaciones
  int _unreadNotificationsCount = 2;
  final List<Map<String, String>> _notifications = [
    {
      "title": "¡Cita Programada!",
      "description":
          "Tu cita médica ha sido registrada exitosamente en nuestro sistema.",
      "time": "Hace 5 minutos",
      "icon": "calendar_today",
    },
    {
      "title": "Reporte de Audiometría Listo",
      "description":
          "El reporte de tus pruebas anteriores ya está disponible en la sección M&P.",
      "time": "Ayer",
      "icon": "assessment",
    },
    {
      "title": "Ejercicios de Vocalización",
      "description":
          "Recuerda completar tus terapias de voz recomendadas por tu especialista.",
      "time": "Hace 2 días",
      "icon": "record_voice_over",
    },
  ];

  @override
  void initState() {
    super.initState();
    _userEmail = widget.userEmail ?? "Invitado";
    _userRole = widget.userRole ?? "USER";
    _cargarCitas();
  }

  bool get _isLoggedIn =>
      _userEmail != "Invitado" && _userEmail.trim().isNotEmpty;

  String formatFechaHora(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      List<String> meses = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];
      List<String> dias = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ];
      String diaSemana = dias[dt.weekday - 1];
      String mes = meses[dt.month - 1];

      int hora = dt.hour;
      String ampm = 'AM';
      if (hora >= 12) {
        ampm = 'PM';
        if (hora > 12) hora -= 12;
      }
      if (hora == 0) hora = 12;
      String minutos = dt.minute.toString().padLeft(2, '0');

      return '$diaSemana ${dt.day} de $mes, $hora:$minutos $ampm';
    } catch (e) {
      return isoString;
    }
  }

  Map<String, dynamic> enriquecerCita(Map<String, dynamic> cita) {
    final fono = cita['idFonoaudiologo'] ?? {};
    final fonoId = fono['id'] ?? 0;
    final fonoNombre = fono['nombre'] ?? 'Especialista';
    final fechaHoraIso = cita['fecha_hora'] ?? '';

    String especialidad = 'Fonoaudiología';
    String foto = 'https://i.pravatar.cc/150?img=32';
    String consultorio = 'Consultorio 304 - Piso 3';
    int specialtyIndex = 0;

    if (fonoId == 1 || fonoNombre.toString().contains('Jeison')) {
      especialidad = 'Audiología Pediátrica';
      foto = 'https://img.freepik.com/free-photo/doctor-offering-medical-tele-consultation-v_23-2149329007.jpg';
      consultorio = 'Consultorio 304 - Piso 3';
      specialtyIndex = 0;
    } else if (fonoId == 2 || fonoNombre.toString().contains('Orozco')) {
      especialidad = 'Terapia de Lenguaje';
      foto = 'https://img.freepik.com/free-photo/handsome-young-male-doctor-with-stethoscope-standing-against-blue-background_662251-343.jpg';
      consultorio = 'Consultorio 201 - Piso 2';
      specialtyIndex = 1;
    } else if (fonoId == 3 || fonoNombre.toString().contains('Toscano')) {
      especialidad = 'Fonoaudiólogo - Habla';
      foto = 'https://img.freepik.com/free-photo/expressive-young-man-posing-studio_23-2148886043.jpg';
      consultorio = 'Consultorio 402 - Piso 4';
      specialtyIndex = 2;
    }

    return {
      'id': cita['id'],
      'nombreDoctor': fonoNombre,
      'especialidad': especialidad,
      'fotoDoctor': foto,
      'consultorio': consultorio,
      'fechaFormateada': formatFechaHora(fechaHoraIso),
      'specialtyIndex': specialtyIndex,
      'fechaRaw': fechaHoraIso,
      'sintomas': cita['sintomas'] ?? '',
    };
  }

  Future<void> _cargarCitas() async {
    if (!_isLoggedIn) {
      setState(() {
        _activeAppointment = null;
        _loadingAppointments = false;
      });
      return;
    }

    setState(() {
      _loadingAppointments = true;
    });

    try {
      final list = await ApiService.obtenerCitas();
      if (!mounted)
        return; // Verificar que el widget sigue montado antes de actualizar el estado
      setState(() {
        if (list.isNotEmpty) {
          _activeAppointment = enriquecerCita(list.first);
        } else {
          _activeAppointment = null;
        }
        _loadingAppointments = false;
      });
    } catch (e) {
      if (!mounted)
        return; // Verificar que el widget sigue montado antes de actualizar el estado
      setState(() {
        _loadingAppointments = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedSpecialtyIndex = null;
      _selectedIndex = index;
    });
  }

  void _showNotificationsPanel() {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (_notifications.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _notifications.clear();
                            });
                            setState(() {
                              _notifications.clear();
                            });
                          },
                          child: const Text('Limpiar todas'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_notifications.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes notificaciones',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: Colors.grey[100]),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          IconData getIcon(String? iconName) {
                            switch (iconName) {
                              case 'calendar_today':
                                return Icons.calendar_today;
                              case 'assessment':
                                return Icons.assessment_outlined;
                              case 'record_voice_over':
                                return Icons.record_voice_over_outlined;
                              default:
                                return Icons.notifications_none;
                            }
                          }

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(
                                  0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                getIcon(notification['icon']),
                                color: colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              notification['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notification['description'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notification['time'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _notifications.removeAt(index);
                                });
                                setModalState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _getCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _loadingAppointments
            ? const Center(child: CircularProgressIndicator())
            : InicioView(
                userName:
                    (ApiService.loggedInUserName != null &&
                        ApiService.loggedInUserName!.isNotEmpty)
                    ? ApiService.loggedInUserName!
                    : (_userEmail.contains('@')
                          ? _userEmail.split('@')[0]
                          : _userEmail),
                activeAppointment: _activeAppointment,
                onTabChange: (index) {
                  _onItemTapped(index);
                },
                onSelectSpecialty: (specialtyIndex) {
                  setState(() {
                    _selectedSpecialtyIndex = specialtyIndex;
                    _selectedIndex = 1; // Pestaña de agendar
                  });
                },
                onCancelAppointment: (citaId) async {
                  final success = await ApiService.cancelarCita(citaId);
                  if (!mounted) return;
                  if (success) {
                    setState(() {
                      _activeAppointment = null;
                      // Agregar notificación de cancelación
                      _notifications.insert(0, {
                        "title": "Cita Cancelada",
                        "description":
                            "Tu cita médica ha sido cancelada correctamente.",
                        "time": "Ahora mismo",
                        "icon": "calendar_today",
                      });
                      _unreadNotificationsCount++;
                    });
                    _cargarCitas();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cita cancelada con éxito.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al cancelar la cita.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              );
      case 1:
        return AgendarCitaScreen(
          initialSpecialty: _selectedSpecialtyIndex,
          isGuest: !_isLoggedIn,
          onAppointmentCreated: (specialtyIndex) {
            _cargarCitas(); // Refrescar desde backend
            setState(() {
              // Crear notificación de cita agendada
              String specialtyName = "Servicio Médico";
              if (specialtyIndex == 0) specialtyName = "Audiología";
              if (specialtyIndex == 1) specialtyName = "Terapia de Lenguaje";
              if (specialtyIndex == 2) specialtyName = "Terapia de Habla";

              _notifications.insert(0, {
                "title": "Nueva Cita Agendada",
                "description":
                    "Has programado una cita de $specialtyName con éxito.",
                "time": "Ahora mismo",
                "icon": "calendar_today",
              });
              _unreadNotificationsCount++;

              _selectedIndex = 0; // Volver al inicio
            });
          },
        );
      case 2:
        return PerfilScreen(userEmail: _userEmail);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si el usuario es un fonoaudiólogo, mostramos la vista de doctor directamente
    // Verificamos tanto el parámetro del widget como el estado global de ApiService
    final currentRole = widget.userRole ?? ApiService.loggedInUserRole;
    
    if (currentRole == 'FONAUDIOLOGO') {
      return DoctorView(
        doctorName: ApiService.loggedInUserName ?? _userEmail.split('@')[0],
        activeAppointment: _activeAppointment,
        onTabChange: _onItemTapped,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.healing_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'FonoSalud',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: _unreadNotificationsCount > 0
                ? Badge(
                    backgroundColor: Colors.red,
                    label: Text(
                      '$_unreadNotificationsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    child: const Icon(Icons.notifications_none, size: 26),
                  )
                : const Icon(Icons.notifications_none, size: 26),
            onPressed: _showNotificationsPanel,
          ),
          const SizedBox(width: 8),
        ],
        automaticallyImplyLeading: false,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _getCurrentView(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Citas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
