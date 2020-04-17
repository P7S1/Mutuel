//
//  EmptyStateAttributes.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/22/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation

class EmptyStateAttributes {
    
    static let shared : EmptyStateAttributes = EmptyStateAttributes()
        
    let title : [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "AvenirNext-Bold", size: 21)!,
            .foregroundColor: UIColor.label
        ]
    
    let subtitle : [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "AvenirNext-Medium", size: 16)!,
        .foregroundColor: UIColor.secondaryLabel
    ]
    
    let button : [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "AvenirNext-Bold", size: 17
            )!,
        .foregroundColor: UIColor.systemPink
    ]
    
    let config = UIImage.SymbolConfiguration(pointSize: 52, weight: .regular)
    
}
