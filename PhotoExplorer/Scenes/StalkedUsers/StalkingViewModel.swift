//
//  StalkingViewModel.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/20/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import RxRealm

class StalkingViewModel: BadgeGeneratorProtocol {
    var badgeNumber: Observable<Int> = PublishSubject<Int>()
    var viewAppears: AnyObserver<Void>!
    
    fileprivate var repo: UsersRepository
    fileprivate var overviewRepo: StalkerOverviewRepository
    fileprivate let syncStore: SyncStore!
    fileprivate let bag = DisposeBag()
    fileprivate var overviewUser: StalkerOverview
    
    var users: Results<StalkedUser>
    
    init(syncStore: SyncStore) {
        repo = UsersRepository()
        self.syncStore = syncStore
        overviewRepo = StalkerOverviewRepository()
        users = repo.userList()
        overviewUser = overviewRepo.overviewUser()
        
        viewAppears = AnyObserver<Void>(eventHandler: {[weak self] (event) in
            if !event.isStopEvent {
                self?.checkUsers(forceUpdate: false)
            }
        })
        checkUsers(forceUpdate: true)
    }

    private func checkUsers(forceUpdate forced: Bool) {
        var shouldUpdate = true
        if let lastSyncDate = overviewUser.lastSyncDate {
            let now = Date()
            if now.timeIntervalSince(lastSyncDate) < 30 {
                shouldUpdate = false
            }
        }
        if forced || shouldUpdate {
            syncStore.refreshUsers().subscribe(onNext: {[weak self] photos in
                (self?.badgeNumber as! PublishSubject<Int>).onNext(photos)
                }).addDisposableTo(bag)
        }
    }

    func usersChanged() -> Observable<RealmChangeset?> {
        return repo.usersChangeset.map({ (results, changeset) -> RealmChangeset? in
            return changeset
        })
    }
    
    func user(index: Int) -> StalkedUser {
        return users[index]
    }
    
    func childViewModel(_ user: StalkedUser) -> UserCollectionViewModeling {
        var vm = AppDelegate.sharedContainer().resolve(UserCollectionViewModeling.self, name: user.service)!
        vm.ownerId = user.userId
        vm.ownerName = user.name
        let remainingNewPhotos = overviewUser.unseenPhotosCount - user.unseenPhotos
        overviewRepo.updateNewPhotosCount(remainingNewPhotos)
        (badgeNumber as! PublishSubject<Int>).onNext(remainingNewPhotos)
        _ = repo.clearNewFlag(user)
        _ = repo.saveUser(user)
        return vm
    }
 
}
