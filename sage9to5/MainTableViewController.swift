//
//  MainTableViewController.swift
//  sage9to5
//
//  Created by Matthias Neumayr on 22.04.19.
//  Copyright © 2019 Fischgruppe. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications

class MainTableViewController: UITableViewController, WKNavigationDelegate {

  @IBOutlet weak var status: UITableViewCell!
  @IBOutlet weak var lastBooking: UITableViewCell!
  @IBOutlet weak var leaveTime: UITableViewCell!
  @IBOutlet weak var maxLeaveTime: UITableViewCell!
  @IBOutlet weak var webView: WKWebView!
  @IBOutlet weak var buttonToggle: UISwitch!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.browserKickoff()
    self.manageBrowserView()

    // App Settings
    let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
    print("library path is \(libraryPath)")
  }

  // MARK: - Logic
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    print("---> WKWebView didFinish URL: \(webView.url!.absoluteString)")

    if let url = webView.url?.absoluteString {
      if url.contains("/mportal/Logout.aspx") {
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Go to Login…")
        self.browserNavigateToLogin()
      }

      if url.contains("/mportal/Login.aspx") {
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Login…")
        self.browserLogin()
      }

      if url.contains("/mportal/Content/Home.aspx") {
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Open Time…")
        self.browserNavigateToTime()
      }

      if url.contains("/mportal/Content/Zeit/ZW/Default.aspx") {
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Collect data…")
        self.browserCollectStatus()
        self.browserCollectLastBooking()
        self.browserChangeLanguageToGerman()
        self.enableButtons()
      }
    }
  }

  // MARK: - View helper
  func disableButtons() {
    self.buttonToggle.isEnabled = false
  }

  func enableButtons() {
    self.refreshControl!.endRefreshing()
    self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to Refresh…")
    self.buttonToggle.isEnabled = true
  }

  func prepareToggle() {
    let statusText = self.status.detailTextLabel!.text!
    if statusText.contains("abwesend") || statusText.contains("absent") {
      self.buttonToggle.isOn = false
    } else {
      self.buttonToggle.isOn = true
    }
  }

  func manageBrowserView() {
    UserDefaults.standard.synchronize()
    let prefShowBrowser = UserDefaults.standard.bool(forKey: "showBrowser")
    print("showBrowser prefs: \(prefShowBrowser)")
    if !prefShowBrowser {
      webView.isHidden = true
      webView.frame.size.height = 0
    }
  }

  func parseLastBooking(_ rawTime: String) {
    let time = rawTime.split(separator: "-")

    if time[0] == "..." { return }

    let enterFormatter = DateFormatter()
    enterFormatter.dateFormat = "HH:mm"

    let enterDate = enterFormatter.date(from: String(time[0]))!
    let enterTime = enterFormatter.string(from: enterDate)
    UserDefaults.standard.set(enterTime, forKey: "enterTime")

    let forecastLeaveFormatter = DateFormatter()
    forecastLeaveFormatter.dateFormat = "HH:mm"

    // 8h + 30min brake
    let forcastDate = enterDate.addingTimeInterval(8.5 * 3600.0)
    let forecastLeaveTime = forecastLeaveFormatter.string(from: forcastDate)
    self.leaveTime.detailTextLabel!.text = forecastLeaveTime
    UserDefaults.standard.set(forecastLeaveTime, forKey: "forecastLeaveTime")

    // 10h + 45min brake
    let forcastMaxDate = enterDate.addingTimeInterval(10.75 * 3600.0)
    let forecastMaxLeaveTime = forecastLeaveFormatter.string(from: forcastMaxDate)
    self.maxLeaveTime.detailTextLabel!.text = forecastMaxLeaveTime
    UserDefaults.standard.set(forecastMaxLeaveTime, forKey: "forecastMaxLeaveTime")

    if time[1] != "..." {
      let leaveFormatter = DateFormatter()
      leaveFormatter.dateFormat = "HH:mm"

      let leaveDate = leaveFormatter.date(from: String(time[1]))!
      let leaveTime = leaveFormatter.string(from: leaveDate)
      UserDefaults.standard.set(leaveTime, forKey: "leaveTime")

      let dateIntervalFormatter = DateComponentsFormatter()
      dateIntervalFormatter.allowedUnits = [.day, .hour, .minute]
      dateIntervalFormatter.unitsStyle = .abbreviated

      let timeInMinutes = dateIntervalFormatter.string(from: enterDate, to: leaveDate)!
      UserDefaults.standard.set(timeInMinutes, forKey: "timeInMinutes")
    }
  }

  // MARK: - Send push
  func sendPushNotification(title: String, body: String, timeInterval: Double, identifier: String) {
    let notificationContent = UNMutableNotificationContent()
    notificationContent.title = title
    notificationContent.body = body
    notificationContent.sound = UNNotificationSound.default

    let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

    let notificationRequest = UNNotificationRequest(
      identifier: identifier,
      content: notificationContent,
      trigger: notificationTrigger
    )
    UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: nil)
  }

  func sendPushForEnter() {
    let enterTime = UserDefaults.standard.string(forKey: "enterTime")!
    let forecastLeaveTime = UserDefaults.standard.string(forKey: "forecastLeaveTime")!
    let forecastMaxLeaveTime = UserDefaults.standard.string(forKey: "forecastMaxLeaveTime")!

    // enter workplace push
    self.sendPushNotification(
      title: "Enter Workplace",
      body: "Successfully check in at \(enterTime)\nForecast: Healty at \(forecastLeaveTime) – Max: \(forecastMaxLeaveTime)",
      timeInterval: 0.5,
      identifier: "EnterWorkInfoPush"
    )

    // 8 hours (+brake) - go home reminder
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ReminderWorkInfoPush"])
    self.sendPushNotification(
      title: "9to5 Reminder",
      body: "Prepare – At \(forecastLeaveTime) it is time to go home!\nEnjoy your life!",
//      timeInterval: 8.25 * 3600.0,
      timeInterval: 10,
      identifier: "ReminderWorkInfoPush"
    )

    // 10 hours (+brake) - max working hours reminder
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ReminderMaxWorkInfoPush"])
    self.sendPushNotification(
      title: "9to7 Reminder",
      body: "Remember – It's \(forecastMaxLeaveTime) Enough for today!\nYou reached the maximum working hours.",
//      timeInterval: 10.75 * 3600.0,
      timeInterval: 30,
      identifier: "ReminderMaxWorkInfoPush"
    )
  }

  func sendPushForLeave() {
    let enterTime = UserDefaults.standard.string(forKey: "enterTime")!
    let leaveTime = UserDefaults.standard.string(forKey: "leaveTime")!
    let timeInMinutes = UserDefaults.standard.string(forKey: "timeInMinutes")!

    // leave workplace push
    self.sendPushNotification(
      title: "Leave Workplace",
      body: "Successfully check out at \(leaveTime) \nInfo: \(enterTime) → \(leaveTime) = \(timeInMinutes)",
      timeInterval: 0.5,
      identifier: "LeaveWorkInfoPush"
    )
  }

  // MARK: - Browser Actions
  func browserKickoff() {
    self.disableButtons()
    self.browserInit()
  }

  func browserInit() {
    let url = URL(string: "https://portal106427097.bpo-sage.de/mportal/Login.aspx")!
    let request = URLRequest(url: url)
    webView.navigationDelegate = self
    webView.load(request)
  }

  func browserLogin() {
    let username = UserDefaults.standard.string(forKey: "username")!
    let password = UserDefaults.standard.string(forKey: "password")!

    let script = """
      document.getElementById('ctl00_cphContent_txtUsername_I').value = '\(username)';
      document.getElementById('ctl00_cphContent_txtPassword_I').value = '\(password)';
      document.getElementById('ctl00_cphContent_cmdLogin').click();
    """
    webView.evaluateJavaScript(script, completionHandler: nil)
  }

  func browserNavigateToLogin() {
    let script = "document.getElementById('ctl00_cphContent_lnkRelogin').click();"
    webView.evaluateJavaScript(script, completionHandler: nil)
  }

  func browserNavigateToTime() {
    let script = "NavigateToUrl('/mportal/Content/Zeit/ZW/Default.aspx');"
    webView.evaluateJavaScript(script, completionHandler: nil)
  }

  func browserCollectStatus() {
    let script = "document.getElementById('ctl00_cphContent_ucTerminal_lblStatus').innerHTML;"
    webView.evaluateJavaScript(script, completionHandler: { (data, _) in
      let myData = data.flatMap({$0 as? String})
      self.status.detailTextLabel!.text = myData
      self.prepareToggle()
    })
  }

  func browserCollectLastBooking() {
    let script = "document.getElementById('ctl00_cphContent_ucTerminal_lblletzteBuchung').innerHTML;"
    webView.evaluateJavaScript(script, completionHandler: { (data, _) in
      let myData = data.flatMap({$0 as? String})
      self.lastBooking.detailTextLabel!.text = myData
      self.parseLastBooking(myData ?? "...-...")

      // send push after collection the latest data
      // browserClickEnter
      let browserClickEnter = UserDefaults.standard.bool(forKey: "browserClickEnter")
      if browserClickEnter {
        UserDefaults.standard.set(false, forKey: "browserClickEnter")
        self.sendPushForEnter()
      }

      // browserClickLeave
      let browserClickLeave = UserDefaults.standard.bool(forKey: "browserClickLeave")
      if browserClickLeave {
        UserDefaults.standard.set(false, forKey: "browserClickLeave")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        self.sendPushForLeave()
      }
    })
  }

  func browserChangeLanguageToGerman() {
    // swiftlint:disable:next line_length
    let script = "if (document.getElementById('ctl00_lblMySettings').innerHTML == 'settings') { __doPostBack('ctl00','LANG_DE'); }"
    webView.evaluateJavaScript(script, completionHandler: nil)
  }

  func browserClickEnter() {
    let script = "document.getElementById('ctl00_cphContent_ucTerminal_btnKommen').click();"
    webView.evaluateJavaScript(script, completionHandler: nil)
  }

  func browserClickLeave() {
    let script = "document.getElementById('ctl00_cphContent_ucTerminal_btnGehen').click();"
    webView.evaluateJavaScript(script, completionHandler: nil)
  }

  func browserLogout() {
    let script = "NavigateToUrl('/mportal/Logout.aspx?userlogout=1');"
    webView.evaluateJavaScript(script, completionHandler: nil)
  }

  // MARK: - IBAction's
  @IBAction func refreshData(_ sender: Any) {
    self.disableButtons()
    self.browserNavigateToTime()
  }

  @IBAction func toggleButton(_ sender: UISwitch) {
    if sender.isOn {
      self.browserClickEnter()
      UserDefaults.standard.set(true, forKey: "browserClickEnter")
    } else {
      self.browserClickLeave()
      UserDefaults.standard.set(true, forKey: "browserClickLeave")
    }
  }

  @IBAction func settingsButton(_ sender: UIBarButtonItem) {
    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)

  }
}
