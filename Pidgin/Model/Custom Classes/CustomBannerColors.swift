//
//  CustomBannerColors.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 2/11/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import NotificationBannerSwift
class CustomBannerColors: BannerColorsProtocol {

    internal func color(for style: BannerStyle) -> UIColor {
        switch style {
            case .info:        // Your custom .info color
               return .systemPink
            default:
            return .systemPink
        }
    }

}
