//
//  UIView.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 2/14/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation

extension UIView {

    // MARK: Activity Indicator

    func activityIndicator(show: Bool) {
        activityIndicator(show: show, style: .large)
    }

    func activityIndicator(show: Bool, style: UIActivityIndicatorView.Style) {
        var spinner: UIActivityIndicatorView? = viewWithTag(NSIntegerMax - 1) as? UIActivityIndicatorView

        if spinner != nil {
            spinner?.removeFromSuperview()
            spinner = nil
        }

        if spinner == nil && show {
            spinner = UIActivityIndicatorView.init(style: style)
            spinner?.translatesAutoresizingMaskIntoConstraints = false
            spinner?.hidesWhenStopped = true
            spinner?.tag = NSIntegerMax - 1

            if Thread.isMainThread {
                spinner?.startAnimating()
            } else {
                DispatchQueue.main.async {
                    spinner?.startAnimating()
                }
            }

            insertSubview((spinner)!, at: 0)

            NSLayoutConstraint.init(item: spinner!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint.init(item: spinner!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0).isActive = true

            spinner?.isHidden = !show
        }
    }

}
