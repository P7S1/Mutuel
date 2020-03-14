//
//  PhotoPickerViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/1/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Photos

protocol PhotoPickerDelegate {
    func didSelectAsset(asset : PHAsset, photoPicker : UIViewController )
}
class PhotoPickerViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var images : [UIImage] = [UIImage]()
    
    var lastIndex = 0
    
    var photoPickerDelegate : PhotoPickerDelegate?
    
    lazy var fetchOptions : PHFetchOptions = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d AND duration < 60", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        return fetchOptions
    }()
    
    lazy var fetchResults: PHFetchResult = {

       return PHAsset.fetchAssets(with: fetchOptions)
        
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
        // Do any additional setup after loading the view.
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResults.count
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        let imageView = cell.viewWithTag(1) as! UIImageView
        
        let imgManager = PHImageManager.default()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        
        let size = (self.collectionView.frame.width/3 - 1)
        
        let fetchObject = fetchResults.object(at: indexPath.row)
        
        let duration = fetchObject.duration
        
        let timeLabel = cell.viewWithTag(2) as! UILabel
        timeLabel.layer.addButtonShadows()
        if fetchObject.mediaType == .video{
        timeLabel.text = duration.stringFromTimeInterval()
        }else{
         timeLabel.text = ""
        }
        
        imgManager.requestImage(for: fetchObject, targetSize: CGSize(width: size, height: size), contentMode: .aspectFill, options: requestOptions) { (image, data) in
            imageView.image = image
        }

        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        photoPickerDelegate?.didSelectAsset(asset: fetchResults.object(at: indexPath.row), photoPicker: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = self.collectionView.frame.width/3 - 1
        
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
