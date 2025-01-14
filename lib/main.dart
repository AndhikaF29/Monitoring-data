import 'package:flutter/material.dart';
import 'api_service.dart';
import 'sensor_data.dart';
import 'splash_screen.dart';
import 'bottom_navbar.dart';
import 'grafik_screen.dart';
import 'dart:async';
import 'profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'control_screen.dart';

void main() {
  runApp(const RCMineSentinelApp());
}

class RCMineSentinelApp extends StatefulWidget {
  const RCMineSentinelApp({Key? key}) : super(key: key);

  @override
  State<RCMineSentinelApp> createState() => _RCMineSentinelAppState();
}

class _RCMineSentinelAppState extends State<RCMineSentinelApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  void _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('isDarkMode', isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 214, 252),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
        ),
        cardColor: Colors.green[50],
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
        ),
        cardColor: Colors.grey[800],
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.greenAccent,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode),
    );
  }
}

class SensorDataScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const SensorDataScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _SensorDataScreenState createState() => _SensorDataScreenState();
}

class _SensorDataScreenState extends State<SensorDataScreen> {
  List<SensorData> sensorDataList = [];
  int? _selectedHours;
  int _selectedIndex = 0;
  ApiService _apiService = ApiService();

  @override
  void dispose() {
    _apiService.dispose(); // Stop polling when screen is disposed
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RC MINE Sentinel'),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedIndex != 2 && _selectedIndex != 3)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButton<int?>(
                  value: _selectedHours,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  iconSize: 26,
                  elevation: 16,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  underline: Container(), // Remove default underline
                  hint: Text(
                    'Select Time Range',
                    style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white70
                            : Colors.black54),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Data')),
                    DropdownMenuItem(value: 1, child: Text('Last 1 Hour')),
                    DropdownMenuItem(value: 3, child: Text('Last 3 Hours')),
                    DropdownMenuItem(value: 6, child: Text('Last 6 Hours')),
                    DropdownMenuItem(value: 12, child: Text('Last 12 Hours')),
                    DropdownMenuItem(value: 24, child: Text('Last 24 Hours')),
                  ],
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedHours = newValue;
                      sensorDataList.clear();
                      _fetchFilteredData();
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedIndex == 0
                ? _buildDataContent()
                : _selectedIndex == 1
                    ? GrafikScreen(sensorDataList: sensorDataList)
                    : _selectedIndex == 2
                        ? ControlScreen()
                        : ProfileScreen(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  void _fetchFilteredData() async {
    // Fetch data according to selected filter
    List<SensorData> fetchedData =
        await ApiService().fetchSensorData(hours: _selectedHours);

    setState(() {
      sensorDataList = fetchedData;
    });
  }

  Widget _buildDataContent() {
    return StreamBuilder<SensorData?>(
      stream: ApiService().getSensorDataStream(hours: _selectedHours),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          // If no data, show disconnected status
          return const Center(child: Text('Disconnected'));
        } else {
          SensorData sensorData = snapshot.data!;

          // Check data update time
          final currentTime = DateTime.now();
          final lastUpdateTime =
              sensorData.timestamp; // Get timestamp from sensor data
          final difference = currentTime.difference(lastUpdateTime);

          // If no update for more than 10 seconds, set isConnected to false
          sensorData.updateConnectionStatus(difference.inSeconds <= 10);

          // Only add data if not already exists
          if (!sensorDataList.contains(sensorData)) {
            sensorDataList.add(sensorData);
          }

          // Calculate averages from sensorDataList
          double averageTemperature =
              SensorData.calculateAverageTemperature(sensorDataList);
          double averageGas = SensorData.calculateAverageGas(sensorDataList);
          double averagePh = SensorData.calculateAveragePh(sensorDataList);
          double averageHumidity =
              SensorData.calculateAverageHumidity(sensorDataList);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSensorGrid(sensorData),
                  const SizedBox(height: 20),
                  _buildAverageSensorData(
                    averageTemperature,
                    averageGas,
                    averagePh,
                    averageHumidity,
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSensorGrid(SensorData sensorData) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800] // Color for dark mode
            : Colors.blue.shade50, // Color for light mode
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.blue.shade700),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monitoring',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Update: ${_formatTimestamp(sensorData.timestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sensorData.isConnected ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          sensorData.isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _showThresholdSettings,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 11), // Space between title and grid
          Expanded(
            // Use Expanded for SensorGridView
            child: SensorGridView(
              sensorCards: [
                SensorInfoCard(
                  title: 'Temperature',
                  value: '${sensorData.temperature} °C',
                  isDanger:
                      sensorData.temperature > SensorData.temperatureThreshold,
                  icon: Icons.thermostat,
                ),
                SensorInfoCard(
                  title: 'Gas',
                  value: '${sensorData.gas} ppm',
                  isDanger: sensorData.gas > SensorData.gasThreshold,
                  icon: Icons.gas_meter_rounded,
                ),
                SensorInfoCard(
                  title: 'Humidity',
                  value: '${sensorData.humidity} %',
                  isDanger: sensorData.humidity > SensorData.humidityThreshold,
                  icon: Icons.water_drop,
                ),
                SensorInfoCard(
                  title: 'Vibration',
                  value: sensorData.getaran ? 'Danger' : 'Safe',
                  isDanger: sensorData.getaran,
                  icon: Icons.vibration_sharp,
                ),
                SensorInfoCard(
                  title: 'Infrared',
                  value: sensorData.infrared ? 'Danger' : 'Safe',
                  isDanger: sensorData.infrared,
                  icon: Icons.visibility,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageSensorData(
      double temperature, double gas, double ph, double humidity) {
    // Calculate min and max values
    double minTemperature = SensorData.calculateMinTemperature(sensorDataList);
    double maxTemperature = SensorData.calculateMaxTemperature(sensorDataList);
    double minGas = SensorData.calculateMinGas(sensorDataList);
    double maxGas = SensorData.calculateMaxGas(sensorDataList);
    double minPh = SensorData.calculateMinPh(sensorDataList);
    double maxPh = SensorData.calculateMaxPh(sensorDataList);
    double minHumidity = SensorData.calculateMinHumidity(sensorDataList);
    double maxHumidity = SensorData.calculateMaxHumidity(sensorDataList);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800] // Color for dark mode
            : Colors.blue.shade50, // Color for light mode
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 11),
              const Text(
                'Average Sensor Data',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildSensorRow('Temperature', '${temperature.toStringAsFixed(1)} °C',
              Icons.thermostat_outlined),
          _buildMinMaxRow('Min: ${minTemperature.toStringAsFixed(1)} °C',
              'Max: ${maxTemperature.toStringAsFixed(1)} °C'),
          const Divider(height: 20),
          _buildSensorRow(
              'Gas', '${gas.toStringAsFixed(1)} ppm', Icons.cloud_outlined),
          _buildMinMaxRow('Min: ${minGas.toStringAsFixed(1)} ppm',
              'Max: ${maxGas.toStringAsFixed(1)} ppm'),
          const Divider(height: 20),
          _buildSensorRow('Humidity', '${humidity.toStringAsFixed(1)} %',
              Icons.water_outlined),
          _buildMinMaxRow('Min: ${minHumidity.toStringAsFixed(1)} %',
              'Max: ${maxHumidity.toStringAsFixed(1)} %'),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: const Text(
                'Export Sensor Data',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              onPressed: _showExportConfirmation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinMaxRow(String minValue, String maxValue) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 4.0),
      child: Row(
        children: [
          Text(minValue,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 16),
          Text(maxValue,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSensorRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Future<void> _showThresholdSettings() async {
    final temperatureController = TextEditingController();
    final gasController = TextEditingController();
    final humidityController = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    temperatureController.text =
        (prefs.getDouble('temperature_threshold') ?? 35.0).toString();
    gasController.text = (prefs.getDouble('gas_threshold') ?? 400.0).toString();
    humidityController.text =
        (prefs.getDouble('humidity_threshold') ?? 80.0).toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                'Danger Threshold Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThresholdField(
                  controller: temperatureController,
                  label: 'Temperature Threshold',
                  suffix: '°C',
                  icon: Icons.thermostat,
                  isDarkMode: widget.isDarkMode,
                ),
                SizedBox(height: 16),
                _buildThresholdField(
                  controller: gasController,
                  label: 'Gas Threshold',
                  suffix: 'ppm',
                  icon: Icons.gas_meter,
                  isDarkMode: widget.isDarkMode,
                ),
                SizedBox(height: 16),
                _buildThresholdField(
                  controller: humidityController,
                  label: 'Humidity Threshold',
                  suffix: '%',
                  icon: Icons.water_drop,
                  isDarkMode: widget.isDarkMode,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                // Save new threshold values
                await prefs.setDouble('temperature_threshold',
                    double.tryParse(temperatureController.text) ?? 35.0);
                await prefs.setDouble('gas_threshold',
                    double.tryParse(gasController.text) ?? 400.0);
                await prefs.setDouble('humidity_threshold',
                    double.tryParse(humidityController.text) ?? 80.0);

                // Update threshold values in SensorData
                SensorData.temperatureThreshold =
                    double.tryParse(temperatureController.text) ?? 35.0;
                SensorData.gasThreshold =
                    double.tryParse(gasController.text) ?? 400.0;
                SensorData.humidityThreshold =
                    double.tryParse(humidityController.text) ?? 80.0;

                Navigator.pop(context);
                setState(() {});
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThresholdField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: Colors.blue),
          labelStyle:
              TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700]),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showExportConfirmation() async {
    DateTimeRange? selectedDateRange;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.file_download_outlined, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                'Export Sensor Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text(
                      selectedDateRange == null
                          ? 'Select Date Range'
                          : '${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                    ),
                    onPressed: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                        initialDateRange: selectedDateRange ??
                            DateTimeRange(
                              start: DateTime.now().subtract(Duration(days: 7)),
                              end: DateTime.now(),
                            ),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDateRange = picked;
                        });
                      }
                    },
                  ),
                ),
                if (selectedDateRange != null) ...[
                  SizedBox(height: 16),
                  FutureBuilder<List<SensorData>>(
                    future: ApiService().fetchSensorDataByDateRange(
                      selectedDateRange!.start,
                      selectedDateRange!.end,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      final filteredData = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics,
                                  color: Colors.blue.shade700, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Total data: ${filteredData.length}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          if (filteredData.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.date_range,
                                    color: Colors.blue.shade700, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Range: ${_formatTimestamp(filteredData.first.timestamp)} - ${_formatTimestamp(filteredData.last.timestamp)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: selectedDateRange != null
                  ? () {
                      Navigator.pop(context);
                      _exportSensorData(selectedDateRange!);
                    }
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Export',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSensorData(DateTimeRange dateRange) async {
    try {
      // Check and request storage permission first
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Storage permission required for data export')),
            );
            return; // Stop if permission not granted
          }
        }
      }

      // Choose save location first
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Sensor Data',
        fileName:
            'sensor_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (filePath == null) {
        print('File path is null');
        return; // Stop if user cancels dialog
      }

      // Get data with separate try-catch
      List<SensorData> filteredData;
      try {
        filteredData = await _apiService.fetchSensorDataByDateRange(
          dateRange.start,
          dateRange.end,
        );
        print('Data fetched: ${filteredData.length} items');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch data: $e')),
        );
        return;
      }

      if (filteredData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No data available for selected time range')),
        );
        return; // Stop if no data
      }

      // Process data to CSV
      final rows = [
        [
          'Timestamp',
          'Temperature (°C)',
          'Gas (ppm)',
          'Soil Moisture',
          'Humidity (%)',
          'Getaran',
          'Infrared'
        ],
        ...filteredData.map((data) => [
              DateFormat('yyyy-MM-dd HH:mm:ss').format(data.timestamp),
              data.temperature.toString(),
              data.gas.toString(),
              data.ph.toString(),
              data.humidity.toString(),
              data.getaran ? 'Danger' : 'Safe',
              data.infrared ? 'Danger' : 'Safe',
            ]),
      ];

      print('Rows to export: ${rows.length}');

      // Tulis file dengan try-catch terpisah
      try {
        final csv = const ListToCsvConverter().convert(rows);
        final file = File(filePath);
        await file.writeAsString(csv, flush: true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan file: $e')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data berhasil disimpan ke: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }
}

Widget _buildSensorRow(String label, String value, IconData icon) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ],
  );
}

