//
//  GaugeManager.swift
//  DesktopGauge
//
//  Created by Eldan Ben Haim on 03/02/2022.
//

import Foundation
import CoreBluetooth

class GaugeManager {
    init() {
        value = 0;
        characteristic = nil;
    }
    
    func flushToCharacteristic() {
        if let chara = self.characteristic {
            chara.service?.peripheral?.writeValue(Data([value]),
                                                  for: chara,
                                                  type: .withResponse);
        }
    }
    
    var value: uint8 {
        didSet {
            flushToCharacteristic();
        }
    }
    
    var characteristic: CBCharacteristic? {
        didSet {
            flushToCharacteristic();
        }
    }
}
