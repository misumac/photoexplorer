//
//  UserNetworking.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/21/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift

protocol UserNetworking {
    func userDetails(userId: String) -> Observable<AbstractUser>
}
