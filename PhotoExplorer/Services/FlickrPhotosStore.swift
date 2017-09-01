//
//  FlickrPhotosStore.swift
//  PhotoExplorer
//
//  Created by Mihai on 1/23/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON


class FlickrPhotosStore: UserNetworking {
    fileprivate var network: Networking!
    
    init(network: Networking) {
        self.network = network
    }
    
    enum PhotosRouter: URLRequestConvertible {
        static let baseURL = "https://api.flickr.com/services/rest"
        
        case popularPhotos(page: Int, pageSize: Int)
        case searchPhotos(term: String, page: Int, pageSize: Int)
        case mediaSizes(photoId: String)
        case photoExif(photoId: String)
        case userPhotos(userId: String, page: Int, pageSize: Int)
        case userInfo(userId: String)
        
        func asURLRequest() throws -> URLRequest {
            let path = "";
            var parameters:[String: Any] = ["format":"json", "nojsoncallback":"1","api_key":insert key here]
            switch self {
            case .popularPhotos(let page, let pageSize):
                parameters["page"] = page
                parameters["per_page"] = pageSize
                parameters["method"] = "flickr.interestingness.getList"
                parameters["extras"] = "url_s, url_l,url_m,owner_name"
            case .searchPhotos(let term, let page, let pageSize):
                parameters["page"] = page
                parameters["per_page"] = pageSize
                parameters["text"] = term
                parameters["method"] = "flickr.photos.search"
                parameters["extras"] = "url_s, url_l,url_m,owner_name"
            case .userPhotos(let userId, let page, let pageSize):
                parameters["user_id"] = userId
                parameters["page"] = page
                parameters["per_page"] = pageSize
                parameters["extras"] = "url_s, url_l,url_m,owner_name"
                parameters["method"] = "flickr.people.getPublicPhotos"
            case .mediaSizes(let photoId):
                parameters["method"] = "flickr.photos.getSizes"
                parameters["photo_id"] = photoId
            case .photoExif(let photoId):
                parameters["method"] = "flickr.photos.getExif"
                parameters["photo_id"] = photoId
            case .userInfo(let userId):
                parameters["method"] = "flickr.people.getInfo"
                parameters["user_id"] = userId
            }
            let url = try PhotosRouter.baseURL.asURL().appendingPathComponent(path)
            let urlRequest = try URLRequest(url: url, method: HTTPMethod.get)
            return try URLEncoding.methodDependent.encode(urlRequest, with: parameters)
        }
    }

    class func photoFromJS(js: JSON) -> FlickrPhoto {
        let ph = FlickrPhoto()
        ph.ownerId = js["owner"].stringValue
        ph.photoId = js["id"].stringValue
        ph.title = js["title"].stringValue
        ph.ownerFullName = js["ownername"].stringValue
        ph.smallPhotoSrc = js["url_s"].stringValue
        ph.thumbWidth = js["width_s"].intValue
        ph.thumbHeight = js["height_s"].intValue
        ph.mediumPhotoSrc = js["url_m"].stringValue
        ph.bigPhotoSrc = js["url_l"].stringValue
        ph.largeWidth = js["width_l"].intValue
        ph.largeHeight = js["height_l"].intValue
        return ph
    }
    
    func downloadImage(source: String, photoId: String) -> Observable<(UIImage, String)> {
        return network.requestImage(source)
            .map { image -> (UIImage, String) in
                return (image, photoId)
        }
    }
    
    func getMediaSizes(photoId: String) -> Observable<(String, Int, String)> {
        return network.requestJSON(PhotosRouter.mediaSizes(photoId: photoId))
            .flatMap({ (json) -> Observable<(String, Int, String)> in
                let observable = Observable<(String, Int, String)>.create({ (observer) -> Disposable in
                    let sizes = json["sizes"]["size"].arrayValue
                    for sz in sizes {
                        if (sz["label"].stringValue == "Large Square") {
                            observer.onNext((sz["source"].stringValue, 0, photoId))
                        }
                        if (sz["label"].stringValue == "Large") {
                            observer.onNext((sz["source"].stringValue, 1, photoId))
                        }
                    }
                    observer.onCompleted()
                    return Disposables.create()
                })
                return observable
            })
    }
    
