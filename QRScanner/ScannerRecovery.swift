import Foundation

// Camera-independent policy. Samples and state stay on the capture queue.
struct ScannerRecovery {
    enum Action: Equatable {
        case exposure(Double)
        case automatic
        case ultraWide
    }

    private var samples: [[Double]] = []
    private var exposureStep: Int?
    private var changedAt = -Double.infinity
    private var automaticUntil = 0.0
    private var referenceBrightness = 0.0
    private var candidateSince: Double?
    private var usedUltraWide = false
    private let durations = [1.0 / 100, 1.0 / 120, 1.0 / 50, 1.0 / 60]

    mutating func resetExposure(at time: Double) {
        samples.removeAll()
        exposureStep = nil
        candidateSince = nil
        automaticUntil = time + 3
    }

    mutating func observe(_ patches: [Double], at time: Double, undecodedQR: Bool) -> Action? {
        guard patches.count == 16, patches.allSatisfy({ $0.isFinite }) else { return nil }
        let brightness = patches.reduce(0, +) / 16
        if undecodedQR {
            if candidateSince == nil { candidateSince = time }
        } else {
            candidateSince = nil
        }
        // A timeout alone is not evidence of a QR code.
        if let since = candidateSince, time - since > 3, !usedUltraWide {
            usedUltraWide = true
            resetExposure(at: time)
            return .ultraWide
        }
        guard time >= automaticUntil else { return nil }
        if exposureStep != nil {
            guard time - changedAt > 0.5 else { return nil }
            // Never leave custom ISO/shutter locked across changing scenes.
            if time - changedAt > 8 || brightness < 0.08 || brightness > 0.92 || abs(brightness - referenceBrightness) > 0.20 {
                resetExposure(at: time)
                return .automatic
            }
        }
        samples.append(patches)
        if samples.count > 12 { samples.removeFirst() }
        guard Self.hasFlicker(samples) else { return nil }
        let next = (exposureStep ?? -1) + 1
        if next == durations.count {
            resetExposure(at: time)
            if !usedUltraWide {
                usedUltraWide = true
                return .ultraWide
            }
            return .automatic
        }
        referenceBrightness = samples.flatMap { $0 }.reduce(0, +) / Double(samples.count * 16)
        exposureStep = next
        changedAt = time
        samples.removeAll()
        return .exposure(durations[next])
    }

    static func hasFlicker(_ samples: [[Double]]) -> Bool {
        guard samples.count == 12, samples.allSatisfy({ $0.count == 16 }) else { return false }
        // Repeated oscillation across most of the image, not a single brightness
        // change or the static black/white pattern of a printed QR code.
        let flickeringPatches = (0..<16).filter { patch in
            let values = samples.map { $0[patch] }
            guard values.max()! - values.min()! > 0.10 else { return false }
            let differences = zip(values.dropFirst(), values).map(-)
            let significant = differences.filter { abs($0) > 0.025 }
            return zip(significant.dropFirst(), significant).filter { $0 * $1 < 0 }.count >= 6
        }
        return flickeringPatches.count >= 12
    }

    static func compensatedISO(currentISO: Double, currentDuration: Double,
                               duration: Double, minimum: Double, maximum: Double) -> Double? {
        guard duration > 0, currentDuration > 0 else { return nil }
        let iso = currentISO * currentDuration / duration
        // Reject timings that cannot maintain approximately the existing brightness.
        guard iso.isFinite, iso >= minimum * 0.8, iso <= maximum * 1.2 else { return nil }
        return min(maximum, max(minimum, iso))
    }
}
