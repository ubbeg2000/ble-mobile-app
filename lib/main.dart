import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  return runApp(
    const MaterialApp(home: HomePage()),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Some state management stuff
  bool _foundDeviceWaitingToConnect = false;
  bool _scanStarted = false;
  bool _connected = false;

  // Bluetooth related variables
  late DiscoveredDevice _ubiqueDevice;
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> _scanStream;
  late QualifiedCharacteristic _rxCharacteristic;

  // These are the UUIDs of your device
  final Uuid serviceUuid = Uuid.parse("213850a2-0a13-472e-8018-65e644f39fd6");
  final Uuid characteristicUuid =
      Uuid.parse("1266CC05-10FB-4452-B42C-963D1EFA6B67");

  void _startScan() async {
    // Platform permissions handling stuff
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
    });

    print("ASDF");

    Permission permission = Permission.bluetooth;
    // PermissionStatus permission;
    // if (Platform.isAndroid) {
    print("MI");
    PermissionStatus permStatus = await permission.request();
    await Permission.location.request();
    print("DI");
    print(permStatus);
    permGranted = permStatus.isGranted;
    // permission = await LocationPermissions().requestPermissions();
    //   if (permission == PermissionStatus.granted) permGranted = true;
    // } else if (Platform.isIOS) {
    //   permGranted = true;
    // }
    // permGranted = true;
    // Main scanning logic happens here ⤵️
    if (permGranted) {
      print("ASDFHUHU");
      _scanStream = flutterReactiveBle.scanForDevices(
        withServices: [],
        scanMode: ScanMode.opportunistic,
      ).listen((device) {
        // Change this string to what you defined in Zephyr
        print("DUDU" + device.name);
        if (device.name.contains("ESP")) {
          setState(() {
            _ubiqueDevice = device;
            _foundDeviceWaitingToConnect = true;
          });
        }
      });
    }
  }

  void _connectToDevice() {
    print("HASDF");
    // We're done scanning, we can cancel it
    _scanStream.cancel();
    print(_ubiqueDevice);
    // Let's listen to our connection so we can make updates on a state change
    Stream<ConnectionStateUpdate> _currentConnectionStream = flutterReactiveBle
        .connectToAdvertisingDevice(
            id: _ubiqueDevice.id,
            prescanDuration: const Duration(seconds: 1),
            withServices: [serviceUuid, characteristicUuid]);
    _currentConnectionStream.listen((event) {
      print(event);
      switch (event.connectionState) {
        // We're connected and good to go!
        case DeviceConnectionState.connected:
          {
            _rxCharacteristic = QualifiedCharacteristic(
                serviceId: serviceUuid,
                characteristicId: characteristicUuid,
                deviceId: event.deviceId);
            setState(() {
              _foundDeviceWaitingToConnect = false;
              _connected = true;
            });
            break;
          }
        // Can add various state state updates on disconnect
        case DeviceConnectionState.disconnected:
          {
            break;
          }
        default:
      }
    });
  }

  void _partyTime() {
    print(_connected);
    if (_connected) {
      flutterReactiveBle
          .writeCharacteristicWithoutResponse(_rxCharacteristic, value: [
        0xff,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(),
      persistentFooterButtons: [
        // We want to enable this button if the scan has NOT started
        // If the scan HAS started, it should be disabled.
        // _scanStarted
        //     // True condition
        //     ? ElevatedButton(
        //         // style: ElevatedButton.styleFrom(
        //         //   primary: Colors.grey, // background
        //         //   onPrimary: Colors.white, // foreground
        //         // ),
        //         onPressed: () {},
        //         child: const Icon(Icons.search),
        //       )
        //     // False condition
        //     :
        ElevatedButton(
          // style: ElevatedButton.styleFrom(
          //   primary: Colors.blue, // background
          //   onPrimary: Colors.white, // foreground
          // ),
          onPressed: _startScan,
          child: const Icon(Icons.search),
        ),
        // _foundDeviceWaitingToConnect
        //     // True condition
        //     ?
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: _connectToDevice,
          child: const Icon(Icons.bluetooth),
        ),
        // False condition
        // : ElevatedButton(
        //     style: ElevatedButton.styleFrom(
        //       primary: Colors.grey, // background
        //       onPrimary: Colors.white, // foreground
        //     ),
        //     onPressed: () {},
        //     child: const Icon(Icons.bluetooth),
        //   ),
        // _connected
        //     // True condition
        //     ?
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: _partyTime,
          child: const Icon(Icons.celebration_rounded),
        ),
        // False condition
        // : ElevatedButton(
        //     style: ElevatedButton.styleFrom(
        //       primary: Colors.grey, // background
        //       onPrimary: Colors.white, // foreground
        //     ),
        //     onPressed: () {},
        //     child: const Icon(Icons.celebration_rounded),
        //   ),
      ],
    );
  }
}
