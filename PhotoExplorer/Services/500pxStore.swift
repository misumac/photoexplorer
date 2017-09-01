//
//  500pxStore.swift
//  PhotoExplorer
//
//  Created by Mihai on 2/7/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON

enum PxFeature: String {
    case Popular = "popular"
    case Editors = "editors"
    case Upcoming = "upcoming"
    case Fresh = "fresh_today"
}

enum PxCategory: Int {
    case all = 0
    case blackAndWhite = 10
    case celebrities = 9
    case cityAndArchitecture = 8
    case fashion = 1
    case fineArt = 7
    case landscapes = 6
    case macro = 5
    case nature = 4
    case nude = 2
    case people = 3
    
    func categoryName() -> String {
        switch self {
        case .people:
            return "People"
        case .blackAndWhite:
            return "Black and White"
        case .fashion:
            return "Fashion"
        case .nude:
            return "Nude"
        case .nature:
            return "Nature"
        case .macro:
            return "Macro"
        case .landscapes:
            return "Landscapes"
        case .cityAndArchitecture:
            return "City and Architecture"
        case .fineArt:
            return "Fine Art"
        default:
            return "All"
        }
    }
    
    func categoryCode() -> Int {
        switch self {
        case .people:
            return 7
        case .nude:
            return 4
        case .all:
            return 0
        case .blackAndWhite:
            return 5
        case .celebrities:
            return 1
        case .cityAndArchitecture:
            return 9
        case .fashion:
            return 14
        case .fineArt:
            return 24
        case .landscapes:
            return 8
        case .macro:
            return 12
        case .nature:
            return 18
        }
    }
    
    static func count() -> Int {
        return 9
    }
}

class PxStore: UserNetworking {
    fileprivate static let desiredHighResSize: Float = 2048.0
    fileprivate let network: Networking
    
    init(network: Networking) {
        self.network = network
    }
    
    deinit {
        
    }
    
    enum PxRouter: URLRequestConvertible {
        static let baseURL = "https://api.500px.com/v1/"
        case photos(feature: PxFeature, category: PxCategory, page: Int)
        case searchPhotos(feature: PxFeature, category: PxCategory, searchTerm: String, page: Int)
        case userPhotos(ownerID: String, page: Int)
        case downloadImage(url: String)
        case photoInfoLarge(photoID: String)
        case userDetails(userId: String)
        
        func asURLRequest() throws -> URLRequest {
            var path = ""
            var fullURL: String?
            var parameters:[String: Any] = ["consumer_key":insert key here]
            switch self {
            case .photos(let feature, let category, let page):
                path = "photos"
                parameters["page"] = page
                parameters["feature"] = feature.rawValue
                if category != PxCategory.all {
                    parameters["only"] = category.categoryName()
                }
                parameters["image_size"] = "4,30,2048"
            case .searchPhotos(let feature, let category, let searchTerm, let page):
                path = "photos/search"
                parameters["page"] = page
                parameters["feature"] = feature.rawValue
                if category != PxCategory.all {
                    parameters["only"] = category.categoryName()
                }
                parameters["term"] = searchTerm
                parameters["image_size"] = "4,30,2048"
            case .userPhotos(let ownerId, let page):
                path = "photos"
                parameters["page"] = page
                parameters["feature"] = "user"
                parameters["user_id"] = ownerId
                parameters["image_size"] = "4,30,2048"
            case .photoInfoLarge(let photoID):
                path = String(format: "photos/%@", arguments: [photoID])
                parameters["image_size"] = 2048
            case .userDetails(let userId):
                path = "users/show"
                parameters["id"] = userId
            case .downloadImage(let url):
                fullURL = url
            }
            if fullURL != nil {
                return URLRequest(url: URL(string: fullURL!)!)
            } else {
                let url = try PxRouter.baseURL.asURL().appendingPathComponent(path)
                let urlRequest = URLRequest(url: url)
                return try URLEncoding.methodDependent.encode(urlRequest, with: parameters)
            }
        }
    }
    
