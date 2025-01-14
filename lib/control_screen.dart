import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:typed_data';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  double _light = 0;
  double _servo = 90;
  WebSocketChannel? _cameraChannel;
  WebSocketChannel? _controlChannel;
  String _ipAddress = '192.168.180.177';
  Uint8List? _imageBytes;
  bool _isConnected = false;

  final TextEditingController _ipController =
      TextEditingController(text: '192.168.180.177');

  @override
  void initState() {
    super.initState();
    // Optional: Langsung connect saat screen dibuka
    // _connectWebSocket();
  }

  void _connectWebSocket() {
    if (_ipAddress.isEmpty) return;

    setState(() => _isConnected = false);

    try {
      _cameraChannel = WebSocketChannel.connect(
        Uri.parse('ws://$_ipAddress/Camera'),
      );

      _controlChannel = WebSocketChannel.connect(
        Uri.parse('ws://$_ipAddress/CarInput'),
      );

      setState(() => _isConnected = true);

      _cameraChannel?.stream.listen(
        (data) {
          if (data is List<int>) {
            setState(() {
              _imageBytes = Uint8List.fromList(data);
            });
          }
        },
        onError: (error) {
          print('Camera Error: $error');
          setState(() => _isConnected = false);
        },
        onDone: () {
          setState(() => _isConnected = false);
        },
      );
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  void _sendCommand(String command, String value) {
    if (_controlChannel != null && _isConnected) {
      try {
        _controlChannel?.sink.add('$command,$value');
      } catch (e) {
        print('Error sending command: $e');
        // Optional: Tambahkan handling error seperti menampilkan snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim perintah: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // IP Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan IP Address',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => _ipAddress = value,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _connectWebSocket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.green : Colors.cyan,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    children: [
                      if (_isConnected) const Icon(Icons.check, size: 16),
                      const SizedBox(width: 4),
                      Text(_isConnected ? 'Connected' : 'Connect'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Camera Stream
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 240,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : const Center(
                      child: Text(
                        'Waiting for camera...',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Control Buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButtonWithState(
                  '↑', () => _sendCommand('MoveCar', '1')),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButtonWithState(
                      '←', () => _sendCommand('MoveCar', '3')),
                  const SizedBox(width: 80),
                  _buildControlButtonWithState(
                      '→', () => _sendCommand('MoveCar', '4')),
                ],
              ),
              const SizedBox(height: 16),
              _buildControlButtonWithState(
                  '↓', () => _sendCommand('MoveCar', '2')),
            ],
          ),

          const SizedBox(height: 20),

          // Control Panel dengan Sliders
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Light Control
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text('Light:', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16),
                          ),
                          child: Slider(
                            value: _light,
                            min: 0,
                            max: 255,
                            divisions: 255,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.blue.withOpacity(0.2),
                            onChanged: (value) {
                              setState(() => _light = value);
                            },
                            onChangeEnd: (value) {
                              _sendCommand('Light', value.round().toString());
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          _light.round().toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Servo Control
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String label, VoidCallback onPressed) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // Outer shadow
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
          // Inner highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.cyan[700],
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(1, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Optional: Tambahkan efek pressed state
  Widget _buildControlButtonWithState(String label, VoidCallback onPressed) {
    bool isPressed = false;

    return StatefulBuilder(
      builder: (context, setState) => GestureDetector(
        onTapDown: (_) {
          setState(() => isPressed = true);
          try {
            _sendCommand('MoveCar', getDirectionValue(label));
          } catch (e) {
            print('Error sending command: $e');
          }
        },
        onTapUp: (_) {
          setState(() => isPressed = false);
          try {
            _sendCommand('MoveCar', '0');
          } catch (e) {
            print('Error sending stop command: $e');
          }
        },
        onTapCancel: () {
          setState(() => isPressed = false);
          try {
            _sendCommand('MoveCar', '0');
          } catch (e) {
            print('Error sending stop command: $e');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isPressed ? Colors.grey[200] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isPressed
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(-1, -1),
                    ),
                  ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 24,
                color: Colors.cyan[700],
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(1, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String getDirectionValue(String label) {
    switch (label) {
      case '↑':
        return '1';
      case '↓':
        return '2';
      case '←':
        return '3';
      case '→':
        return '4';
      default:
        return '0';
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _cameraChannel?.sink.close();
    _controlChannel?.sink.close();
    super.dispose();
  }
}
