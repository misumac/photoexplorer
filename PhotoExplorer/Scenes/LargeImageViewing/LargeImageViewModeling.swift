//
//  LargeImageViewModeling.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/5/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift

protocol LargeImageViewModeling {
    var photo: AbstractPhoto! {get set}
    var index: Int! {get set}
    var ownerId: String? {get set}
    var image: Variable<UIImage> {get}
    
    func userViewModel() -> PhotoCollectionViewModeling
    func downloadImage() -> Observable<Void>
    func imageZoomed(trigger: Observable<Void>) -> Observable<Void>
}
