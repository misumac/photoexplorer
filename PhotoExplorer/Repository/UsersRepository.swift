//
//  UsersRepository.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/19/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm

class UsersRepository {
    var realm: Realm!
    let usersChangeset:  Observable<(AnyRealmCollection<StalkedUser>, RealmChangeset?)>!
    
    init() {
        realm = try! Realm()
        usersChangeset = Observable.changeset(from: realm.objects(StalkedUser.self))
    }
    
    func clearNewFlag(_ user: StalkedUser) -> Bool {
        do {
            try realm.write({ 
                user.unseenPhotos = 0
            })
        } catch {
            return false
        }
        return true
    }
    
    func saveUser(_ user: StalkedUser) -> Bool {
        do {
            try realm.write { () in
                realm.add(user, update: true)
            }
        } catch {
            return false
        }
        return true
    }
    
    func getUser(userId: String) -> StalkedUser? {
        let predicate = NSPredicate(format:"userId = %@", userId)
        let users = realm.objects(StalkedUser.self).filter(predicate)
        if users.count > 0 {
            return users[0]
        } else {
            return nil
        }
    }
    
    func userList() -> Results<StalkedUser> {
        return realm.objects(StalkedUser.self)
    }
    
    func updateUsers(_ users: [StalkedUser]) {
        do {
            realm.beginWrite()
            for user in users {
                realm.add(user, update: true)
            }
            try realm.commitWrite()
        } catch {
            
        }
    }

    func isUserSaved(_ userId: String) -> Bool {
        let predicate = NSPredicate(format:"userId = %@", userId)
        let users = realm.objects(StalkedUser.self).filter(predicate)
        if users.count > 0 {
            return true
        }
        return false
    }
    
    func deleteUser(_ userId: String) -> Bool {
        do {
            let predicate = NSPredicate(format:"userId = %@", userId)
            let users = realm.objects(StalkedUser.self).filter(predicate)
            try realm.write {
                realm.delete(users)
            }
        } catch {
                return false
        }
        return true
    }
}