// Widget untuk menampilkan informasi sensor dalam bentuk kartu
class SensorInfoCard extends StatefulWidget {
  final String title;
  final String value;
  final bool isDanger;
  final IconData icon;

  const SensorInfoCard({
    required this.title,
    required this.value,
    this.isDanger = false,
    required this.icon,
  });

  @override
  State<SensorInfoCard> createState() => _SensorInfoCardState();
}

class _SensorInfoCardState extends State<SensorInfoCard> {
  bool _isBlinking = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Mulai timer untuk efek kedip
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (widget.isDanger) {
        setState(() {
          _isBlinking = !_isBlinking;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: widget.isDanger
            ? (_isBlinking ? Colors.red : const Color.fromARGB(255, 3, 72, 199))
            : isDark
                ? Colors.grey[700] // Warna untuk mode gelap
                : const Color.fromARGB(
                    255, 0, 215, 243), // Warna untuk mode terang
        borderRadius: BorderRadius.circular(9.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              widget.icon,
              size: 24,
              color: isDark || widget.isDanger ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark || widget.isDanger
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark || widget.isDanger
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tampilan dengan dua kartu sensor per baris
class SensorGridView extends StatelessWidget {
  final List<SensorInfoCard> sensorCards;

  const SensorGridView({required this.sensorCards});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Dua kartu per baris
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 2.2, // Rasio untuk mengatur proporsi kartu
      ),
      itemCount: sensorCards.length,
      itemBuilder: (context, index) {
        return sensorCards[index];
      },
    );
  }
}
