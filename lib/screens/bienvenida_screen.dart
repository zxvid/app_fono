import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'tribute_screen.dart';
import '../api_service.dart';

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // surface-container-lowest
              Color(0xFFE7F6FF), // surface-container-low
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative blobs (Responsive sizes)
            Positioned(
              top: -size.width * 0.1,
              left: -size.width * 0.1,
              child: Container(
                width: size.width * 0.6 > 250 ? 250 : size.width * 0.6,
                height: size.width * 0.6 > 250 ? 250 : size.width * 0.6,
                decoration: BoxDecoration(
                  color: const Color(0xFFB4EBFF).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.1,
              right: -size.width * 0.1,
              child: Container(
                width: size.width * 0.7 > 300 ? 300 : size.width * 0.7,
                height: size.width * 0.7 > 300 ? 300 : size.width * 0.7,
                decoration: BoxDecoration(
                  color: const Color(0xFF94CDF5).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration Placeholder / Graphic (Responsive size)
                            GestureDetector(
                              onLongPress: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const TributeScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: size.width * 0.6 > 250 ? 250 : size.width * 0.6,
                                height: size.width * 0.6 > 250 ? 250 : size.width * 0.6,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.spatial_audio_off_outlined,
                                      size: size.width * 0.25 > 100 ? 100 : size.width * 0.25,
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    ),
                                    Positioned(
                                      bottom: size.width * 0.05,
                                      right: size.width * 0.05,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                            )
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.hearing,
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          size: size.width * 0.06 > 24 ? 24 : size.width * 0.06,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'FonoSalud',
                              style: TextStyle(
                                fontSize: size.width * 0.08 > 32 ? 32 : size.width * 0.08,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bienvenidos a FonoSalud.\nTransformamos vidas a través de la comunicación.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width * 0.045 > 18 ? 18 : size.width * 0.045,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom Button (Responsive constraints)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Empezar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ApiService.logout(); // Limpiar cualquier sesión previa
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Entrar como invitado',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
