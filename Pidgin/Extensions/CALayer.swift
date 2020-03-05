//
//  CALayer.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/4/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation

extension CALayer{
    func addButtonShadows(){
        shadowColor = UIColor.black.cgColor
        shadowOpacity = 0.5
        shadowRadius = 2
        shadowOffset = CGSize(width: 3, height: 3)
    }
}
