//
//  AbstractPhoto.swift
//  PhotoExplorer
//
//  Created by Mihai on 2/8/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation

class AbstractPhoto {
    var photoId: String = ""
    var ownerId: String = ""
    var title: String = ""
    var ownerFullName: String = ""
    var bigPhotoSrc: String = ""
    var mediumPhotoSrc: String = ""
    var smallPhotoSrc: String = ""
    var exif: PhotoExif?
    var largeWidth: Int = 0
    var largeHeight: Int = 0
    var thumbHeight: Int = 0
    var thumbWidth: Int = 0
}