    fileprivate class func pxPhotoFromJson(_ js: JSON) -> PxPhoto {
        let px = PxPhoto()
        px.title = js["name"].stringValue
        let images = js["images"].arrayValue
        for image in images {
            if image["size"].stringValue == "2048" {
                px.bigPhotoSrc = image["url"].stringValue
            } else if image["size"].stringValue == "4" {
                px.mediumPhotoSrc = image["url"].stringValue
            } else {
                px.smallPhotoSrc = image["url"].stringValue
            }
        }
        px.photoId = js["id"].stringValue
        px.ownerId = js["user"]["id"].stringValue
        px.ownerFullName = js["user"]["fullname"].stringValue
        let exif = PhotoExif()
        exif.apperture = js["aperture"].stringValue
        exif.camera = js["camera"].stringValue
        exif.exposureTime = js["shutter_speed"].stringValue
        exif.focalLength = js["focal_length"].stringValue
        exif.ISO = js["iso"].stringValue
        exif.lens = js["lens"].stringValue
        px.exif = exif
        let originalWidth = js["width"].floatValue
        let originalHeight = js["height"].floatValue
        var factor: Float = originalWidth / PxStore.desiredHighResSize
        if originalHeight > originalWidth {
            factor = originalHeight / PxStore.desiredHighResSize
        }
        if factor > 1 {
            px.largeHeight = Int(originalHeight / factor)
            px.largeWidth = Int(originalWidth / factor)
        } else {
            px.largeHeight = Int(originalHeight)
            px.largeWidth = Int(originalWidth)
        }
        //256 on longest edge
        if originalWidth > originalHeight {
            px.thumbWidth = 256
            px.thumbHeight = Int(originalHeight * 256 / originalWidth)
        } else {
            px.thumbHeight = 256
            px.thumbWidth = Int(originalWidth * 256 / originalHeight)
        }
        return px
    }
    
    func largePhoto(photoID: String) -> Observable<(String, String)> {
        return network.requestJSON(PxRouter.photoInfoLarge(photoID: photoID))
            .map { js -> (String, String) in
                let url = js["photo"]["image_url"].stringValue
                return (url, photoID)
            }
    }
    
    func userPhotos(ownerId: String, page: Int) -> Observable<[PxPhoto]> {
        return network.requestJSON(PxRouter.userPhotos(ownerID: ownerId, page: page))
            .map { js -> [PxPhoto] in
                let photos = js["photos"].arrayValue
                var pxs = [PxPhoto]()
                for ph in photos {
                    pxs.append(PxStore.pxPhotoFromJson(ph))
                }
                return pxs
            }
    }
    
    func searchPhotos(feature: PxFeature, category: PxCategory, term: String, page: Int) -> Observable<[PxPhoto]> {
        return network.requestJSON(PxRouter.searchPhotos(feature: feature, category: category, searchTerm: term, page: page))
            .map { (js) -> [PxPhoto] in
                let photos = js["photos"].arrayValue
                var pxs = [PxPhoto]()
                for pjs in photos {
                    pxs.append(PxStore.pxPhotoFromJson(pjs))
                }
                return pxs
            }
    }
    
    func getPhotos(feature: PxFeature, category: PxCategory, page: Int) -> Observable<[PxPhoto]> {
        return network.requestJSON(PxRouter.photos(feature: feature, category: category, page: page))
            .map { (js) -> [PxPhoto] in
                let photos = js["photos"].arrayValue
                var pxs = [PxPhoto]()
                for pjs in photos {
                    pxs.append(PxStore.pxPhotoFromJson(pjs))
                }
                return pxs
        }
    }
    
    func downloadImage(url: String, photoId: String) -> Observable<(UIImage, String)> {
        return network.requestImage(url)
            .map { (image) -> (UIImage, String) in
                return (image, photoId)
            }
    }
    
    func userDetails(userId: String) -> Observable<AbstractUser> {
        return network.requestJSON(PxRouter.userDetails(userId: userId))
            .flatMap({[weak self] (userjs) -> Observable<AbstractUser> in
                let u = AbstractUser()
                u.userId = userId
                let js = userjs["user"]
                u.userName = js["fullname"].stringValue
                u.photosCount = js["photos_count"].intValue
                
                let avatarUrl = js["userpic_url"].stringValue
                return self!.network.requestImageAsData(avatarUrl).map { data in
                    u.avatar = data
                    return u
                }
            }).catchError({ (err) -> Observable<AbstractUser> in
                debugPrint(err)
                return Observable<AbstractUser>.just(AbstractUser())
            })
    }
}
