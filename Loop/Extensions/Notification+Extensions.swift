//
//  Notification+Extensions.swift
//  Loop
//
//  Created by Kai Azim on 2023-06-14.
//

import Foundation

extension Notification.Name {
    static let updateBackendDirection = Notification.Name("updateBackendDirection")
    static let updateUIDirection = Notification.Name("updateUIDirection")

    static let forceCloseLoop = Notification.Name("forceCloseLoop")
    static let activeStateChanged = Notification.Name("activeStateChanged")

    static let systemWindowManagerStateChanged = Notification.Name("systemWindowManagerStateChanged")

    static let didImportKeybindsSuccessfully = Notification.Name("didImportKeybindsSuccessfully")
    static let didExportKeybindsSuccessfully = Notification.Name("didExportKeybindsSuccessfully")

    @discardableResult
    func onReceive(object: Any? = nil, using: @escaping (Notification) -> ()) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: self,
            object: object,
            queue: .main,
            using: using
        )
    }

    func post(object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: self, object: object, userInfo: userInfo)
    }
}
