//
//  BackGradientView.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 2/11/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation

class BackGradientView: UIView {
    override open class var layerClass: AnyClass {
       return CAGradientLayer.classForCoder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
    }
}
