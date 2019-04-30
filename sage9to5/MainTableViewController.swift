//
//  MainTableViewController.swift
//  sage9to5
//
//  Created by Matthias Neumayr on 22.04.19.
//  Copyright © 2019 Fischgruppe. All rights reserved.
//

import UIKit
import WebKit

class MainTableViewController: UITableViewController, WKNavigationDelegate {

  @IBOutlet weak var status: UITableViewCell!
  @IBOutlet weak var lastBooking: UITableViewCell!
  @IBOutlet weak var leaveTime: UITableViewCell!
  @IBOutlet weak var webView: WKWebView!
  @IBOutlet weak var buttonToggle: UIButton!
  @IBOutlet weak var activityToggle: UIActivityIndicatorView!

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
      if url.contains("/mportal/Login.aspx") {
        self.browserLogin()
      }

      if url.contains("/mportal/Content/Home.aspx") {
        self.browserNavigateToTime()
      }

      if url.contains("/mportal/Content/Zeit/ZW/Default.aspx") {
        self.browserCollectStatus()
        self.browserCollectLastBooking()
        self.enableButtons()
      }
    }
  }

  // MARK: - View helper
  func disableButtons() {
    activityToggle.hidesWhenStopped = true
    self.activityToggle.startAnimating()
    self.buttonToggle.isEnabled = false
  }

  func enableButtons() {
    self.activityToggle.stopAnimating()
    self.refreshControl!.endRefreshing()
    self.buttonToggle.isEnabled = true
  }

  func manageBrowserView() {
    UserDefaults.standard.synchronize()
    let prefShowBrowser = UserDefaults.standard.bool(forKey: "showBrowser")
    print("showBrowser prefs: \(prefShowBrowser)")
    if !prefShowBrowser {
      webView.isHidden = true
    }
  }

  func parseLastBooking(_ rawTime: String) {
    let time = rawTime.split(separator: "-")
    print(time[0])

    if time[0] == "..." { return }

    let enterFormatter = DateFormatter()
    enterFormatter.locale = Locale(identifier: "de_DE")
    enterFormatter.dateFormat = "HH:mm"

    var enterDate = enterFormatter.date(from: String(time[0]))!
    enterDate.addTimeInterval(8.5 * 3600.0)

    let resultFormatter = DateFormatter()
    resultFormatter.dateFormat = "HH:mm"
    let leaveTime = resultFormatter.string(from: enterDate)
    self.leaveTime.detailTextLabel!.text = leaveTime
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

  func browserNavigateToTime() {
    let script = "NavigateToUrl('/mportal/Content/Zeit/ZW/Default.aspx');"
    webView.evaluateJavaScript(script, completionHandler: nil)
  }

  func browserCollectStatus() {
    let script = "document.getElementById('ctl00_cphContent_ucTerminal_lblStatus').innerHTML;"
    webView.evaluateJavaScript(script, completionHandler: { (data, _) in
      let myData = data.flatMap({$0 as? String})
      self.status.detailTextLabel!.text = myData
    })
  }

  func browserCollectLastBooking() {
    let script = "document.getElementById('ctl00_cphContent_ucTerminal_lblletzteBuchung').innerHTML;"
    webView.evaluateJavaScript(script, completionHandler: { (data, _) in
      let myData = data.flatMap({$0 as? String})
      self.lastBooking.detailTextLabel!.text = myData
      self.parseLastBooking(myData ?? "...-...")
    })
  }

  func browserChangeLanguage() {
    let script = "__doPostBack('ctl00','LANG_DE');"
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

  @IBAction func toggleButton(_ sender: UIButton) {
    self.disableButtons()
    let statusText = self.status.detailTextLabel!.text!
    if statusText.contains("abwesend") || statusText.contains("absent") {
      self.browserClickEnter()
    } else {
      self.browserClickLeave()
    }
  }
}
