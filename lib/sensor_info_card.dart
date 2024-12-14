import 'package:flutter/material.dart';

class SensorInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isDanger;
  final IconData icon;

  const SensorInfoCard({
    Key? key,
    required this.title,
    required this.value,
    this.isDanger = false,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDanger ? Colors.red[100] : Colors.white,
      elevation: 2, // Mengurangi elevasi
      margin: const EdgeInsets.symmetric(vertical: 4), // Mengurangi margin
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Mengurangi padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: isDanger ? Colors.red : Colors.black), // Mengurangi ukuran ikon
                const SizedBox(width: 8), // Mengurangi jarak antara ikon dan teks
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16, // Mengurangi ukuran font
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16, // Mengurangi ukuran font
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
