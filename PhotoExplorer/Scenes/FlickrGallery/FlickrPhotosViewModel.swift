//
//  FlickrPhotosViewModel.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/9/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class ExifInfo {
    var photoId: String
    var exif: PhotoExif
    init(photoId: String, exif: PhotoExif) {
        self.photoId = photoId
        self.exif = exif
    }
}

class FlickrPhotosViewModel: PhotoCollectionViewModeling {
    private var internalPhotos = [AbstractPhoto]()
    private var currentPage = Variable<Int>(1)
    private static let pageSize = 20
    private let store: FlickrPhotosStore
    private var photoMap = [String:Int]()
    private var gettingPhotos = Variable<Bool>(false)
    //PhotoCollectionViewModeling properties
    var currentPhotoIndex = Variable<Int>(0)
    var newPhotosIndexes = Variable<[IndexPath]>([])
    
    var photos: [AbstractPhoto] {
        get { return internalPhotos }
    }
    var errorMessage = Variable<String?>(nil)
    var searchTerm = Variable<String>("")
    var photosRetrieved: Observable<Int>!
    //end
    init(store: FlickrPhotosStore) {
        self.store = store
    }
    
    func setup(scrollNearEnd: Observable<Void>) {
        let paramsChanged = searchTerm.asObservable().map {[unowned self] (_) -> Void in
            self.internalPhotos.removeAll()
            self.currentPage.value = 1
            self.photoMap.removeAll()
            self.newPhotosIndexes.value.removeAll()
            return
        }
        
        let combined = Observable.of(
            scrollNearEnd,
            paramsChanged
        ).merge().filter {[unowned self] (_) -> Bool in
            return self.gettingPhotos.value == false
        }
        photosRetrieved = combined.flatMap({[unowned self] (_) -> Observable<Int> in
            self.gettingPhotos.value = true
            let sp = self.searchTerm.value.characters.count > 0 ? self.store.searchPhotos(term: self.searchTerm.value, page: self.currentPage.value, pageSize: FlickrPhotosViewModel.pageSize) : self.store.popularPhotos(page: self.currentPage.value, pageSize: FlickrPhotosViewModel.pageSize)
            let exifs = sp.observeOn(MainScheduler.instance).flatMap({[weak self] photos -> Observable<String> in
                return Observable<String>.create { observer in
                    var idx = self!.internalPhotos.count
                    var indexes: [IndexPath] = []
                    for ph in photos {
                        self?.internalPhotos.append(ph)
                        self?.photoMap[ph.photoId] = idx
                        observer.onNext(ph.photoId)
                        //self?.getExif(ph.photoId)
                        indexes.append(IndexPath(row: idx, section: 0))
                        idx += 1
                    }
                    observer.onCompleted()
                    self?.currentPage.value += 1
                    self?.newPhotosIndexes.value = indexes
                    self?.gettingPhotos.value = false
                    return Disposables.create()
                }
            }).flatMap { (photoId) -> Observable<ExifInfo> in
                return self.store.exifSignal(photoId: photoId).map({ (value) -> ExifInfo in
                    return ExifInfo(photoId: value.1, exif: value.0)
                })
            }
            return exifs.map({[unowned self] (exifInfo) -> Int in
                guard let idx = self.photoMap[exifInfo.photoId] else {
                    return 0
                }
                if idx < self.internalPhotos.count && self.internalPhotos[idx].photoId == exifInfo.photoId {
                    self.internalPhotos[idx].exif = exifInfo.exif
                }
                return 1
            })
        })
    }
   
    func childViewModel(forIndex index: Int) -> LargeImageViewModeling {
        let childVM = AppDelegate.sharedContainer().resolve(LargeFlickrImageViewModel.self)!
        childVM.setPhoto(photo: internalPhotos[index], index: index)
        return childVM
    }
}
