import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

bool showPushButton =false;

class SelectBondedDevicePage extends StatefulWidget {
  final bool checkAvailability;
  const SelectBondedDevicePage({super.key, this.checkAvailability = true});

  @override
  State<SelectBondedDevicePage> createState() => _SelectBondedDevicePageState();
}

class _SelectBondedDevicePageState extends State<SelectBondedDevicePage> {
  List<BluetoothDevice> _devicesList = [];
  bool _isConnecting = false;
  BluetoothConnection? _connection;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (await FlutterBluetoothSerial.instance.isEnabled ?? false) {
      if (await Permission.bluetoothScan.request().isGranted &&
          await Permission.bluetoothConnect.request().isGranted) {
        _getBondedDevices();
      } else {
        print('Bluetooth permissions not granted');
      }
    } else {
      print('Bluetooth is not enabled');
    }
  }

  Future<void> _getBondedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print('Error getting bonded devices: $e');
    }

    if (!mounted) return;

    setState(() {
      _devicesList = devices;
    });
  }

  Future<void> _connectDevice(BluetoothDevice device) async { // this function is used to connect the the app with the device
    try {
      setState(() {
        _isConnecting = true;
      });

      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        _isConnecting = false;
      });

      connection.input!.listen((data) {
        String message = String.fromCharCodes(data);
        print('Received: $message');
      }).onDone(() {
        print('Disconnected by remote request');
      });
      setState(() {
        showPushButton = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );

    } catch (e) {
      setState(() {
        _isConnecting = false;
      });
      print('Cannot connect to the device: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device.name}')),
      );
    }
  }

    void _sendOnMessageToBluetooth() async {
    _connection!.output.add(
      utf8.encode("F"),
    );
    await _connection!.output.allSent;
  }

  void _disconnect() async {
    // Closing the Bluetooth connection
    await _connection!.close();

    if (!_connection!.isConnected) {
      setState(() {
        showPushButton=false;
        _isConnecting = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paired Devices'),
      ),
      body: _isConnecting
          ? Center(child: CircularProgressIndicator())
          : showPushButton?
          Center(
            child: Column(
              children: [
                InkWell(
                          onTap: () {
                            _sendOnMessageToBluetooth();
                          },
                          child: Container(
                            color: Colors.blue,
                            height: 70,
                            width: 150,
                            child: Center(child: Text('Feeding button')),
                          ),
                        ),

                        ElevatedButton(onPressed: (){
                          _disconnect();
                          
                          Navigator.pop(context);
                        }, child: Text('Disconnect'),),
              ],
            ),
          )
          
          : ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devicesList[index];
                return ListTile(
                  title: Text(device.name ?? 'Unknown device'),
                  subtitle: Text(device.address),
                  onTap: () {
                    _connectDevice(device);
                    
                  },
                );
              },
            ),
    );
  }
}
