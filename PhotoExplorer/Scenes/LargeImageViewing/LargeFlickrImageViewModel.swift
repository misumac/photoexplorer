//
//  LargeFlickrImageViewModel.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/9/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift

class LargeFlickrImageViewModel: LargeImageViewModeling {
    var photo: AbstractPhoto!
    var index: Int!
    var ownerId: String?
    var image = Variable<UIImage>(UIImage())
    let bag = DisposeBag()
    
    fileprivate let store: FlickrPhotosStore
    private var largeImageRetrieved = false
    
    init(store: FlickrPhotosStore) {
        self.store = store
    }
    
    func setPhoto(photo: AbstractPhoto, index: Int) {
        self.photo = photo
        self.index = index
    }
    
    func downloadImage() -> Observable<Void> {
        return store.downloadImage(source: photo.mediumPhotoSrc, photoId: photo.photoId).observeOn(MainScheduler.instance).map({[weak self] (img, photoId) in
            self?.image.value = img
        })
    }
    
    func userViewModel() -> PhotoCollectionViewModeling {
        let child = AppDelegate.sharedContainer().resolve(FlickrUserPhotosViewModel.self)!
        child.ownerId = photo.ownerId
        child.ownerName = photo.ownerFullName
        return child
    }
    
    func imageZoomed(trigger: Observable<Void>) -> Observable<Void> {
        return trigger.flatMap({[weak self] (_) -> Observable<Void> in
            if self == nil {
                return Observable<Void>.just()
            }
            if !self!.largeImageRetrieved {
                self!.largeImageRetrieved = true
                return self!.store.downloadImage(source: self!.photo.bigPhotoSrc, photoId: self!.photo.photoId)
                    .observeOn(MainScheduler.instance).flatMap({[weak self] (img, photoId) -> Observable<Void> in
                        self?.image.value = img
                        return Observable<Void>.just()
                    })
            } else {
                return Observable<Void>.just()
            }
        })
    }
}
