import 'dart:async';
import 'dart:io' show Platform, sleep;
import 'dart:math';

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

  int _rrsi_0 = 0;
  int _rrsi_1 = 0;
  int _rrsi_2 = 0;
  int _rrsi_3 = 0;

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

    Permission permission = Permission.bluetooth;
    // PermissionStatus permission;
    // if (Platform.isAndroid) {
    await permission.request();
    await Permission.location.request();

    // permGranted = permStatus.isGranted;
    // permission = await LocationPermissions().requestPermissions();
    //   if (permission == PermissionStatus.granted) permGranted = true;
    // } else if (Platform.isIOS) {
    //   permGranted = true;
    // }
    // permGranted = true;
    // Main scanning logic happens here ⤵️
    // if (permGranted) {
    _scanStream = flutterReactiveBle.scanForDevices(
      withServices: [],
      scanMode: ScanMode.balanced,
    ).listen((device) {
      if (device.name.contains("ESP")) {
        print(device.name + " " + device.rssi.toString() + "dBm");
        setState(() {
          _ubiqueDevice = device;
          _foundDeviceWaitingToConnect = true;
        });
        if (device.name.split("_")[1] == "0") {
          setState(() {
            _rrsi_0 = device.rssi;
          });
        }
        if (device.name.split("_")[1] == "1") {
          setState(() {
            _rrsi_1 = device.rssi;
          });
        }
        if (device.name.split("_")[1] == "2") {
          setState(() {
            _rrsi_2 = device.rssi;
          });
        }
        if (device.name.split("_")[1] == "3") {
          setState(() {
            _rrsi_3 = device.rssi;
          });
        }
      }
    });
    // }
  }

  void _connectToDevice() async {
    // We're done scanning, we can cancel it
    await _scanStream.cancel();

    // sleep(Duration(seconds: 1));
    // Let's listen to our connection so we can make updates on a state change
    StreamSubscription<ConnectionStateUpdate> _currentConnectionStream;
    _currentConnectionStream = flutterReactiveBle.connectToAdvertisingDevice(
        id: _ubiqueDevice.id,
        prescanDuration: const Duration(seconds: 1),
        withServices: [serviceUuid, characteristicUuid]).listen((event) {
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
            print(_ubiqueDevice.rssi);
            try {
              flutterReactiveBle.writeCharacteristicWithoutResponse(
                _rxCharacteristic,
                value: [_ubiqueDevice.rssi],
              );
            } catch (e) {
              print(e);
            }
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

    // flutterReactiveBle.clearGattCache(_ubiqueDevice.id);
    // _connected = false;

    _currentConnectionStream.cancel();

    _startScan();
  }

  // def find_angle(panjang1, panjang2, panjang3):
  //   a = math.acos((-pow(panjang1, 2) + pow(panjang2, 2) +
  //                 pow(panjang3, 2)) / (2*panjang2*panjang3))
  //   b = math.acos((-pow(panjang2, 2) + pow(panjang3, 2) +
  //                 pow(panjang1, 2)) / (2*panjang3*panjang1))
  //   c = math.acos((-pow(panjang3, 2) + pow(panjang1, 2) +
  //                 pow(panjang2, 2)) / (2*panjang1*panjang2))
  //   return a, b, c

  List<double> _findAngle(num l1, num l2, num l3) {
    double a = acos((-pow(l1, 2) + pow(l2, 2) + pow(l3, 2)) / (2 * l2 * l3));
    double b = acos((-pow(l2, 2) + pow(l3, 2) + pow(l1, 2)) / (2 * l3 * l1));
    double c = acos((-pow(l3, 2) + pow(l1, 2) + pow(l2, 2)) / (2 * l1 * l2));
    return [a, b, c];
  }

  List<double> _findCoords(num l1, num l2, num l3) {
    // def find_koordinat(l1, l2, l3):
    var a = _findAngle(l1, l2, l3);
    var temp1 = cos(a[1]) * l3;
    var temp2 = sin(a[1]) * l3;
    return [temp1, temp2, temp1, -temp2];
  }

  void _partyTime() {
    print(_connected);
    print(_rxCharacteristic);

    // int rssi = _ubiqueDevice.rssi;

    // flutterReactiveBle.statusStream.listen((status) {
    //   BleStatus.
    // });

    // _scanStream = flutterReactiveBle.scanForDevices(
    //   withServices: [],
    //   scanMode: ScanMode.balanced,
    // ).listen((device) {
    //   if (device.name.contains("ESP")) {
    //     setState(() {
    //       _ubiqueDevice = device;
    //       _foundDeviceWaitingToConnect = true;
    //     });
    //     rssi = device.rssi;
    //     _scanStream.cancel();
    //   }
    // });

    if (_connected) {
      // try {
      print(_ubiqueDevice.rssi);
      flutterReactiveBle.writeCharacteristicWithoutResponse(_rxCharacteristic,
          value: [
            _ubiqueDevice.rssi
          ]).onError((error, stackTrace) => print(error));
      // } catch (e) {
      //   print(e);
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: EdgeInsets.fromLTRB(0, 300, 0, 0),
        child: Center(
            child: Column(
          children: [
            Text(
              (pow(10, (-72 - _rrsi_0) / (10 * 2))).toString() +
                  "m, $_rrsi_0 dBm",
              textAlign: TextAlign.center,
            ),
            Text(
              (pow(10, (-72 - _rrsi_1) / (10 * 2))).toString() +
                  "m, $_rrsi_1 dBm",
              textAlign: TextAlign.center,
            ),
            Text(
              (pow(10, (-72 - _rrsi_2) / (10 * 2))).toString() +
                  "m, $_rrsi_2 dBm",
              textAlign: TextAlign.center,
            ),
            Text(
              (pow(10, (-72 - _rrsi_3) / (10 * 2))).toString() +
                  "m, $_rrsi_3 dBm",
              textAlign: TextAlign.center,
            ),
            Text(
              _findCoords(
                      pow(10, (-72 - _rrsi_0) / (10 * 2)),
                      pow(10, (-72 - _rrsi_1) / (10 * 2)),
                      pow(10, (-72 - _rrsi_2) / (10 * 2)))
                  .toString(),
              textAlign: TextAlign.center,
            ),
          ],
        )),
      ),
      persistentFooterButtons: [
        // We want to enable this button if the scan has NOT started
        // If the scan HAS started, it should be disabled.
        // _scanStarted
        // True condition
        // ?
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: _startScan,
          child: const Icon(Icons.search),
        ),
        // False condition
        // : ElevatedButton(
        //     style: ElevatedButton.styleFrom(
        //       primary: Colors.blue, // background
        //       onPrimary: Colors.white, // foreground
        //     ),
        //     onPressed: _startScan,
        //     child: const Icon(Icons.search),
        //   ),
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: () {
            _scanStream.cancel();
          },
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
