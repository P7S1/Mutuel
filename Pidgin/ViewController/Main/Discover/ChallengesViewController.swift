//
//  ChallengesViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/17/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import  CollectionViewWaterfallLayout
import FirebaseFirestore
class ChallengesViewController: HomeViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var challenges : [Challenge] = [Challenge]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self

        setupUI()
        self.configureNavItem(name: "Challenges")
        
        let layout = CollectionViewWaterfallLayout()
        layout.minimumColumnSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.columnCount = 1
        layout.headerHeight = 34
        layout.headerInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 9)
        collectionView.collectionViewLayout = layout
        
        collectionView.register(SubtitleLabelCollectionReusableView.self, forSupplementaryViewOfKind:  CollectionViewWaterfallElementKindSectionHeader, withReuseIdentifier: "SubtitleLabelCollectionReusableView")
        
        
        
        
        let docRef = db.collection("challenges").whereField("isActive", isEqualTo: true).limit(to: 15)
        
        docRef.getDocuments { (snapshot, error) in
            if error == nil{
                for document in snapshot!.documents{
                    let challenge = Challenge(document: document)
                    self.challenges.append(challenge)
                }
                self.collectionView.reloadData()
            }else{
                print("tehre was an error \(error!.localizedDescription)")
            }
        }
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

extension ChallengesViewController : UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return challenges.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChallengesCollectionViewCell", for: indexPath) as! ChallengesCollectionViewCell
        
        let challenge = challenges[indexPath.row]
        
        cell.title.text = challenge.title
        cell.colorView.backgroundColor = challenge.color
        cell.subtitle.text = challenge.desc
        cell.imageView.kf.setImage(with: challenge.photoURL)
        cell.contentView.layer.cornerRadius = 15
        cell.contentView.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChallengeDayViewController") as! ChallengeDayViewController
        vc.challenge = challenges[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    
    
}

extension ChallengesViewController: CollectionViewWaterfallLayoutDelegate{
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: self.view.frame.height/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SubtitleLabelCollectionReusableView", for: indexPath) as! SubtitleLabelCollectionReusableView
        
    }
    
    
}

