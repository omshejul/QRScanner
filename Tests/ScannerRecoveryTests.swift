import Foundation

@main
struct RecoveryTests {
    static func main() {
        let still = Array(repeating: Array(repeating: 0.5, count: 16), count: 12)
        let flicker = (0..<12).map { Array(repeating: $0.isMultiple(of: 2) ? 0.35 : 0.65, count: 16) }
        precondition(!ScannerRecovery.hasFlicker(still))
        precondition(ScannerRecovery.hasFlicker(flicker))
        precondition(!ScannerRecovery.hasFlicker((0..<12).map { Array(repeating: Double($0) / 20, count: 16) }))
        let printedPattern = Array(repeating: (0..<16).map { $0.isMultiple(of: 2) ? 0.1 : 0.9 }, count: 12)
        precondition(!ScannerRecovery.hasFlicker(printedPattern))
        var localizedMotion = still
        for i in 0..<12 { localizedMotion[i][0] = i.isMultiple(of: 2) ? 0 : 1 }
        precondition(!ScannerRecovery.hasFlicker(localizedMotion))

        var recovery = ScannerRecovery()
        var action: ScannerRecovery.Action?
        for i in 0..<12 { action = recovery.observe(flicker[i], at: Double(i) / 30, undecodedQR: false) }
        precondition(action == .exposure(0.01))
        precondition(recovery.observe(Array(repeating: 0.05, count: 16), at: 1, undecodedQR: false) == .automatic)
        precondition(recovery.observe(flicker[0], at: 1.1, undecodedQR: false) == nil)

        recovery = ScannerRecovery()
        for i in 0..<12 { action = recovery.observe(flicker[i], at: Double(i) / 30, undecodedQR: false) }
        precondition(recovery.observe(Array(repeating: 0.65, count: 16), at: 9, undecodedQR: false) == .automatic)

        recovery = ScannerRecovery()
        for i in 0..<300 {
            precondition(recovery.observe(still[0], at: Double(i) / 10, undecodedQR: false) == nil)
        }
        precondition(recovery.observe(still[0], at: 30, undecodedQR: true) == nil)
        precondition(recovery.observe(still[0], at: 33.1, undecodedQR: true) == .ultraWide)
        precondition(recovery.observe(still[0], at: 37, undecodedQR: true) == nil)
        precondition(recovery.observe(still[0], at: 41, undecodedQR: true) == nil)

        recovery = ScannerRecovery()
        var time = 0.0
        var actions: [ScannerRecovery.Action] = []
        for i in 0..<600 {
            time += 1.0 / 30
            if let next = recovery.observe(flicker[i % 12], at: time, undecodedQR: false) { actions.append(next) }
        }
        precondition(Array(actions.prefix(5)) == [.exposure(1.0 / 100), .exposure(1.0 / 120), .exposure(1.0 / 50), .exposure(1.0 / 60), .ultraWide])
        precondition(actions.filter { $0 == .ultraWide }.count == 1)

        precondition(ScannerRecovery.compensatedISO(currentISO: 200, currentDuration: 0.005, duration: 0.01, minimum: 50, maximum: 1600) == 100)
        precondition(ScannerRecovery.compensatedISO(currentISO: 50, currentDuration: 0.001, duration: 0.02, minimum: 50, maximum: 1600) == nil)
        precondition(ScannerRecovery.compensatedISO(currentISO: 1600, currentDuration: 0.03, duration: 0.01, minimum: 50, maximum: 1600) == nil)
        print("Recovery tests passed: flicker, stable scenes, motion, exposure reset, QR-gated fallback, ISO bounds")
    }
}
