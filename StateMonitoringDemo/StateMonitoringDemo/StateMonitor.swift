//
//  StateMonitor.swift
//  StateMonitoringDemo
//
//  Created by Valeriy Efimov on 3/25/19.
//  Copyright © 2019 tomych. All rights reserved.
//

import AVFoundation
import UIKit

protocol StateHandler: class {
    func didChangeAccessours(state: Accessours)
    func didChangePowerMode(state: PowerMode)
    func didChangePowerState(state: PowerState)
    func didChangeTermalState(state: TermalState)
    func didChangeOrientation(orientation: UIDeviceOrientation)
}

class StateMonitor {
    var delegate: StateHandler
    
    init(with delegate: StateHandler) {
        self.delegate = delegate
        try? AVAudioSession.sharedInstance().setActive(true, options: [])

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationStateDidChange(_:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(batteryStateDidChange(_:)),
                                               name: UIDevice.batteryStateDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(termalStateDidChange(_:)),
                                               name: ProcessInfo.thermalStateDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange(_:)),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(powerModeDidChange(_:)),
                                               name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.isBatteryMonitoringEnabled = false
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

// MARK: - State names
enum Accessours {
    case headphones
    case bluetoothA2DP
    case airPlay
    case bluetoothLE
    case bluetoothHFP
    case usbAudio
    case carAudio
}

enum PowerMode {
    case ordinary
    case lowPower
}

enum PowerState {
    case charging
    case full
    case unplugged
}

enum TermalState {
    case fair
    case critical
    case serious
    case nominal
}

// MARK: - Orientation handling
extension StateMonitor {
    @objc func orientationStateDidChange(_ notification: NSNotification) {
        delegate.didChangeOrientation(orientation: UIDevice.current.orientation)
    }
}

// MARK: - Thermal handling
extension StateMonitor {
    @objc func termalStateDidChange(_ notification: NSNotification) {
        switch ProcessInfo.processInfo.thermalState {
        case .fair:
            delegate.didChangeTermalState(state: .fair)
        case .critical:
            delegate.didChangeTermalState(state: .critical)
        case .serious:
            delegate.didChangeTermalState(state: .serious)
        case .nominal:
            delegate.didChangeTermalState(state: .nominal)
        }
    }
}

// MARK: - Power & battery handling
extension StateMonitor {
    @objc func batteryStateDidChange(_ notification: NSNotification) {
        switch UIDevice.current.batteryState {
        case .charging:
            delegate.didChangePowerState(state: .charging)
        case .full:
             delegate.didChangePowerState(state: .full)
        case .unplugged:
             delegate.didChangePowerState(state: .unplugged)
        case .unknown:
             delegate.didChangePowerState(state: .unplugged)
        }
    }
    
    @objc func powerModeDidChange(_ notification: NSNotification) {
        let isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        delegate.didChangePowerMode(state: isLowPowerModeEnabled ? .lowPower : .ordinary)
    }
}

// MARK: - Accessours handling
extension StateMonitor {
    @objc func handleRouteChange(_ notification: Notification) {
        let userInfo = notification.userInfo
        guard let reasonRaw = userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber else { return }
        let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw.uintValue)
        
        if reason == .newDeviceAvailable {
            let device = AVAudioSession.sharedInstance().currentRoute.outputs.first?.portType
            switch device {
            case AVAudioSession.Port.headphones:
                delegate.didChangeAccessours(state: .headphones)
            case AVAudioSession.Port.bluetoothA2DP:
                  delegate.didChangeAccessours(state: .bluetoothA2DP)
            case AVAudioSession.Port.airPlay:
                  delegate.didChangeAccessours(state: .airPlay)
            case AVAudioSession.Port.bluetoothLE:
                  delegate.didChangeAccessours(state: .bluetoothLE)
            case AVAudioSession.Port.bluetoothHFP:
                  delegate.didChangeAccessours(state: .bluetoothHFP)
            case AVAudioSession.Port.usbAudio:
                  delegate.didChangeAccessours(state: .usbAudio)
            case AVAudioSession.Port.carAudio:
                 delegate.didChangeAccessours(state: .carAudio)
            default: print("Other device e.g. HDMI")
            }
        }
    }
}
