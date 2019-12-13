//
//  WebViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/24/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {
    
    var index = 0
    
    let webView    = UIWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
         webView.frame  = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
         webView.loadRequest(NSURLRequest(url: NSURL(string: "https://www.google.com")! as URL) as URLRequest)
         webView.delegate = self
         self.view.addSubview(webView)

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ProgressHUD.dismiss()
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        ProgressHUD.show("Loading")
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        ProgressHUD.dismiss()
    }
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        ProgressHUD.showError("Load failed")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
