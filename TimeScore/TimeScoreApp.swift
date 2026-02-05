//
//  TimeScoreApp.swift
//  TimeScore
//
//  iOS 应用入口
//  对应 Python 版本的 main.py
//

import SwiftUI

@main
struct TimeScoreApp: App {

    // CoreData 持久化控制器
    let persistenceController = CoreDataStack.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}