    func userPhotos(userId: String, page: Int, pageSize: Int) -> Observable<[FlickrPhoto]> {
        return network.requestJSON(PhotosRouter.userPhotos(userId: userId, page: page, pageSize: pageSize))
            .map{ json -> [FlickrPhoto] in
                let photoList = json["photos"]["photo"].arrayValue
                var photos = [FlickrPhoto]()
                for photoJson in photoList {
                    photos.append(FlickrPhotosStore.photoFromJS(js: photoJson))
                }
                return photos
            }
    }
    
    func popularPhotos(page: Int, pageSize: Int) -> Observable<[FlickrPhoto]> {
        return network.requestJSON(PhotosRouter.popularPhotos(page: page, pageSize: pageSize))
            .map{ json -> [FlickrPhoto] in
                let photoList = json["photos"]["photo"].arrayValue
                var photos = [FlickrPhoto]()
                for photoJson in photoList {
                    photos.append(FlickrPhotosStore.photoFromJS(js: photoJson))
                }
                return photos
            }
    }
    
    func searchPhotos(term: String, page: Int, pageSize: Int) -> Observable<[FlickrPhoto]> {
        return network.requestJSON(PhotosRouter.searchPhotos(term: term, page: page, pageSize: pageSize))
            .map { json -> [FlickrPhoto] in
                let list = json["photos"]["photo"].arrayValue
                var photos = [FlickrPhoto]()
                for jsphoto in list {
                    photos.append(FlickrPhotosStore.photoFromJS(js: jsphoto))
                }
                return photos
            }
    }
    
    func userDetails(userId: String) -> Observable<AbstractUser> {
        return network.requestJSON(PhotosRouter.userInfo(userId: userId))
            .flatMap({[weak self] (json) -> Observable<AbstractUser> in
                if self == nil {
                    return Observable<AbstractUser>.empty()
                }
                let userInfo = AbstractUser()
                userInfo.userId = userId
                userInfo.photosCount = json["person"]["photos"]["count"]["_content"].intValue
                userInfo.userName = json["person"]["realname"]["_content"].stringValue
                let iconServer = json["person"]["iconserver"].intValue
                let farm = json["person"]["iconfarm"].stringValue
                let nsid = json["person"]["nsid"].stringValue
                var url = "https://www.flickr.com/images/buddyicon.gif"
                if iconServer > 0 {
                    url = String(format: "http://farm%@.staticflickr.com/%d/buddyicons/%@.jpg", farm, iconServer, nsid)
                }
                return self!.network.requestImageAsData(url).map { data -> AbstractUser in
                    userInfo.avatar = data
                    return userInfo
                }
            })
    }
    
    func exifSignal(photoId: String) -> Observable<(PhotoExif, String)> {
        return network.requestJSON(PhotosRouter.photoExif(photoId: photoId))
            .map { js -> (PhotoExif, String) in
                return (self.exifFromJson(json: js), photoId)
            }
    }
    
    fileprivate func exifFromJson(json: JSON) -> PhotoExif {
        let exif = PhotoExif()
        exif.camera = json["photo"]["camera"].stringValue

        let tags = json["photo"]["exif"].arrayValue
        for tag in tags {
            let content = tag["raw"]["_content"].stringValue
            switch tag["tag"].stringValue {
            case "ISO":
                exif.ISO = content
            case "ExposureTime":
                exif.exposureTime = content
            case "FNumber":
                exif.apperture = content
            case "ExposureProgram":
                exif.mode = content
            case "FocalLength":
                exif.focalLength = content
            case "ExposureMode":
                exif.mode = content
            case "WhiteBalance":
                exif.wb = content
            case "FocalLengthIn35mmFormat":
                exif.focalLength = content
            case "LensInfo":
                exif.lens = content
            default:
                continue
            }
        }
        return exif
    }
}
