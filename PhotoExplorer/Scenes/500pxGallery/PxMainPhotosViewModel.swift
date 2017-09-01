//
//  PxMainPhotosViewModel.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/2/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class PxMainPhotosViewModel: PhotoCollectionViewModeling, CategoryControllerDelegate {
    fileprivate var internalPhotos = [AbstractPhoto]()
    fileprivate let pxStore: PxStore
    private var gettingPhotos = Variable<Bool>(false)
    //PhotoCollectionViewModeling properties
    var currentPhotoIndex = Variable<Int>(0)
    var newPhotosIndexes = Variable<[IndexPath]>([])
    var photos: [AbstractPhoto] {
        get { return internalPhotos }
    }
    var errorMessage = Variable<String?>(nil)
    //end
    //Inputs
    var searchTerm = Variable<String>("")
    var selectedFeature = Variable<PxFeature>(.Popular)
    var selectedCategoryVariable = Variable<PxCategory>(.all)
    var currentPage = Variable<Int>(1)
    //Outputs
    var photosRetrieved: Observable<Int>!
    
    var clearCommand: AnyObserver<Void> {
        return AnyObserver<Void> { _ in
            self.searchTerm.value = ""
        }
    }

    var selectedCategory: PxCategory {
        get { return selectedCategoryVariable.value }
        set { selectedCategoryVariable.value = newValue }
    }
    
    init(pxStore: PxStore) {
        self.pxStore = pxStore
    }
    
    func setup(scrollNearEnd:Observable<Void>)  {
        let photoIndexNearEnd = currentPhotoIndex.asObservable().map {[unowned self] (index) -> Bool in
            if self.internalPhotos.count > 0 {
                if index > self.internalPhotos.count - 5 {
                    return true
                }
            }
            return false
        }
        let paramsChanged = Observable.of(
            selectedFeature.asObservable().map{ (_) -> Bool in return true },
            selectedCategoryVariable.asObservable().map{ (_) -> Bool in return true },
            searchTerm.asObservable().map{ (_) -> Bool in return true }
        ).merge().map {[unowned self] (_) -> Bool in
            self.errorMessage.value = nil
            self.internalPhotos.removeAll()
            self.currentPage.value = 1
            self.newPhotosIndexes.value = []
            return true
        }
        let combined = Observable.of(scrollNearEnd.map({ (_) -> Bool in
            return true
        }), photoIndexNearEnd, paramsChanged).merge()
        photosRetrieved = combined.filter({[unowned self] (doRetrieve) -> Bool in
            return doRetrieve && self.gettingPhotos.value == false
        }).flatMap({[unowned self] (doRetrieve) -> Observable<Int> in
            self.gettingPhotos.value = true
                let sp = (self.searchTerm.value.characters.count > 0) ? self.pxStore.searchPhotos(feature: self.selectedFeature.value, category: self.selectedCategory, term: self.searchTerm.value, page: self.currentPage.value) : self.pxStore.getPhotos(feature: self.selectedFeature.value, category: self.selectedCategory, page: self.currentPage.value)
                return sp.observeOn(MainScheduler.instance).map({[weak self] (photos) -> Int in
                    var idx =  self!.internalPhotos.count
                    var indexes: [IndexPath] = []
                    for photo in photos {
                        self?.internalPhotos.append(photo)
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
    
    func childViewModel(forIndex index: Int) -> LargeImageViewModeling {
        let chilVM = AppDelegate.sharedContainer().resolve(LargePxImageViewModel.self)!
        chilVM.setPhoto(photo: internalPhotos[index], index: index)
        return chilVM
    }
}
