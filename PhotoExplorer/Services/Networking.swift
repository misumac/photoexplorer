//
//  Networking.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/2/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON
import Alamofire

public protocol Networking {
    
    func requestJSON(_ request: URLRequestConvertible) -> Observable<JSON>
    func requestImage(_ url: String) -> Observable<UIImage>
    func requestImageAsData(_ url: String) -> Observable<Data>
}
