//
//  CategoriesViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/21/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
class CategoriesViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        // Do any additional setup after loading the view.
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

extension CategoriesViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  CategoryItem.getCategoryArray().count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryVCCell", for: indexPath)
        
        let button = cell.viewWithTag(1) as! UIButton
        
        if indexPath.row > 0{
            let index = indexPath.row-1
            let item = CategoryItem.getCategoryArray()[index]
            button.setTitle(item.displayName, for: .normal)
            if item.color == UIColor.black{
            button.setTitleColor(.label, for: .normal)
            }else{
            button.setTitleColor(item.color, for: .normal)
            }
        }else{
            button.setTitle("Latest", for: .normal)
            button.setTitleColor(.label, for: .normal)
        }
        button.roundCorners()
        button.isEnabled = false
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "ExploreViewController") as! ExploreViewController
        
        vc.shouldquery = false
        
        if indexPath.row > 0{
            let index = indexPath.row-1
            let item = CategoryItem.getCategoryArray()[index]
            vc.query = db.collectionGroup("posts").whereField("isRepost", isEqualTo: false).whereField("isPrivate", isEqualTo: false).whereField("tags", arrayContainsAny: [item.id]).whereField("isExplicit", isEqualTo: false).order(by: "score", descending: true).limit(to: 20)
            vc.navigationItem.title = item.displayName
        }else{
            vc.navigationItem.title = "Latest"
            vc.query = db.collectionGroup("posts").whereField("isRepost", isEqualTo: false).whereField("isPrivate", isEqualTo: false).order(by: "publishDate", descending: true).limit(to: 20)
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}
