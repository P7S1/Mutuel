//
//  SearchCollectionViewCell.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/10/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import SvrfSDK
class SearchCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func setupWith(media: SvrfMedia) {
        
        imageView.layer.addButtonShadows()
      imageView.image = nil

      guard let previewImage = media.files?.images?._720x720,
        let imageUrl = URL(string: previewImage) else {

        print("Could not fetch 720x720 image")
        return
      }

      URLSession.shared.dataTask(with: imageUrl,
        completionHandler: { (data, _, error) in
          if error != nil {
            print("Could not fetch image: \(error!)")
            return
          }

          DispatchQueue.main.async {
            if let data = data, let remoteImage = UIImage(data: data) {
              self.imageView.image = remoteImage
            }
        }
      }).resume()
    }
}
