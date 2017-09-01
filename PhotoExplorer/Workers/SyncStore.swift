//
//  SyncStore.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/22/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift

class SyncStore {
    fileprivate var active = false
    
    init() {
    }
    
    func refreshUsers() -> Observable<Int> {
        if active {
            return Observable<Int>.empty()
        }
        active = true
        
        let repo = UsersRepository()
        let users = repo.userList()
        var reusableClients = [String:UserNetworking]()
        var usersRequests = [Observable<AbstractUser>]()
        
        for user in users {
            var client = reusableClients[user.service]
            if client == nil {
                client = AppDelegate.sharedContainer().resolve(UserNetworking.self, name: user.service)!
                reusableClients[user.service] = client
            }
            usersRequests.append(client!.userDetails(userId: user.userId))
        }
        return Observable.from(usersRequests).merge().toArray().map({[reusableClients, usersRequests] newUsers -> Int in
            var updatedUsers = [StalkedUser]()
            let _ = reusableClients
            var newPhotos = 0
            let repo = UsersRepository()
            for aUser in newUsers {
                if let user = repo.getUser(userId: aUser.userId) {
                    let newUser = StalkedUser(aUser: aUser)
                    newUser.unseenPhotos = user.unseenPhotos + aUser.photosCount - user.photo_count
                    newUser.service = user.service
                    newPhotos = newPhotos + newUser.unseenPhotos
                    updatedUsers.append(newUser)
                }
            }
            
            repo.updateUsers(updatedUsers)
            let overviewRepo = StalkerOverviewRepository()
            overviewRepo.updateNewPhotosCount(newPhotos)
            return newPhotos
        })
    }
}
