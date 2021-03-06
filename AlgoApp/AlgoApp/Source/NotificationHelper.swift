//
//  Scheduler.swift
//  AlgoApp
//
//  Created by Huong Do on 3/17/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RxSwift
import UIKit
import UserNotifications

final class NotificationHelper: NSObject {
    
    static let shared = NotificationHelper()
    let center = UNUserNotificationCenter.current()
    
    private static let openProblemActionId = "com.ichigo.AlgoApp.reminders.problem"
    private static let reminderCategoryId = "com.ichigo.AlgoApp.reminders"
    
    private static let reminderIdKey = "reminderId"
    
    private var pendingReminderId: String?
    
    private let reminderTitles: [String] = [
        "Time to practice coding again!",
        "What time is it? Puzzle time!",
        "You asked to be reminded - you got it!",
        "Yet another reminder to practice coding",
        "Ready? Puzzle time!",
        "Time to hack another algo problem!",
        "Knock knock, where's our hacker at?"
    ]
    
    private let reminderBodies: [String] = [
        "A coding challenge is waiting for you to solve 👩‍💻",
        "Keep your coding skills sharp with at least one challenge a day 🤓",
        "You're doing better everyday 🥳 Here's another coding challenge for you.",
        "You're guaranteed to learn something new 🤯 by trying this coding problem.",
        "Be a ninja and take on this one challenge picked especially for you 😏",
        "All ninjas need to practice their skills everyday, you know you do too 🤓",
        "Algo problems are fun if you practice them everyday ✨"
    ]
    
    override init() {
        super.init()
        setupNotificationSettings()
    }
    
    func setupNotificationSettings() {
        
        let openProblemAction = UNNotificationAction(
            identifier: NotificationHelper.openProblemActionId,
            title: "Solve Problem",
            options: .foreground
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: NotificationHelper.reminderCategoryId,
            actions: [openProblemAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        center.setNotificationCategories([reminderCategory])
        center.delegate = self
    }
    
    func updateScheduledNotifications(for reminder: ReminderDetail) {
        cancelScheduledNotifications(for: reminder) { [weak self] in
            guard reminder.enabled else { return }
            
            let content = UNMutableNotificationContent()
            content.title = self?.reminderTitles.randomElement() ?? ""
            content.body = self?.reminderBodies.randomElement() ?? ""
            content.categoryIdentifier = NotificationHelper.reminderCategoryId
            content.userInfo[NotificationHelper.reminderIdKey] = reminder.id
            
            let calendar = Calendar.current
            let minuteComponent = calendar.component(.minute, from: reminder.date)
            let hourComponent = calendar.component(.hour, from: reminder.date)
            
            var dateComponents = DateComponents()
            dateComponents.calendar = calendar
            dateComponents.hour = hourComponent
            dateComponents.minute = minuteComponent
            
            if reminder.repeatDays.isEmpty {
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                self?.center.add(request, withCompletionHandler: nil)
            } else {
                for weekday in reminder.repeatDays {
                    dateComponents.weekday = weekday
                    
                    // different titles and bodies for different days
                    content.title = self?.reminderTitles.randomElement() ?? ""
                    content.body = self?.reminderBodies.randomElement() ?? ""
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    self?.center.add(request, withCompletionHandler: nil)
                }
            }
        }
    }
    
    func showPendingQuestion() {
        guard let id = pendingReminderId else { return }
        guard let questionId = Reminder.randomQuestionId(for: id) else { return }
        AppHelper.showQuestionDetail(for: questionId) { [weak self] in
            self?.pendingReminderId = id
        }
    }
    
    func cancelScheduledNotifications(for reminder: ReminderDetail, completionHandler: @escaping (() -> Void)) {
        
        center.getPendingNotificationRequests { [weak self] requests in
            var foundRequestIds: [String] = []
            for request in requests {
                guard let reminderId = request.content.userInfo[NotificationHelper.reminderIdKey] as? String,
                    reminderId == reminder.id else { continue }
                foundRequestIds.append(request.identifier)
            }
            
            self?.center.removePendingNotificationRequests(withIdentifiers: foundRequestIds)
            completionHandler()
        }
    }
    
    func scheduleNotificationIfNeeded(for reminder: ReminderDetail) {
        if reminder.enabled == false || (reminder.repeatDays.isEmpty && reminder.date < Date()) {
            return
        }
        center.getPendingNotificationRequests { [weak self] requests in
            if (requests.filter { ($0.content.userInfo[NotificationHelper.reminderIdKey] as? String) == reminder.id }).isEmpty {
                self?.updateScheduledNotifications(for: reminder)
            }
        }

    }
}

extension NotificationHelper: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        completionHandler()
        
        if let reminderId = response.notification.request.content.userInfo[NotificationHelper.reminderIdKey] as? String {
            
            guard let questionId = Reminder.randomQuestionId(for: reminderId) else { return }
            AppHelper.showQuestionDetail(for: questionId) { [weak self] in
                self?.pendingReminderId = reminderId
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(UNNotificationPresentationOptions.alert)
    }
}

extension Reactive where Base: UNUserNotificationCenter {
    
    public func requestAuthorization(options: UNAuthorizationOptions = []) -> Single<Bool> {
        return Single.create(subscribe: { (event) -> Disposable in
            self.base.requestAuthorization(options: options) { (success: Bool, error: Error?) in
                if let error = error {
                    event(.error(error))
                } else {
                    event(.success(success))
                }
            }
            return Disposables.create()
        })
    }
}

