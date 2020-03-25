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
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
    
    let subtitle : [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15, weight: .regular),
        .foregroundColor: UIColor.secondaryLabel
    ]
    
    let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
    
}
