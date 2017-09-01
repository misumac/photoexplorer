//
//  FlickrUserPhotosViewModel.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/10/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift

class FlickrUserPhotosViewModel: PhotoCollectionViewModeling, UserCollectionViewModeling {
    fileprivate var internalPhotos = [AbstractPhoto]()
    fileprivate var currentPage = Variable<Int>(1)
    fileprivate static let pageSize = 20
    fileprivate let store: FlickrPhotosStore
    fileprivate let repo: UsersRepository
    //PhotoCollectionViewModeling properties
    var currentPhotoIndex = Variable<Int>(0)
    var newPhotosIndexes = Variable<[IndexPath]>([])
    var gettingPhotos = Variable<Bool>(false)
    var photos: [AbstractPhoto] {
        get { return internalPhotos }
    }
    var errorMessage = Variable<String?>(nil)
    
    var ownerId: String {
        didSet {
            if ownerId.characters.count > 0 {
                userIsBookmarked.value = repo.isUserSaved(ownerId)
            }
        }
    }
    var ownerName: String
    var userIsBookmarked = Variable<Bool>(false)
    var photosRetrieved: Observable<Int>!
    
    init(store: FlickrPhotosStore) {
        self.store = store
        self.ownerId = ""
        self.ownerName = ""
        self.repo = UsersRepository()
    }
    
    func setup(scrollNearEnd: Observable<Void>) {
        photosRetrieved = scrollNearEnd.filter({[weak self] (_) -> Bool in
            return self?.gettingPhotos.value == false
        }).flatMap({[weak self] (_) -> Observable<Int> in
            if self == nil {
                return Observable<Int>.just(0)
            }
            self!.gettingPhotos.value = true
            return self!.store.userPhotos(userId: self!.ownerId, page: self!.currentPage.value, pageSize: FlickrUserPhotosViewModel.pageSize).observeOn(MainScheduler.instance).map({[weak self] (photos) -> Int in
                if self == nil {
                    return 0
                }
                var idx = self!.internalPhotos.count
                var indexes: [IndexPath] = []
                for ph in photos {
                    self?.internalPhotos.append(ph)
                    indexes.append(IndexPath(row: idx, section: 0))
                    idx += 1
                }
                self?.currentPage.value += 1
                self?.newPhotosIndexes.value = indexes
                self?.gettingPhotos.value = false
                return photos.count
            })
        })
    }
    
    func bindBookmarkAction(bookmarkAction: Observable<Void>) -> Observable<Bool> {
        return bookmarkAction.flatMap({[weak self] (_) -> Observable<Bool> in
            if let me = self {
                if me.userIsBookmarked.value == false {
                    return me.store.userDetails(userId: me.ownerId).observeOn(MainScheduler.instance).map { user -> Bool in
                        let stalkedUser = StalkedUser(aUser: user)
                        stalkedUser.service = "flickr"
                        let repo = UsersRepository()
                        let result = repo.saveUser(stalkedUser)
                        self?.userIsBookmarked.value = result
                        return result
                    }
                } else {
                    if me.repo.deleteUser(me.ownerId) {
                        me.userIsBookmarked.value = false
                    }
                    return Observable<Bool>.just(true)
                
                }
            } else {
                    return Observable<Bool>.just(false)
            }
        })
    }
  
    func childViewModel(forIndex index: Int) -> LargeImageViewModeling {
        let childVM = AppDelegate.sharedContainer().resolve(LargeFlickrImageViewModel.self)!
        childVM.ownerId = ownerId
        childVM.setPhoto(photo: internalPhotos[index], index: index)
        return childVM
    }
}
