//
//  HeroAutolayoutFixPlugin.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/15/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import Hero


extension HeroModifier {
    static var autolayout: HeroModifier {
        return HeroModifier { targetState in
            targetState[HeroAutolayoutFixPlugin.modifier] = true
        }
    }
}

class HeroAutolayoutFixPlugin: HeroPlugin {
    static let modifier = "turnOnTranslatedAutoresizingMaskWhileAnimation"
    
    override func process(fromViews: [UIView], toViews: [UIView]) {
        let modifier = type(of: self).modifier
        
        fromViews
            .filter { context[$0]?[modifier] as? Bool == true }
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = true }
        
        toViews
            .filter { context[$0]?[modifier] as? Bool == true }
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = true }
    }
    
    override func clean() {
        let modifier = type(of: self).modifier
        
        context.fromViews
            .filter { context[$0]?[modifier] as? Bool == false }
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        context.toViews
            .filter { context[$0]?[modifier] as? Bool == false }
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    }
}
