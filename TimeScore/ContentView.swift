//
//  ContentView.swift
//  TimeScore
//
//  主内容视图
//  作为应用的根视图，协调各个模块
//

import SwiftUI
import CoreData

struct ContentView: View {

    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        MainTabView()
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
    }
}
