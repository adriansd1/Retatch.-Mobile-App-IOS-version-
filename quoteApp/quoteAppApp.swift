//
//  quoteAppApp.swift
//  quoteApp
//
//  Created by Hajar Daryagasht on 2024-05-15.
//

import SwiftUI

@main
struct quoteAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
