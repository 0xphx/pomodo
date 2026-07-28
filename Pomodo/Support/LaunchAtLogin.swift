// Pomodo/Support/LaunchAtLogin.swift
import ServiceManagement

struct LaunchAtLogin {
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("LaunchAtLogin: Statusänderung fehlgeschlagen: \(error)")
        }
        return isEnabled
    }

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
