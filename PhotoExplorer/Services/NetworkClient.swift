//
//  NetworkClient.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/2/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import SwiftyJSON

public final class NetworkClient: Networking {
    fileprivate let queue = DispatchQueue(label: "PhotoExplorer.Services.Network.Queue", attributes: [])
    
    public init() { }
    
    public func requestJSON(_ request: URLRequestConvertible) -> Observable<JSON> {
        return Observable<JSON>.create({ (observer) -> Disposable in
            let req = Alamofire.request(request).responseJSON(queue: self.queue, options: JSONSerialization.ReadingOptions.allowFragments) { response in
                switch response.result {
                case .success(let value):
                    let js = JSON(value)
                    observer.onNext(js)
                    observer.onCompleted()
                case .failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create {
                req.cancel()
            }
        })
    }
    
    public func requestImage(_ url: String) -> Observable<UIImage> {
        return Observable<UIImage>.create { (observer) -> Disposable in
            let req = Alamofire.request(url).responseData(queue: self.queue, completionHandler: { (responseData) in
                switch responseData.result {
                case .success(let data):
                    let cachedURLResponse = CachedURLResponse(response: responseData.response!, data: data, userInfo: nil, storagePolicy: .allowed)
                    URLCache.shared.storeCachedResponse(cachedURLResponse, for: responseData.request!)
                    if let image = UIImage(data: data) {
                        observer.onNext(image)
                    }
                    observer.onCompleted()
                case .failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create {
                req.cancel()
            }
        }
    }
    
    public func requestImageAsData(_ url: String) -> Observable<Data> {
        
        return Observable<Data>.create({ (observer) -> Disposable in
            let req = Alamofire.request(url).responseData(queue: self.queue, completionHandler: { (dataResponse) in
                switch dataResponse.result {
                case .success(let data):
                    let cachedURLResponse = CachedURLResponse(response: dataResponse.response!, data: data, userInfo: nil, storagePolicy: .allowed)
                    URLCache.shared.storeCachedResponse(cachedURLResponse, for: dataResponse.request!)
                    observer.onNext(data)
                    observer.onCompleted()
                case .failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create {
                req.cancel()
            }
        })
    }
}
