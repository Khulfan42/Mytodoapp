//
//  mytodoappApp.swift
//  mytodoapp
//
//  Created by Muhammad Khulfan on 01/11/2026.
//

import SwiftUI

@main
struct mytodoappApp: App {
    var body: some Scene {
        WindowGroup {
            let persistenceController = PersistenceController.shared
            ContentView()
                .environment(\.managedObjectContext,
                              persistenceController.container.viewContext)
        }
    }
}
