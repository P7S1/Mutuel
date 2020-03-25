//
//  UINavigationController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/23/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
extension UINavigationController {

  public func pushViewController(viewController: UIViewController,
                                 animated: Bool,
                                 completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    pushViewController(viewController, animated: animated)
    CATransaction.commit()
  }

}
