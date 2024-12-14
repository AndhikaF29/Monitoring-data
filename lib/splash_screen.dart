import 'package:flutter/material.dart';
import 'main.dart'; // Pastikan ini terhubung dengan file main.dart
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const SplashScreen({
    Key? key, 
    required this.toggleTheme, 
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animasi fade-in untuk elemen di splash screen
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Timer untuk navigasi ke layar utama setelah 3 detik
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SensorDataScreen(
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: widget.isDarkMode ? Colors.yellow : Colors.grey[800],
            ),
            onPressed: () => widget.toggleTheme(),
          ),
        ],
      ),
      backgroundColor:const Color.fromARGB(255, 0, 214, 252), // Warna latar belakang splash
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo aplikasi (Ganti dengan aset logo jika ada)
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/logo1.webp'), // Ganti dengan path logo
              ),
              SizedBox(height: 20),
              
              // Nama aplikasi dengan gaya
              Text(
                'RC MINE Sentinel',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 10),
              
              // Deskripsi singkat atau slogan aplikasi
              Text(
                'Your Reliable Mine Safety Companion',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 40),
              
              // Animasi loading
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
