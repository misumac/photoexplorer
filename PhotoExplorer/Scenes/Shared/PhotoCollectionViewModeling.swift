//
//  PhotoCollectionViewModeling.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/5/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift

protocol PhotoCollectionViewModeling {
    //Output
    var currentPhotoIndex: Variable<Int> {get set}
    var newPhotosIndexes: Variable<[IndexPath]> {get set}
    var errorMessage: Variable<String?> {get set}
    var photos: [AbstractPhoto] {get}
    var photosRetrieved: Observable<Int>! {get set}
    //Input
    func setup(scrollNearEnd:Observable<Void>)
    //Methods
    func childViewModel(forIndex index:Int) -> LargeImageViewModeling
}

protocol UserCollectionViewModeling {
    var ownerId: String {get set}
    var ownerName: String {get set}
    var userIsBookmarked: Variable<Bool> {get set}
    func bindBookmarkAction(bookmarkAction: Observable<Void>) -> Observable<Bool>
}
