//
//  AddEmailViewController.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit
import TextFieldEffects
import PopupDialog

class AddEmailViewController: ConfirmedBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        if !isPostboarding {
            self.emailTextField?.becomeFirstResponder()
        }
    }
    
    func showInfoMessage(infoString : String) {
        let title = "ONE MORE THING..."
        let message = infoString
        
        let popup = PopupDialog(title: title, message: message, image: nil, transitionStyle: .zoomIn, hideStatusBar: false)
        
        let acceptButton = DefaultButton(title: "OK", dismissOnTap: true) { }
        popup.addButtons([acceptButton])
        
        self.present(popup, animated: true, completion: nil)
        
        NotificationCenter.post(name: .dismissOnboarding)
        self.dismiss(animated: true, completion: {})
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            //self.createSigninButton?.normalCornerRadius = 4
            self.createSigninButton?.isUserInteractionEnabled = true
            self.createSigninButton?.setOriginalState()
            self.createSigninButton?.layer.cornerRadius = 4
        }
    }
    
    func showErrorMessage(errorString : String) {
        
        let title = "ERROR SIGNING UP"
        let message = errorString
        let popup = PopupDialog(title: title, message: message, image: nil, transitionStyle: .zoomIn, hideStatusBar: false)
        
        let acceptButton = DefaultButton(title: "OK", dismissOnTap: true) { }
        popup.addButtons([acceptButton])
        
        self.present(popup, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            //self.createSigninButton?.normalCornerRadius = 4
            self.createSigninButton?.isUserInteractionEnabled = true
            self.createSigninButton?.setOriginalState()
            self.createSigninButton?.layer.cornerRadius = 4
        }
    }
    
    @IBAction func addEmailLater () {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showAddEmailScreen" {
            isFromAccountPage = true
        }
        else {
            isFromAccountPage = false
        }
    }
    
    @IBAction func createSignInPressed () {
        self.createSigninButton?.isUserInteractionEnabled = false
        self.createSigninButton?.startLoadingAnimation()
        
        let email = self.emailTextField?.text
        let password = self.passwordTextField?.text
        
        if (!Utils.isValidEmail(emailAddress: email!) || email == nil) || (password == nil || password!.count < 8) {
            showErrorMessage(errorString: "Please make sure to enter a valid e-mail and a password that contains at least eight characters, a capital letter, a number, and a special character.")
            
            return
        }
        
        Auth.createUser(email: email!, password: password!, passwordConfirmation: password!, createUserCallback: {(_ status: Bool, _ reason: String, _ code: Int) -> Void in
            if status || code == Global.kEmailNotConfirmed {
                self.showInfoMessage(infoString: "Please check your e-mail for a confirmation link and your sign-in will be enabled")
            }
            else {
                self.showErrorMessage(errorString: reason)
            }
        })
        
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var isFromAccountPage = false
    var isPostboarding : Bool = false
    
    @IBOutlet var createSigninButton: TKTransitionSubmitButton?
    @IBOutlet var emailTextField: HoshiTextField?
    @IBOutlet var passwordTextField: HoshiTextField?

}
