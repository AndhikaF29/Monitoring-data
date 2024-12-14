import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sensor_data.dart';


class ApiService {
  final String apiUrl =
      'https://rc-research-mining-api.vercel.app/api/sensordata/all';
  final int intervalSeconds = 5; // Interval waktu polling dalam detik
  Timer? _pollingTimer;
  bool _isPolling = false;

  // Stream untuk mendapatkan data sensor secara berkala
  Stream<SensorData?> getSensorDataStream({required int? hours}) async* {
    _isPolling = true;
    
    while (_isPolling) {
      try {
        List<SensorData> data = await fetchSensorData(hours: hours);

        if (data.isNotEmpty) {
          // Urutkan berdasarkan waktu terbaru
          data.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          yield data.first; // Mengirimkan data terbaru
        } else {
          print('No data found after filtering');
          yield null;
        }
      } catch (e) {
        print('Error in stream: $e');
        yield null;
      }

      try {
        await Future.delayed(Duration(seconds: intervalSeconds));
      } catch (e) {
        print('Error during delay: $e');
        _isPolling = false;
      }
    }
  }

  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
  }

  // Tambahkan dispose method
  void dispose() {
    stopPolling();
  }

  // Fungsi untuk mengambil data sensor dari API dengan filter waktu
  Future<List<SensorData>> fetchSensorData({int? hours}) async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<dynamic> data = jsonResponse['data'];

        print('Raw Data: $data'); // Debugging: Data mentah dari API

        if (hours != null) {
          DateTime now = DateTime.now();
          Duration filterDuration = Duration(hours: hours);

          // Filter data berdasarkan durasi
          data = data.where((sensor) {
            DateTime timestamp = DateTime.parse(sensor['timestamp']);
            return now.difference(timestamp) < filterDuration;
          }).toList();

          print('Filtered Data: $data'); // Debugging: Data setelah difilter
        } else {
          print('All Data: $data'); // Debugging: Jika semua data diambil
        }

        // Mengonversi data JSON menjadi objek SensorData
        return data.map((item) => SensorData.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  Future<List<SensorData>> fetchSensorDataByDateRange(DateTime start, DateTime end) async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (!jsonResponse.containsKey('data')) {
          throw Exception('Format data tidak valid');
        }

        List<dynamic> allData = jsonResponse['data'];
        var filteredData = allData.where((item) {
          try {
            DateTime timestamp = DateTime.parse(item['timestamp']);
            return timestamp.isAfter(start) && timestamp.isBefore(end.add(const Duration(days: 1)));
          } catch (e) {
            print('Error parsing timestamp: $e');
            return false;
          }
        }).toList();

        return filteredData.map((item) {
          try {
            return SensorData.fromJson(Map<String, dynamic>.from(item));
          } catch (e) {
            print('Error converting item: $e');
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchSensorDataByDateRange: $e');
      rethrow;
    }
  }
}
