//
//  StalkerOverviewRepository.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/25/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import RxRealm

class StalkerOverviewRepository {
    var usersChanged: Observable<Int>!
    
    fileprivate var realm: Realm
    
    init() {
        realm = try! Realm()
        self.usersChanged = Observable.collection(from: realm.objects(StalkedUser.self)).map({users in users.count})
    }
    
    func overviewUser() -> StalkerOverview {
        let result = realm.objects(StalkerOverview.self)
        if result.count == 1 {
            return result[0]
        } else {
            return StalkerOverview()
        }
    }
    
    func updateNewPhotosCount(_ newCount: Int) {
        let obj = StalkerOverview()
        obj.unseenPhotosCount = newCount
        obj.lastSyncDate = Date(timeIntervalSinceNow: 0)
        try! realm.write({ 
            realm.add(obj, update: true)
        })
    }
    
}
