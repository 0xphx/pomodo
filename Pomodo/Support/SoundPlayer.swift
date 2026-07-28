import AppKit

struct SoundPlayer {
    @discardableResult
    func play(_ preset: SoundPreset) -> Bool {
        let sound = NSSound(named: preset.rawValue) ?? NSSound(named: SoundPreset.glass.rawValue)
        return sound?.play() ?? false
    }
}
