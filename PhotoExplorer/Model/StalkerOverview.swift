//
//  StalkerOverview.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/25/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RealmSwift

class StalkerOverview: Object {
    dynamic var unseenPhotosCount: Int = 0
    dynamic var lastSyncDate: Date?
    dynamic var id = 1
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
