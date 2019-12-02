//
//  CredentialsTableViewController.swift
//  sage9to5
//
//  Created by Matthias Neumayr on 28.04.19.
//  Copyright © 2019 Fischgruppe. All rights reserved.
//

import UIKit

class OnboardingViewController: UITableViewController {

  @IBOutlet weak var username: UITextField!
  @IBOutlet weak var password: UITextField!

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.prompt = UserDefaults.standard.string(forKey: "url")
  }

  @IBAction func onSave(_ sender: UIBarButtonItem) {
    if username.text!.count > 0 && password.text!.count > 0 {
      UserDefaults.standard.set(username.text!, forKey: "username")
      UserDefaults.standard.set(password.text!, forKey: "password")

      performSegue(withIdentifier: "toMainSegue", sender: self)
    }
  }
}
