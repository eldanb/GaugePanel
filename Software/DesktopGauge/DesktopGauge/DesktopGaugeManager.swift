//
//  DesktopGaugeManager.swift
//  DesktopGauge
//
//  Created by Eldan Ben Haim on 03/02/2022.
//

import Foundation
import CoreBluetooth



let DesktopGaugeServiceUuid =
    CBUUID.init(string: "93e842a1-9cb9-476d-aaf0-7183ff7c3551")
let DesktopGaugeServiceGauge1CharaUuid =
    CBUUID.init(string: "24d71d3e-79e0-4458-ba98-6ad86421a10b")
let DesktopGaugeServiceGauge2CharaUuid =
    CBUUID.init(string: "34d72d3e-79e0-4458-ba98-6ad86421a10b")

class DektopGaugeManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    override init() {
        super.init();
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("Central manager state \(central.state.rawValue).");
        
        if(central.state == .poweredOn && !central.isScanning) {
            NSLog("Cancel existing \(pendingConnections.count) connections.");
            while(!pendingConnections.isEmpty) {
                cancelConnection(pendingConnections.first!);
            }

            NSLog("Start scanning.");
            central.scanForPeripherals(withServices: [DesktopGaugeServiceUuid], options: [: ]);
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if(currentPeripheral == nil) {
            NSLog("Discovered peripheral \(peripheral.identifier). Trying to connect.");
            central.connect(peripheral, options: [:]);
            pendingConnections.insert(peripheral);
        } else {
            NSLog("Discovered peripheral \(peripheral.identifier) while there's an existing connection; ignoring")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("Connected to peripheral \(peripheral.identifier). Discovering services.");
        peripheral.delegate = self;
        peripheral.discoverServices([DesktopGaugeServiceUuid]);
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard(error == nil) else {
            NSLog("Peripheral \(peripheral.identifier) service discovery error \(String(describing:error))");
            cancelConnection(peripheral);
            return;
        }
        
        NSLog("Peripheral \(peripheral.identifier) service discovery succesful");
        if let service = peripheral.services?.first(where: { svc in svc.uuid == DesktopGaugeServiceUuid })
        {
            peripheral.discoverCharacteristics(nil, for: service);
        } else {
            cancelConnection(peripheral);
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        NSLog("Peripheral \(peripheral.identifier) chara discovered");
        
        if(currentPeripheral == nil) {
            NSLog("Peripheral \(peripheral.identifier) with chara - making connected");
            connectToPeripheral(peripheral);
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        NSLog("Peripheral \(peripheral.identifier) services modified; cancelling connection");
        
        cancelConnection(peripheral);
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("Peripheral \(peripheral.identifier) failed to connect; cancelling connection");

        cancelConnection(peripheral);
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("Peripheral \(peripheral.identifier) disconnected; cancelling connection");

        cancelConnection(peripheral)
    }

    func cancelConnection(_ peripheral: CBPeripheral) {
        NSLog("Disconnecting peripheral \(peripheral.identifier)");
        
        if(peripheral == currentPeripheral) {
            NSLog("Current peripheral disconnecting: \(String(describing:currentPeripheral?.identifier))");
            currentPeripheral = nil;
            gaugeManagers.forEach({ gm in gm.characteristic = nil});
        }

        cbCentral?.cancelPeripheralConnection(peripheral);
        pendingConnections.remove(peripheral);
    }
        
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        NSLog("Attempting to make current peripheral: \(peripheral.identifier)");

        if let service = peripheral.services?.first(where: { s in s.uuid == DesktopGaugeServiceUuid}) {
            let chara1 = service.characteristics?.first(where: { c in c.uuid == DesktopGaugeServiceGauge1CharaUuid });
            let chara2 = service.characteristics?.first(where: { c in c.uuid == DesktopGaugeServiceGauge2CharaUuid });
            
            if(chara1 != nil && chara2 != nil) {
                currentPeripheral = peripheral;
                gaugeManagers[0].characteristic = chara1;
                gaugeManagers[1].characteristic = chara2;
                
                NSLog("We now have a current peripheral: \(String(describing: currentPeripheral?.identifier))");
            } else {
                NSLog("Failed to obtain characteristics from: \(peripheral.identifier)");
                cancelConnection(peripheral);
            }
        }
    }
    
    func setGaugeValue(gauge: Int, value: uint8) {
        gaugeManagers[gauge].value = value;
    }
    
    func start() {
        cbCentral = CBCentralManager(delegate: self, queue: DispatchQueue.main);
        gaugeManagers[0].value=30;
        gaugeManagers[1].value=80;
    }
    
    
    var cbCentral: CBCentralManager?
    var pendingConnections: Set<CBPeripheral> = Set();

    var currentPeripheral: CBPeripheral?
    let gaugeManagers = [GaugeManager(), GaugeManager()]
}
