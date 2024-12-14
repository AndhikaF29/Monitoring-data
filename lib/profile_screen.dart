import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo1.webp', // Pastikan menambahkan logo di assets
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'RC MINE Sentinel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Versi 1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aplikasi monitoring keamanan tambang dengan menggunakan sensor untuk mendeteksi suhu, gas, kelembaban, getaran, dan infrared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            'Dikembangkan Oleh',
            [
              'Andhika Fajar Prayoga',
              '152022066',
              'Itenas',
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            'Fitur Utama',
            [
              'Monitoring Sensor Realtime',
              'Grafik Analisis Data',
              'Sistem Peringatan',
              'Riwayat Data Sensor',
              'Control RC',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      item,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
