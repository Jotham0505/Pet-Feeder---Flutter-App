import 'dart:convert';

import 'package:ecs/bonded_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({super.key});

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothDevice? _device;
  BluetoothConnection? _connection;
  bool _isconnecting = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    //Enable Bluetooth
    FlutterBluetoothSerial.instance.isEnabled.then((isEnabled) {
      if (!isEnabled!) {
        FlutterBluetoothSerial.instance.requestEnable();
      }
    });

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  Future<void> _connectDevice() async {
    try {
      if (_device != null) {
        setState(() {
          _isconnecting = true;
        });
        BluetoothConnection connection =
            await BluetoothConnection.toAddress(_device!.address);
        setState(() {
          _connection = connection;
          _isconnecting = false;
        });
        connection.input!.listen((data) {
          String message = String.fromCharCodes(data);
          print('recieved: $message');
        });
      }
    } catch (e) {
      setState(() {
        _isconnecting = false;
      });
      print('Can not connect');
    }
  }

  Future<void> _selectDevice() async {
    final BluetoothDevice? selectedDevice = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectBondedDevicePage(checkAvailability: false),
      ),
    );

    if (selectedDevice != null) {
      print(selectedDevice);
      setState(() {
        _device = selectedDevice;
      });
    }
  }

  void _sendOnMessageToBluetooth() async {
    _connection!.output.add(
      utf8.encode("F"),
    );
    await _connection!.output.allSent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Connection'),
      ),
      body: Center(
        child: Column(
          children: [
            Text('Bluetooth is ${_bluetoothState.toString().split('.')[1]}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectDevice,
              child: Text(_device == null ? 'Select Device' : 'Selected: ${_device!.name}'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _device != null && !_isconnecting ? _connectDevice : null,
              child: Text(_isconnecting ? 'Connecting...' : 'Connect to Device'),
            ),
            SizedBox(height: 20),
            if (_connection != null && _connection!.isConnected)
              Text('Connected to ${_device!.name}'),

              SizedBox(height: 20),

              // showPushButton
              //   ? InkWell(
              //       onTap: () {
              //         _sendOnMessageToBluetooth();
              //       },
              //       child: Container(
              //         color: Colors.blue,
              //         height: 70,
              //         width: 150,
              //         child: Center(child: Text('Feeding button')),
              //       ),
              //     )
              //   : SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
