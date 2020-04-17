//
//  SubtitleLabelCollectionReusableView.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/27/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class SubtitleLabelCollectionReusableView: UICollectionReusableView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.myCustomInit()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.myCustomInit()
    }

    func myCustomInit() {
        let label = UILabel(frame: self.frame)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        let text = formatter.string(from: Date())
        label.font = UIFont(name: "AvenirNext-Bold", size: 21
        )!
        label.textColor = .secondaryLabel
        label.text = text
        
        self.addSubview(label)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let horizontalConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 16)
        let leadingConstraint = label.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        
        NSLayoutConstraint.activate([horizontalConstraint,
                                    verticalConstraint,
                                    leadingConstraint])
    }

}
