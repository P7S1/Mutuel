//
//  GiphyViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/3/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import GiphyCoreSDK
import SkeletonView
import CollectionViewWaterfallLayout
import DeepDiff
import Kingfisher
import SwiftyGif
protocol GifDelegate {
    func didSelectItem(gif : GPHMedia, vc : GifViewController)
}

class GifViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CollectionViewWaterfallLayoutDelegate, UISearchBarDelegate {

    
    let cache = NSCache<NSString, NSURL>()

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    let g = GiphyHelper(apiKey: "jqEwvwCYxQjIehwIZpHnLKns5NMG0rd8")
    
    var gifs : [GiphyHelper.Gif] = [GiphyHelper.Gif]()
    
    var gifDeleagte : GifDelegate?
    
    var offset : UInt?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        searchBar.delegate = self
        
        getGifs(removeAll: false)
        
        setUpCollectionView()
        
        searchBar.addDoneButtonOnKeyboard()
        
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        navigationItem.title = "Select GIF"
        
        
        // Do any additional setup after loading the view.
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        offset = nil
        getGifs(removeAll: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        offset = nil
        getGifs(removeAll: true)
    }
    
    func getGifs(removeAll : Bool){
        if searchBar.text?.isEmpty ?? true{
        g.trending(20, offset: offset, rating: nil) { gifs, pagination, err in
            if let array = gifs{
                
                self.offset = (self.offset ?? 0) + UInt((pagination?.count ?? 0))
                self.reload(updates: array, removeAll: removeAll)
  
            }
            if let error = err{
                print(error.localizedDescription)
            }
        }
        }else{
            
        g.search(searchBar.text!, limit: 20, offset: offset, rating: nil) { (gifs, pagination, err) in
                if let array = gifs{
                              
                    self.offset = (self.offset ?? 0) + UInt((pagination?.count ?? 0))
                    self.reload(updates: array, removeAll: removeAll)
                
                }
                if let error = err{
                              print(error.localizedDescription)
                          }
            }
            
        }
    }
    
    func reload(updates : [GiphyHelper.Gif], removeAll : Bool){
        
        let old = self.gifs
        var new = self.gifs
        if removeAll{
            new.removeAll()
        }
        new.append(contentsOf: updates)
    
        let changes = diff(old: old, new: new)
        DispatchQueue.main.async {
            self.collectionView.reload(changes: changes, section: 0, updateData: {
                self.gifs = new
            })
        }
    }
    
    func setUpCollectionView(){
        let layout = CollectionViewWaterfallLayout()
        
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 32, right: 0)
        
        layout.minimumColumnSpacing = 4
        layout.minimumInteritemSpacing = 4
        
        collectionView.collectionViewLayout = layout
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifs.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "giphyCell", for: indexPath)
        let imageView = cell.viewWithTag(1) as! UIImageView
        imageView.delegate = self
        let gif = gifs[indexPath.row]
        
        let id = gif.id
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.isSkeletonable = true
        
        let gradient = SkeletonGradient(baseColor: UIColor.secondarySystemBackground)
        imageView.showAnimatedGradientSkeleton(usingGradient: gradient)
        
        /*let data = gif.gifMetadataForType(.Original, still: false)
        
        imageView.kf.setImage(with: data.URL) { (result) in
            imageView.stopSkeletonAnimation()
            imageView.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
        } */
        
        if let nsUrl = cache.object(forKey: id as NSString), let url = nsUrl.absoluteURL {
            // use the cached version
            DispatchQueue.main.async {
              imageView.setGifFromURL(url)
            }
        }
         else {
           /* let data = gif.gifMetadataForType(.FixedWidth, still: false)
            let url = data.URL
            
            self.cache.setObject(url as NSURL, forKey: id as NSString)
            
            imageView.kf.setImage(with: url) { (result) in
                imageView.stopSkeletonAnimation()
                imageView.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
            } */
            
            DispatchQueue.global().async {
                GiphyCore.shared.gifByID(id) { (response, error) in
                    if let media = response?.data {
                        if let gifURL = media.url(rendition: .fixedWidth, fileType: .gif),
                            let url = URL(string: gifURL){
                                DispatchQueue.main.async {

                                    imageView.setGifFromURL(url) 
                                }
                            
                    }
                    }
                }
            }
            
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gif = gifs[indexPath.row]
        let id = gif.id
        GiphyCore.shared.gifByID(id) { (respone, error) in
            if let media = respone?.data{
            DispatchQueue.main.async {
                self.gifDeleagte?.didSelectItem(gif: media, vc: self)
            }
            } 
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if indexPath.row + 1 == gifs.count{
            getGifs(removeAll: false)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let gif = gifs[indexPath.row]
        let data = gif.gifMetadataForType(.FixedWidthDownsampled, still: true)
        
        return CGSize(width: data.width, height: data.height)
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

extension GifViewController : SwiftyGifDelegate {

    func gifURLDidFinish(sender: UIImageView) {
        sender.stopSkeletonAnimation()
        sender.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
    }

    func gifURLDidFail(sender: UIImageView) {
        
    }

    func gifDidStart(sender: UIImageView) {
       
    }
    
    func gifDidLoop(sender: UIImageView) {
        
    }
    
    func gifDidStop(sender: UIImageView) {
       
    }
}
