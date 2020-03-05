//
//  TimeInterval.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/3/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation

extension TimeInterval{

    func stringFromTimeInterval() -> String {

        let time = NSInteger(self)
        
        let seconds = time % 60
        let minutes = (time / 60) % 60

        return String(format: "%0.2d:%0.2d",minutes,seconds)

    }
}
