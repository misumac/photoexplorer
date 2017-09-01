//
//  StalkedUser.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/19/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RealmSwift

class StalkedUser: Object {
    dynamic var name = ""
    dynamic var service = ""
    dynamic var userId = ""
    dynamic var unseenPhotos = 0
    dynamic var userAvatar: Data? = nil
    dynamic var photo_count = 0
    
    convenience required init(aUser: AbstractUser) {
        self.init()
        self.userId = aUser.userId
        self.name = aUser.userName
        self.unseenPhotos = 0
        self.photo_count = aUser.photosCount
        self.userAvatar = aUser.avatar as Data
    }
    
    override static func primaryKey() -> String? {
        return "userId"
    }
    
}
