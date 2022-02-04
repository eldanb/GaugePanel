//
//  main.swift
//  DesktopGauge
//
//  Created by Eldan Ben Haim on 03/02/2022.
//

import Foundation

import Foundation
import CoreBluetooth

import PerfectSysInfo


var lastCpuTotal = 0;
var lastCpuIdle = 0;

func getCpuLoad() -> Double? {

    if let cpu = SysInfo.CPU["cpu"] {
        let newTotal = cpu.reduce(0, { partialResult, entry in
            partialResult + entry.value
        });
        let newIdle = cpu["idle"] ?? 0;
        
        let idleRatio = Double(newIdle - lastCpuIdle) / Double(newTotal - lastCpuTotal);
        let busyRatio = (1 - idleRatio);

        lastCpuTotal = newTotal;
        lastCpuIdle = newIdle;

        return busyRatio;
    }
    
    return nil;
}

func getMemoryLoad() -> Double {
    let memory = SysInfo.Memory;
    let totalMem = (memory["active"] ?? 0) + (memory["inactive"] ?? 0) + (memory["wired"] ?? 0) + (memory["free"] ?? 0) + 1;
    let freeMem = memory["free"] ?? 0;
    
    let memRatio = 1 - (Double(freeMem)/Double(totalMem));
    
    return memRatio;
}

let desktopGaugeManager = DektopGaugeManager();
desktopGaugeManager.start();

let timer = Timer.scheduledTimer(withTimeInterval: 1,
                                   repeats: true) { _ in
    if let busyRatio = getCpuLoad() {
        desktopGaugeManager.setGaugeValue(gauge: 0, value: uint8(busyRatio*255));
    }
    
    let memRatio = getMemoryLoad();
    desktopGaugeManager.setGaugeValue(gauge: 1, value: uint8(memRatio*255));
}

let runLoop = RunLoop.current
let distantFuture = Date.distantFuture

while runLoop.run(mode: RunLoop.Mode.default, before: distantFuture) {
}

