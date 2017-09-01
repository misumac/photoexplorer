//
//  BadgeGeneratorProtocol.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/25/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation
import RxSwift

protocol BadgeGeneratorProtocol {
    var badgeNumber: Observable<Int> { get }
}
