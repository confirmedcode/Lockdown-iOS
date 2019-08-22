//
//  WebViewViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import WebKit
import UIKit

class WebViewViewController: BaseViewController, WKNavigationDelegate {
    
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var titleLabel: UILabel!
    var url: URL?
    var titleLabelText: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let u = url {
            webView.load(URLRequest(url: u))
        }
        webView.navigationDelegate = self
        titleLabel.text = titleLabelText
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (webView.isLoading == false) {
            self.activity.stopAnimating()
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.activity.startAnimating()
    }
    
    @IBAction func safariTapped(_ sender: Any) {
        if let u = url {
            UIApplication.shared.open(u, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
