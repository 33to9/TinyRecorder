//
//  SleepPreventer.swift
//  TinyRecorder
//
//  Created by apple on 2024/12/9.
//

import Foundation
import IOKit.pwr_mgt

class SleepPreventer {
    static let shared = SleepPreventer()
    private var assertionID: IOPMAssertionID = 0
    private var isActive = false
    private let lock = NSLock()
    
    /// 申请阻止屏幕睡眠；已处于激活状态时不重复申请（避免泄漏旧的 assertion）
    func preventSleep(reason: String) {
        lock.lock()
        defer { lock.unlock() }
        if isActive { return }
        let type = "PreventUserIdleDisplaySleep" as CFString
        let reason = reason as CFString
        var newID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(type, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason, &newID)
        if result == kIOReturnSuccess {
            assertionID = newID
            isActive = true
        } else {
            print("Failure to prevent sleep, error: \(result)")
        }
    }
    
    /// 释放阻止睡眠的 assertion；幂等，可无条件调用
    func allowSleep() {
        lock.lock()
        defer { lock.unlock() }
        guard isActive else { return }
        let result = IOPMAssertionRelease(assertionID)
        if result != kIOReturnSuccess { print("Failed to release assertion, error: \(result)") }
        assertionID = 0
        isActive = false
    }
}
