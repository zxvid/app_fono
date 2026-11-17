import 'package:flutter/material.dart';

class TributeScreen extends StatefulWidget {
  const TributeScreen({super.key});

  @override
  State<TributeScreen> createState() => _TributeScreenState();
}

class _TributeScreenState extends State<TributeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Header animations
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // Image animations
  late Animation<double> _imageFade;
  late Animation<double> _imageScale;

  // Salah Card animations
  late Animation<double> _salahFade;
  late Animation<Offset> _salahSlide;

  // Robbo Card animations
  late Animation<double> _robboFade;
  late Animation<Offset> _robboSlide;

  // Footer animations
  late Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animación de desvanecimiento e inclinación para el cabezal
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0.0, -0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
          ),
        );

    // Animación de desvanecimiento y escala para la imagen principal
    _imageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _imageScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Animación de desvanecimiento y deslizamiento para la tarjeta de Salah
    _salahFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _salahSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
          ),
        );

    // Animación de desvanecimiento y deslizamiento para la tarjeta de Robbo
    _robboFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
      ),
    );
    _robboSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
          ),
        );

    // Animación del texto de pie de página
    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    // Iniciar la animación al cargar la pantalla
    _controller.forward();

    // Pre-cargar imágenes para asegurar que estén listas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('pics/tribute.jpg'), context);
      precacheImage(const AssetImage('pics/salah.jpg'), context);
      precacheImage(const AssetImage('pics/robbo.jpg'), context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFC8102E), // Liverpool Red
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.06,
          vertical: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animación del Header (Copa, Fénix, Títulos)
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: size.width * 0.1 > 40 ? 40 : size.width * 0.1,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '🐦‍🔥',
                          style: TextStyle(
                            fontSize: size.width * 0.1 > 40
                                ? 40
                                : size.width * 0.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: size.width * 0.1 > 40 ? 40 : size.width * 0.1,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'THANK YOU LEGENDS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.07 > 28
                            ? 28
                            : size.width * 0.07,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A tribute to Mo Salah and Andy Robertson',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: size.width * 0.04 > 16
                            ? 16
                            : size.width * 0.04,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Imagen principal de tributo con Fade e Scale animados
            FadeTransition(
              opacity: _imageFade,
              child: ScaleTransition(
                scale: _imageScale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'pics/tribute.jpg',
                    fit: BoxFit
                        .fitWidth, // Render complete image without cropping
                    filterQuality:
                        FilterQuality.high, // Ensure maximum high definition
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                              size: 50,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Check pics/tribute.jpg',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Tarjeta de Mo Salah con Fade y Slide
            FadeTransition(
              opacity: _salahFade,
              child: SlideTransition(
                position: _salahSlide,
                child: _buildPlayerCard(
                  context,
                  name: 'Mohamed Salah',
                  nickname: 'The Egyptian King',
                  imageUrl: 'pics/salah.jpg',
                  chant:
                      'Mo Salah! Mo Salah! Mo Salah!\nRunning down the wing\nSalah la la la la la la la\nThe Egyptian King!',
                  description:
                      'Thank you Mo for every goal, for every joy and for being the driving force that inspired us never to give up. Your legacy at Anfield is eternal.',
                  matches: '349',
                  goals: '211',
                  assists: '89',
                  collectiveTitles: [
                    'Premier League (2) 🏆',
                    'Champions League 🇪🇺',
                    'FIFA Club World Cup 🌍',
                    'FA Cup 🏴󠁧󠁢󠁥󠁮󠁧󠁿',
                    'EFL Cup (2) 🥤',
                    'UEFA Super Cup 🇪🇺',
                    'Community Shield 🛡️',
                  ],
                  individualTitles: [
                    'PFA Players\' Player of the Year (2) 🥇',
                    'FWA Footballer of the Year (2) ✍️',
                    'Premier League Golden Boot (3) ⚽',
                    'Playmaker of the Season 🎯',
                    'FIFA Puskás Award 👑',
                    'African Footballer of the Year (2) 🌍',
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tarjeta de Andy Robertson con Fade y Slide
            FadeTransition(
              opacity: _robboFade,
              child: SlideTransition(
                position: _robboSlide,
                child: _buildPlayerCard(
                  context,
                  name: 'Andy Robertson',
                  nickname: 'Robbo',
                  imageUrl: 'pics/robbo.jpg',
                  chant: 'Oh Andy, Andy!\nAndy Andy Andy\nAndy Robertson!',
                  description:
                      'Thank you Andy for your tireless dedication, for defending our colours with all your heart, and for showing us that anything is possible with hard work.',
                  matches: '297',
                  goals: '11',
                  assists: '65',
                  collectiveTitles: [
                    'Premier League (2) 🏆',
                    'Champions League 🇪🇺',
                    'FIFA Club World Cup 🌍',
                    'FA Cup 🏴󠁧󠁢󠁥󠁮󠁧󠁿',
                    'EFL Cup (2) 🥤',
                    'UEFA Super Cup 🇪🇺',
                    'Community Shield 🛡️',
                  ],
                  individualTitles: [
                    'PFA Team of the Year (2) ⭐',
                    'UEFA Champions League Squad 🇪🇺',
                    'ESM Team of the Year 🌟',
                    'All-Time PL Defender Assists Record 🎯',
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Pie de página con You'll Never Walk Alone y el Fénix animado
            FadeTransition(
              opacity: _footerFade,
              child: Column(
                children: [
                  Text(
                    'YOU\'LL NEVER WALK ALONE 🐦‍🔥',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.05 > 20 ? 20 : size.width * 0.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
    BuildContext context, {
    required String name,
    required String nickname,
    required String imageUrl,
    required String chant,
    required String description,
    required String matches,
    required String goals,
    required String assists,
    required List<String> collectiveTitles,
    required List<String> individualTitles,
  }) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          // Player Image - FIXED SIZE AND FIT
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality
                    .high, // Ensure maximum high definition rendering
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white10,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white24,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.055 > 22 ? 22 : size.width * 0.055,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            nickname,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          // Fila de Estadísticas (Matches, Goals, Assists)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Matches', matches),
              _buildStatItem('Goals', goals),
              _buildStatItem('Assists', assists),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Títulos Colectivos
          _buildTitlesSection(
            title: 'COLLECTIVE TITLES',
            titles: collectiveTitles,
            icon: Icons.emoji_events,
          ),
          const SizedBox(height: 16),

          // Distinciones Individuales
          _buildTitlesSection(
            title: 'INDIVIDUAL HONOURS',
            titles: individualTitles,
            icon: Icons.workspace_premium,
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'THE CHANT',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  chant,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'serif',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitlesSection({
    required String title,
    required List<String> titles,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: titles
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
