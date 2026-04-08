//
//  BleManager.swift
//  cameraExample
//
//  Created by MacBook on 08/07/2025.
//
import Foundation
import CoreBluetooth

class BleManager: NSObject, ObservableObject, CBCentralManagerDelegate,CBPeripheralDelegate  {
    var centralManager: CBCentralManager!
       @Published var connectedPeripheral: CBPeripheral?
       @Published var isConnected = false
       @Published var connectedPeripheralName: String? = nil
       private var writeCharacteristic: CBCharacteristic?

       let targetDeviceName = "Ledy"
       let targetServiceUUID = CBUUID(string: "dcbc7255-1e9e-49a0-a360-b0430b6c6905")
       let targetCharacteristicUUID = CBUUID(string: "371a55c8-f251-4ad2-90b3-c7c195b049be")

       override init() {
           super.init()
           centralManager = CBCentralManager(delegate: self, queue: nil)
       }

       func centralManagerDidUpdateState(_ central: CBCentralManager) {
           if central.state == .poweredOn {
               centralManager.scanForPeripherals(withServices: nil, options: nil)
               print("Bluetooth ON — zaczynam skanowanie")
           } else {
               print("Bluetooth wyłączony lub niedostępny")
               isConnected = false
               connectedPeripheralName = nil
           }
       }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Połączono z: \(peripheral.name ?? "Unknown")")
        
        // Musimy to wykonać na głównej kolejce, żeby UI się odświeżył
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectedPeripheralName = peripheral.name
        }
        
        peripheral.delegate = self
        peripheral.discoverServices([targetServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Nieznane"
        print("Widzę urządzenie: \(name)")

        // ZMIEŃ TO: zamiast "ESP32-LED" użyj targetDeviceName
        if name == targetDeviceName {
            print("MAM GO! Łączę...")
            self.connectedPeripheral = peripheral
            self.centralManager.stopScan()
            self.centralManager.connect(peripheral, options: nil)
        }
    }

       func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
           if let error = error {
               print("Błąd podczas szukania usług: \(error.localizedDescription)")
               return
           }
           guard let services = peripheral.services else { return }
           for service in services {
               print("Znaleziono usługę UUID: \(service.uuid)")
               if service.uuid == targetServiceUUID {
                   peripheral.discoverCharacteristics([targetCharacteristicUUID], for: service)
               }
           }
       }

       func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
           if let error = error {
               print("Błąd podczas szukania charakterystyk: \(error.localizedDescription)")
               return
           }
           guard let characteristics = service.characteristics else { return }
           for characteristic in characteristics {
               print("Znaleziono charakterystykę UUID: \(characteristic.uuid)")
               if characteristic.uuid == targetCharacteristicUUID {
                   writeCharacteristic = characteristic
                   print("Znaleziono writeCharacteristic")
               }
           }
       }

       func sendData(_ data: Data) {
           guard let peripheral = connectedPeripheral,
                 let characteristic = writeCharacteristic else {
               print("Brak połączenia lub charakterystyki do zapisu")
               return
           }
           peripheral.writeValue(data, for: characteristic, type: .withResponse)
           print("Wysłano dane: \(data as NSData)")
       }
   }
