import 'dart:math' show min, max;

class SensorData {
  final double temperature;
  final double gas;
  final double ph;
  final double humidity;
  final bool getaran; // Pastikan ini boolean
  final bool espconnected;
  final bool infrared;
  final DateTime timestamp;
  bool isConnected;

  static double temperatureThreshold = 35.0; // Ambang batas suhu
  static double gasThreshold = 400.0; // Ambang batas gas
  static double phThreshold = 7.0; // Ambang batas pH
  static double humidityThreshold = 80.0; // Ambang batas kelembapan

  SensorData({
    required this.temperature,
    required this.gas,
    required this.ph,
    required this.humidity,
    required this.getaran, // Pastikan ini boolean
    required this.espconnected,
    required this.infrared,
    required this.timestamp,
    this.isConnected = true,
  });

  // Parsing JSON ke SensorData
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature:
          json['temperature'] != null ? json['temperature'].toDouble() : 0.0,
      gas: json['gas'] != null ? json['gas'].toDouble() : 0.0,
      ph: json['ph'] != null ? json['ph'].toDouble() : 0.0,
      humidity: json['humidity'] != null ? json['humidity'].toDouble() : 0.0,
      getaran: json['getaran'] ?? false, // Jika null, beri nilai default false
      espconnected:
          json['espconnected'] ?? false, // Jika null, beri nilai default false
      infrared:
          json['infrared'] ?? false, // Jika null, beri nilai default false
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  // Fungsi untuk menghitung rata-rata dari list SensorData
  static double calculateAverageTemperature(List<SensorData> data) {
    if (data.isEmpty) return 0.0;
    double sum = data.fold(0, (prev, element) => prev + element.temperature);
    return sum / data.length;
  }

  static double calculateAverageGas(List<SensorData> data) {
    if (data.isEmpty) return 0.0;
    double sum = data.fold(0, (prev, element) => prev + element.gas);
    return sum / data.length;
  }

  static double calculateAveragePh(List<SensorData> data) {
    if (data.isEmpty) return 0.0;
    double sum = data.fold(0, (prev, element) => prev + element.ph);
    return sum / data.length;
  }

  static double calculateAverageHumidity(List<SensorData> data) {
    if (data.isEmpty) return 0.0;
    double sum = data.fold(0, (prev, element) => prev + element.humidity);
    return sum / data.length;
  }

  static double calculateMinTemperature(List<SensorData> dataList) {
    return dataList.map((e) => e.temperature).reduce(min);
  }

  static double calculateMaxTemperature(List<SensorData> dataList) {
    return dataList.map((e) => e.temperature).reduce(max);
  }

  static double calculateMinGas(List<SensorData> dataList) {
    return dataList.map((e) => e.gas).reduce(min);
  }

  static double calculateMaxGas(List<SensorData> dataList) {
    return dataList.map((e) => e.gas).reduce(max);
  }

  static double calculateMinPh(List<SensorData> dataList) {
    return dataList.map((e) => e.ph).reduce(min);
  }

  static double calculateMaxPh(List<SensorData> dataList) {
    return dataList.map((e) => e.ph).reduce(max);
  }

  static double calculateMinHumidity(List<SensorData> dataList) {
    return dataList.map((e) => e.humidity).reduce(min);
  }

  static double calculateMaxHumidity(List<SensorData> dataList) {
    return dataList.map((e) => e.humidity).reduce(max);
  }

  void updateConnectionStatus(bool status) {
    isConnected = status;
  }
}
