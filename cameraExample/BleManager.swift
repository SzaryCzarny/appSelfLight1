//
//  BleManager.swift
//  cameraExample
//
//  Created by MacBook on 08/07/2025.
//
import Foundation
import CoreBluetooth

class BleManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
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

    // MARK: - Central Manager State
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning() // Wyciągnąłem skanowanie do osobnej funkcji
        } else {
            print("Bluetooth wyłączony lub niedostępny")
            DispatchQueue.main.async {
                self.isConnected = false
                self.connectedPeripheralName = nil
            }
        }
    }

    // Funkcja pomocnicza do skanowania
    func startScanning() {
        print("Skanowanie wymuszone ręcznie")
        centralManager.stopScan() // Najpierw stopujemy na wszelki wypadek
        centralManager.scanForPeripherals(withServices: [targetServiceUUID], options: nil)
    }

    // MARK: - Discovering & Connecting
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // CoreBluetooth czasem zwraca nazwę w advertisementData, jeśli peripheral.name jest nil
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "Nieznane"
        
        if name == targetDeviceName {
            print("MAM GO! Próba połączenia...")
            self.connectedPeripheral = peripheral
            self.centralManager.stopScan()
            self.centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Połączono pomyślnie z: \(peripheral.name ?? "Ledy")")
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectedPeripheralName = peripheral.name ?? "Ledy"
        }
        
        peripheral.delegate = self
        peripheral.discoverServices([targetServiceUUID])
    }

    // MARK: - RECONNECT LOGIC (To rozwiązuje Twój problem)
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Połączenie przerwane. Powód: \(error?.localizedDescription ?? "Brak błędu")")
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedPeripheralName = nil
            self.writeCharacteristic = nil
        }
        
        // Gdy stracimy połączenie, od razu zaczynamy szukać ponownie
        print("Uruchamiam ponowne skanowanie (Autoconnect)...")
        startScanning()
    }

    // MARK: - Peripheral Delegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Błąd usług: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == targetServiceUUID {
                peripheral.discoverCharacteristics([targetCharacteristicUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == targetCharacteristicUUID {
                writeCharacteristic = characteristic
                print("Gotowy do zapisu danych.")
            }
        }
    }

    func sendData(_ data: Data) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic else {
            print("Nie można wysłać — brak aktywnego połączenia")
            return
        }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}
