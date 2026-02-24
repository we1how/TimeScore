//
//  TimeScoreApp.swift
//  TimeScore
//
//  iOS 应用入口
//  对应 Python 版本的 main.py
//  P0更新: 配置 Widget 和通知
//

import SwiftUI
import WidgetKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 配置通知中心代理
        UNUserNotificationCenter.current().delegate = self

        // P0: 请求通知权限
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("通知权限已获取")
                NotificationManager.shared.setupDefaultReminders()
            } else {
                print("通知权限被拒绝")
            }
        }

        return true
    }

    // 处理前台通知显示
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // 处理通知点击
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("通知被点击: \(userInfo)")
        completionHandler()
    }

    // 应用进入前台时刷新 Widget
    func applicationDidBecomeActive(_ application: UIApplication) {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

@main
struct TimeScoreApp: App {

    // CoreData 持久化控制器
    let persistenceController = CoreDataStack.shared

    // App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .onAppear {
                    // 刷新 Widget
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}
