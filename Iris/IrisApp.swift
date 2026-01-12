//
//  IrisApp.swift
//  Iris
//
//  Created by Ayon Sarkar on 12/01/26.
//

import SwiftUI
import Combine
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var manager = TimerManager()
    private var breakWindowController: BreakWindowController?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
      
        setupLaunchAtLogin()
       
        manager.$isBreakWindowVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in
                if visible {
                    self?.showBreakWindow()
                } else {
                    self?.hideBreakWindow()
                }
            }
            .store(in: &cancellables)
    }
  
    private func setupLaunchAtLogin() {
        let service = SMAppService.mainApp
        
      
        if service.status == .notRegistered {
            do {
                try service.register()
                print("Iris: Successfully registered for login launch.")
            } catch {
                print("Iris: Failed to register login item: \(error.localizedDescription)")
            }
        } else {
            print("Iris: Login item status is \(service.status.description)")
        }
    }
    
    private func showBreakWindow() {
        if breakWindowController == nil {
            breakWindowController = BreakWindowController(manager: manager)
        }
        breakWindowController?.show()
    }
    
    private func hideBreakWindow() {
        breakWindowController?.hide()
    }
}

extension SMAppService.Status {
    var description: String {
        switch self {
        case .notRegistered: return "Not Registered"
        case .enabled: return "Enabled"
        case .requiresApproval: return "Requires User Approval in System Settings"
        case .notFound: return "Not Found"
        @unknown default: return "Unknown"
        }
    }
}

@main
struct IrisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Iris", systemImage: "eye") {
            ContentView(manager: appDelegate.manager)
        }
        .menuBarExtraStyle(.window)
    }
}
