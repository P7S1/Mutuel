//
//  FollowersHelper.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/11/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//
import AVFoundation
import Foundation
import FirebaseFirestore
import FirebaseStorage
class FollowersHelper{
    
    func follow(follower : String, followee : String, tokens : [String], completion: @escaping (Bool) -> Void){
        if let user = User.shared.uid{
            if followee != user{
                let batch = db.batch()
            let docRef = db.collection("users")
                docRef.document(user).updateData((["following": FieldValue.arrayUnion([followee])]))
                docRef.document(followee).updateData(["followerCount": FieldValue.increment(Int64(1))])
                batch.commit { (error) in
                    if error == nil{
                    let notify = PushNotificationSender()
                    for token in tokens{
                        notify.sendPushNotification(to: token , title: "", body: "\(User.shared.name ?? "Someone") started following you", tag: nil, badge: nil)
                        }
                        completion(true)
                    }else{
                        completion(false)
                        print("error :\(error!)")
                    }
                }
            }
            
        }
    }
    
    func unFollow(follower : String, followee : String, completion: @escaping (Bool) -> Void){
        if let user = User.shared.uid{
            if followee != user{
                 let batch = db.batch()
                let docRef = db.collection("users")
                docRef.document(followee).updateData(["followerCount": FieldValue.increment(Int64(-1))])
                docRef.document(user).updateData([
                    "following": FieldValue.arrayRemove([followee]),
                ]) { err in
                    if let err = err {
                        completion(false)
                        print("Error updating document: \(err)")
                    } else {
                        completion(true)
                        print("Document successfully updated")
                    }
                }
                batch.commit()
                }
            }
        }
    
    func leaveChat(channel : Channel){
        if let id = channel.id{
        let docRef = db.collection("channels").document(id)
        
        let tokens = Array(Set(channel.tokens).subtracting(User.shared.tokens))
            
        var members = channel.members
            
        let metaData = channel.metaData
            
        metaData?.removeObject(forKey: User.shared.uid ?? "")
            
            if let index = members.firstIndex(of: User.shared.uid ?? ""){
                members.remove(at: index)
            }
        
            docRef.updateData(["fcmToken" : tokens,
                               "members" : members,
                               "metaData": metaData as Any])
            
            ProgressHUD.showSuccess("Left \(channel.name ?? "group")")
    }
        
        
    }
    
    func uploadGroupPicture(data1 : Data?, imageName : String, docID : String){
        print("doing workfor \(docID)")
        guard let data0 = data1
        else{
            ProgressHUD.showError("Error")
            print("error uploading picture")
            return
        }

        let imageRef = Storage.storage().reference().child("profilePics").child(docID).child("\(imageName).jpg")
        imageRef.putData(data0, metadata: nil) { (metaData, error) in
            imageRef.downloadURL { (url, error) in
                guard url != nil else {
                print("error occurred: \(error!)")
                // Uh-oh, an error occurred!
                return
              }
                let docRef = db.collection("channels").document(docID)
                docRef.updateData(["profilePicURLs.\(docID)" : url?.absoluteString as Any])
            }
        }
        }
    
    
     func uploadPicture(data1 : Data?, imageName : String) -> String{
        var output = ""
        guard let data0 = data1
        else{
            ProgressHUD.showError("Error")
            print("error uploading picture")
            return ""
        }

        let imageRef = Storage.storage().reference().child("profilePics").child(User.shared.uid ?? "").child("\(imageName).jpg")
        imageRef.putData(data0, metadata: nil) { (metaData, error) in
            imageRef.downloadURL { (url, error) in
                guard url != nil else {
                print("error occurred: \(error!)")
                // Uh-oh, an error occurred!
                return
              }
                let docRef = db.collection("users").document(User.shared.uid ?? "")
                docRef.updateData(["profilePicURL" : url?.absoluteString as Any])
                output = url?.absoluteString ?? ""
                
                let query = db.collection("channels").whereField("members", arrayContains: User.shared.uid ?? "")
                query.getDocuments { (snapshot, error) in
                    if error == nil{
                        for document in snapshot!.documents{
                            let docRef = db.collection("channels").document(document.documentID)
                            docRef.updateData(["profilePicURLs.\(User.shared.uid ?? "")": url?.absoluteString as Any])
                        }
                    }
                }
            }
        }
        
        
        
        return output
    }

    func getUserProfilePicture() -> UIImage{
        let image = UIImage.init(named: "icons8-male-user-96")
        return (image?.withTintColor(.secondaryLabel).withRenderingMode(.alwaysOriginal))!
    }
    
    func getGroupProfilePicture() -> UIImage{
        let image = UIImage.init(named: "group")
        return (image?.withTintColor(.secondaryLabel).withRenderingMode(.alwaysOriginal))!
    }
    
    func generateThumbnail(path: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: path, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func deleteImage(at url : String){
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: url)

        //Removes image from storage
        storageRef.delete { error in
            if error != nil{
                print("there was an error \(error!.localizedDescription)")
            }
        }
    }
    
    static func deletePost(post : Post){
        let docRef = db.collection("users").document(post.creatorID).collection("posts").document(post.postID)
        docRef.delete(completion: nil)
        FollowersHelper.deleteImage(at: post.photoURL)
        if let url = post.videoURL{
        FollowersHelper.deleteImage(at: url)
        }
    }
    
    func getChannelID(id1 : String, id2 : String) -> String{
        if id1 > id2{
            return id1+id2
        }else{
            return id2+id1
        }
    }
    
    }
    
    
    
    

