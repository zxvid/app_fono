import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../api_service.dart';

class AgendarCitaScreen extends StatefulWidget {
  final int? initialSpecialty;
  final Function(int)? onAppointmentCreated;
  final bool isGuest;
  const AgendarCitaScreen({
    super.key,
    this.initialSpecialty,
    this.onAppointmentCreated,
    this.isGuest = false,
  });

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  int _currentStep = 1; // 1: Especialista, 2: Fecha/Hora, 3: Confirmar

  List<Map<String, dynamic>> _fonoaudiologos = [];
  bool _loadingFonos = true;
  int? _selectedFonoId;
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = "10:00 AM";
  final TextEditingController _sintomasController = TextEditingController();
  bool _isSaving = false;

  final List<String> _horasDisponibles = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "02:30 PM",
    "04:00 PM"
  ];

  @override
  void initState() {
    super.initState();
    _cargarFonoaudiologos();
  }

  @override
  void dispose() {
    _sintomasController.dispose();
    super.dispose();
  }

  Future<void> _cargarFonoaudiologos() async {
    setState(() {
      _loadingFonos = true;
    });

    try {
      final fonos = await ApiService.obtenerFonoaudiologos();
      setState(() {
        _fonoaudiologos = fonos;
        _loadingFonos = false;

        // Intentar seleccionar especialista según initialSpecialty
        if (widget.initialSpecialty != null && _fonoaudiologos.isNotEmpty) {
          final targetIndex = widget.initialSpecialty!;
          // 0: Dr. Jeison Zuñiga (Audiología)
          // 1: Dr. Orozco (Lenguaje)
          // 2: Dr. Toscano (Habla)
          if (targetIndex == 0 && _fonoaudiologos.any((f) => f['id'] == 1)) {
            _selectedFonoId = 1;
          } else if (targetIndex == 1 && _fonoaudiologos.any((f) => f['id'] == 2)) {
            _selectedFonoId = 2;
          } else if (targetIndex == 2 && _fonoaudiologos.any((f) => f['id'] == 3)) {
            _selectedFonoId = 3;
          } else {
            _selectedFonoId = _fonoaudiologos.first['id'];
          }
        } else if (_fonoaudiologos.isNotEmpty) {
          _selectedFonoId = _fonoaudiologos.first['id'];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingFonos = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AgendarCitaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSpecialty != oldWidget.initialSpecialty && widget.initialSpecialty != null) {
      final targetIndex = widget.initialSpecialty!;
      setState(() {
        if (targetIndex == 0 && _fonoaudiologos.any((f) => f['id'] == 1)) {
          _selectedFonoId = 1;
        } else if (targetIndex == 1 && _fonoaudiologos.any((f) => f['id'] == 2)) {
          _selectedFonoId = 2;
        } else if (targetIndex == 2 && _fonoaudiologos.any((f) => f['id'] == 3)) {
          _selectedFonoId = 3;
        }
      });
    }
  }

  Map<String, dynamic>? get _selectedFono {
    if (_selectedFonoId == null || _fonoaudiologos.isEmpty) return null;
    return _fonoaudiologos.firstWhere(
      (f) => f['id'] == _selectedFonoId,
      orElse: () => _fonoaudiologos.first,
    );
  }

  // Resuelve la foto correspondiente para la UI
  String _getFonoFoto(int id) {
    if (id == 1) return 'https://img.freepik.com/free-photo/doctor-offering-medical-tele-consultation-v_23-2149329007.jpg';
    if (id == 2) return 'https://img.freepik.com/free-photo/handsome-young-male-doctor-with-stethoscope-standing-against-blue-background_662251-343.jpg';
    return 'https://img.freepik.com/free-photo/expressive-young-man-posing-studio_23-2148886043.jpg';
  }

  String _getFonoEspecialidad(int id) {
    if (id == 1) return 'Audiología Pediátrica';
    if (id == 2) return 'Terapia de Lenguaje';
    return 'Fonoaudiólogo - Habla';
  }

  int _getSpecialtyIndex(int id) {
    if (id == 1) return 0;
    if (id == 2) return 1;
    return 2;
  }

  Future<void> _guardarCita() async {
    if (_selectedFonoId == null) return;

    // Quitar el foco antes de iniciar la solicitud asíncrona para ocultar el teclado
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      // Formatear la fecha y hora seleccionada
      // Parsear la hora (ej: "10:00 AM" o "02:30 PM") a formato 24h
      int hora = int.parse(_selectedTime.split(':')[0]);
      final minutos = int.parse(_selectedTime.split(':')[1].split(' ')[0]);
      final isPm = _selectedTime.contains('PM');
      if (isPm && hora < 12) hora += 12;
      if (!isPm && hora == 12) hora = 0;

      final fechaCompleta = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hora,
        minutos,
      );

      final result = await ApiService.crearCita(
        _selectedFonoId!,
        _sintomasController.text.trim(),
        fechaCompleta,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result['mode'] == 'server'
                        ? 'Cita agendada correctamente en el servidor.'
                        : 'Cita agendada correctamente (Modo Demostración).',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blueGrey.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (widget.onAppointmentCreated != null) {
          widget.onAppointmentCreated!(_getSpecialtyIndex(_selectedFonoId!));
        }

        setState(() {
          _currentStep = 1;
          _sintomasController.clear();
        });
      } else {
        // En caso de conflicto de horario o error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Horario Ocupado'),
              ],
            ),
            content: Text(
              result['message'] ??
                  'El especialista ya cuenta con una cita en el horario seleccionado. Por favor, elija otra fecha u hora.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Agendar Cita',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Siga los pasos para programar su atención.',
            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          
          if (widget.isGuest) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Modo Demo de Invitado',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explora y agenda citas de prueba. Regístrate para habilitar reservas reales y seguras.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepOrange.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Registrarse',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Stepper Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStep(context, '1', 'Especialista', _currentStep >= 1),
              Expanded(
                child: Divider(
                  color: _currentStep >= 2
                      ? colorScheme.primary
                      : Colors.grey.shade300,
                  thickness: 2,
                ),
              ),
              _buildStep(context, '2', 'Fecha y Hora', _currentStep >= 2),
              Expanded(
                child: Divider(
                  color: _currentStep >= 3
                      ? colorScheme.primary
                      : Colors.grey.shade300,
                  thickness: 2,
                ),
              ),
              _buildStep(context, '3', 'Confirmar', _currentStep >= 3),
            ],
          ),
          const SizedBox(height: 32),

          if (_currentStep == 1) ...[
            // Specialties Selection
            Text(
              'Seleccione su Fonoaudiólogo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            if (_loadingFonos)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_fonoaudiologos.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text('No se encontraron especialistas en el sistema.'),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _fonoaudiologos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final fono = _fonoaudiologos[index];
                  final fonoId = fono['id'] as int;
                  final isSelected = _selectedFonoId == fonoId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFonoId = fonoId;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage(_getFonoFoto(fonoId)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fono['nombre'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getFonoEspecialidad(fonoId),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  fono['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: colorScheme.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ] else if (_currentStep == 2) ...[
            Text(
              'Seleccione Fecha y Hora',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Mock Calendar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Horarios Disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _horasDisponibles.map((hora) {
                final isSelected = _selectedTime == hora;
                return ChoiceChip(
                  label: Text(
                    hora,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: colorScheme.primary,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTime = hora;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ] else if (_currentStep == 3) ...[
            Text(
              'Confirmar Cita Médica',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_selectedFono != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(_getFonoFoto(_selectedFonoId!)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFono!['nombre'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _getFonoEspecialidad(_selectedFonoId!),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1),
                    
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Fecha:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Hora:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTime,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            Text(
              'Sintomas u Observaciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sintomasController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej. Dificultad para vocalizar, dolor en el oído...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Action Button
          Row(
            children: [
              if (_currentStep > 1) ...[
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _currentStep--;
                              });
                            },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Atrás',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedFonoId == null || _isSaving
                        ? null
                        : () {
                            if (_currentStep < 3) {
                              setState(() {
                                _currentStep++;
                              });
                            } else {
                              _guardarCita();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _currentStep < 3
                                ? 'Siguiente Paso'
                                : 'Confirmar y Guardar',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    String title,
    bool isActive,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? colorScheme.primary : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? colorScheme.primary : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
