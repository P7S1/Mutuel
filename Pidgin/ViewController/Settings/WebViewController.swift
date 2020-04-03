//
//  WebViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/24/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import WebKit
class WebViewController: UIViewController, WKUIDelegate {
    
    var webView: WKWebView!
    
    var url : URL?
    
    var navTitle = ""
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        

        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        self.navigationItem.title = navTitle
        
        if let myURL = url{
        let myRequest = URLRequest(url: myURL)
        webView.load(myRequest)
        }
    }}
