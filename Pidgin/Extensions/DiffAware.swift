//
//  DiffAware.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/26/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import DeepDiff
extension DiffAware where Self: Hashable {
    public var diffId: Int {
        return hashValue
    }

    public static func compareContent(_ a: Self, _ b: Self) -> Bool {
        return a == b
    }
}

extension UUID: DiffAware {}
extension CGFloat: DiffAware {}


extension AnyHashable : DiffAware{
    
}
