import Foundation
import CoreBluetooth
import UIKit

class BLEManager: NSObject, ObservableObject, CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // قائمة الرسائل المستقبلة
    @Published var receivedMessages = [String]()
    
    // البلوتوث
    var peripheralManager: CBPeripheralManager!
    var centralManager: CBCentralManager!
    
    var transferCharacteristic: CBMutableCharacteristic!
    
    override init() {
        super.init()
        
        // إعداد جهازك للعمل كمرسل ومستقبل
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - إرسال الرسالة
    func sendMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        if peripheralManager.state == .poweredOn {
            transferCharacteristic.value = data
            peripheralManager.updateValue(data, for: transferCharacteristic, onSubscribedCentrals: nil)
        }
    }
    
    // MARK: - التحقق من حالة البلوتوث عند فتح التطبيق
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("BLE شغال")
            central.scanForPeripherals(withServices: [CBUUID(string: "1234")], options: nil)
            
        case .poweredOff:
            print("BLE مغلق! التطبيق يحتاج البلوتوث")
            DispatchQueue.main.async {
                self.showBluetoothAlert()
            }
            
        default:
            break
        }
    }
    
    // عرض Alert إذا البلوتوث مغلق
    func showBluetoothAlert() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        
        let alert = UIAlertController(
            title: "البلوتوث مغلق",
            message: "التطبيق يحتاج البلوتوث للعمل. شغل البلوتوث للمتابعة.",
            preferredStyle: .alert
        )
        
        // زر لإغلاق التطبيق
        alert.addAction(UIAlertAction(title: "إغلاق التطبيق", style: .destructive, handler: { _ in
            exit(0)
        }))
        
        // زر لإبقاء التطبيق مفتوح
        alert.addAction(UIAlertAction(title: "حسناً، سأشغل البلوتوث", style: .default, handler: nil))
        
        rootVC.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Peripheral Delegate
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            let serviceUUID = CBUUID(string: "1234")
            transferCharacteristic = CBMutableCharacteristic(
                type: CBUUID(string: "5678"),
                properties: [.notify, .read, .writeWithoutResponse],
                value: nil,
                permissions: [.readable, .writeable]
            )
            let service = CBMutableService(type: serviceUUID, primary: true)
            service.characteristics = [transferCharacteristic]
            peripheralManager.add(service)
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
        }
    }
    
    // MARK: - Central Delegate
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: "1234")])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([CBUUID(string: "5678")], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for char in characteristics {
            if char.uuid == CBUUID(string: "5678") {
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value, let message = String(data: data, encoding: .utf8) else { return }
        DispatchQueue.main.async {
            self.receivedMessages.append(message)
        }
    }
}
