//
//  PxUserPhotosViewModel.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/6/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift

class PxUserPhotosViewModel: PhotoCollectionViewModeling, UserCollectionViewModeling {
    //PhotoCollectionViewModeling properties
    var currentPhotoIndex = Variable<Int>(0)
    var photos: [AbstractPhoto] {
        return internalPhotos
    }
    var ownerId: String {
        didSet {
            if ownerId.characters.count > 0 {
                userIsBookmarked.value = repo.isUserSaved(ownerId)
            }
        }
    }
    var ownerName: String
    var userIsBookmarked = Variable<Bool>(false)
    var newPhotosIndexes = Variable<[IndexPath]>([])
    
    var currentPage = Variable<Int>(1)
    var gettingPhotos = Variable<Bool>(false)
    var errorMessage = Variable<String?>(nil)
    var photosRetrieved: Observable<Int>!
    
    //end
    fileprivate var internalPhotos: [AbstractPhoto] = []
    fileprivate var pxStore: PxStore!
    fileprivate var endOfStream = false
    fileprivate let repo = UsersRepository()
    
    init(pxStore: PxStore) {
        self.pxStore = pxStore
        self.ownerId = ""
        self.ownerName = ""
    }
    
    func setup(scrollNearEnd: Observable<Void>) {
        let loadMorePhotos = currentPhotoIndex.asObservable().map {[weak self] (value) -> Bool in
            if self != nil && self!.internalPhotos.count > 0 && value > self!.internalPhotos.count - 5 {
                return true
            }
            return false
        }
        let combined = Observable.of(
            scrollNearEnd.map { (_) -> Bool in return true },
            loadMorePhotos
        ).merge().filter {[weak self] (value) -> Bool in
            return value && self?.gettingPhotos.value == false
        }
        photosRetrieved = combined.flatMap({[weak self] (_) -> Observable<Int> in
            guard let strongself = self else {
                return Observable<Int>.just(0)
            }
            strongself.gettingPhotos.value = true
            return strongself.pxStore.userPhotos(ownerId: strongself.ownerId, page: strongself.currentPage.value).observeOn(MainScheduler.instance).map({[weak self] (photos) -> Int in
                if let me = self {
                    var idx = me.internalPhotos.count
                    var indexes = [IndexPath]()
                    if photos.count == 0 {
                        me.endOfStream = true
                        me.gettingPhotos.value = false
                    } else {
                        for photo in photos {
                            me.internalPhotos.append(photo)
                            indexes.append(IndexPath(row: idx, section: 0))
                            idx += 1
                        }
                        me.currentPage.value += 1
                        me.newPhotosIndexes.value = indexes
                        me.gettingPhotos.value = false
                    }
                }
                return 1
            })
        })
    }
    
    func childViewModel(forIndex index:Int) -> LargeImageViewModeling {
        let childVM = AppDelegate.sharedContainer().resolve(LargePxImageViewModel.self)!
        childVM.ownerId = ownerId
        childVM.setPhoto(photo: internalPhotos[index], index: index)
        return childVM
    }
    
    func bindBookmarkAction(bookmarkAction: Observable<Void>) -> Observable<Bool> {
        return bookmarkAction.flatMap({[weak self] (_) -> Observable<Bool> in
            if self == nil {
                return Observable<Bool>.just(false)
            }
            if self!.userIsBookmarked.value == true {
                if self!.repo.deleteUser(self!.ownerId) {
                    self!.userIsBookmarked.value = false
                    return Observable<Bool>.just(true)
                } else {
                    return Observable<Bool>.error(PEError.dbError)
                }
            }
            
            return self!.pxStore.userDetails(userId: self!.ownerId).observeOn(MainScheduler.instance).map {[weak self] user -> Bool in
                let stalkedUser = StalkedUser(aUser: user)
                stalkedUser.service = "500px"
                let repo = UsersRepository()
                let result = repo.saveUser(stalkedUser)
                self?.userIsBookmarked.value = result
                return result
            }
        })
    }
}
