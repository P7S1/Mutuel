//
//  CategoryItem.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/20/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation


struct CategoryItem {
    var displayName : String
    var color : UIColor
    var url : URL?
    var id : String
    
    init(displayName : String, color: UIColor, urlString: String, id: String) {
        self.displayName = displayName
        self.color  = color
        self.url = URL(string: urlString)
        self.id = id
    }
    
    static func getCategoryArray() -> [CategoryItem]{
        var output : [CategoryItem] = [CategoryItem]()
        
        output.append(CategoryItem(displayName: "Funny", color: .systemIndigo, urlString: "https://media.giphy.com/media/ZqlvCTNHpqrio/giphy.gif", id: "funny"))
        
        output.append(CategoryItem(displayName: "Music", color: .systemGreen, urlString: "https://media.giphy.com/media/3oxHQERYBueKZdAb9m/giphy.gif", id: "music"))
        
        output.append(CategoryItem(displayName: "News", color: .systemBlue, urlString: "https://media.giphy.com/media/xUNemVaUZFSgHxvQXK/giphy.gif", id: "news"))
        
        output.append(CategoryItem(displayName: "Sports", color: .systemOrange, urlString: "https://media.giphy.com/media/k481R5ERN7jJm/giphy.gif", id: "sports"))
        
        output.append(CategoryItem(displayName: "Food", color: .systemRed, urlString: "https://media.giphy.com/media/EDV30lQQ9VW5q/giphy.gif", id: "food"))
        
        output.append(CategoryItem(displayName: "TV/Movies", color: .systemPurple, urlString: "https://media.giphy.com/media/jpQkuoHi7JZY14yIZf/giphy.gif", id: "tv_movies"))
        
        output.append(CategoryItem(displayName: "Edits", color: .sunFlower, urlString: "https://media.giphy.com/media/3o7qE8wyh4RkaoaZDG/giphy.gif", id: "edits"))
        
        output.append(CategoryItem(displayName: "Animals/Nature", color: .nephritis, urlString: "https://media.giphy.com/media/kreQ1pqlSzftm/giphy.gif", id: "animals_nature"))
        
        output.append(CategoryItem(displayName: "Gaming", color: .belizeHole, urlString: "https://media.giphy.com/media/3og0IzoPfRVwyxjDUs/giphy.gif", id: "gaming"))
        
        output.append(CategoryItem(displayName: "Fashion/Design", color: .alizarin, urlString: "https://media.giphy.com/media/QCDgYrgrfggee4MDPD/giphy.gif", id: "fashion_design"))
        
        output.append(CategoryItem(displayName: "Dance", color: .systemTeal, urlString: "https://media.giphy.com/media/3o6ZtgnmZDZeAshxYY/giphy.gif", id: "dance"))
        
        output.append(CategoryItem(displayName: "DIY/Hacks", color: .pumpkin, urlString: "https://media.giphy.com/media/3oKIPqsXYcdjcBcXL2/giphy.gif", id: "diy_hacks"))
    
        
        
        
        return output
    }
}
