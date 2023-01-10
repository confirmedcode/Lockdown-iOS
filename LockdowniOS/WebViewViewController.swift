//
//  WebViewViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import WebKit
import UIKit

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewDidDisappear()
}

final class WebViewViewController: BaseViewController {
    
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var titleLabel: UILabel!
    
    weak var delegate: WebViewViewControllerDelegate?
    
    var url: URL?
    var titleLabelText: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url {
            webView.load(URLRequest(url: url))
        }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        titleLabel.text = titleLabelText
    }
    
    @IBAction private func safariTapped(_ sender: Any) {
        if let url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction private func dismiss() {
        dismiss(animated: true) {
            self.delegate?.webViewDidDisappear()
        }
    }
}

extension WebViewViewController: WKNavigationDelegate, Loadable {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showLoadingView()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideLoadingView()
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
              let scheme = url.scheme else {
            decisionHandler(.cancel)
            return
        }
        
        if scheme.lowercased() == "mailto" {
            let email = url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
            
            if let pageUrl = self.url, let urlComponents = URLComponents(url: pageUrl, resolvingAgainstBaseURL: false) {
                if urlComponents.path == "/faq" {
                    composeEmail(.blockingImprovementIdeas, to: email)
                } else if urlComponents.path == "/privacy" {
                    composeEmail(.termsAndPrivacyPolicy, to: email)
                } else {
                    composeEmail(.custom(subject: "", body: ""), to: email)
                }
            }
            
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}

extension WebViewViewController: WKUIDelegate, EmailComposable {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        guard navigationAction.targetFrame == nil || navigationAction.targetFrame?.isMainFrame == false else { return nil }
        guard let urlToLoad = navigationAction.request.url else { return nil }
        
        webView.load(URLRequest(url: urlToLoad))
        
        return nil
    }
}
