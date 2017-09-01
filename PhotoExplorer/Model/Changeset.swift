//
//  Changeset.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/2/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation

extension Array {
    func difference<T: Equatable>(_ otherArray: [T]) -> [T] {
        var result = [T]()
        
        for e in self {
            if let element = e as? T {
                if !otherArray.contains(element) {
                    result.append(element)
                }
            }
        }
        
        return result
    }
    
    func intersection<T: Equatable>(_ otherArray: [T]) -> [T] {
        var result = [T]()
        
        for e in self {
            if let element = e as? T {
                if otherArray.contains(element) {
                    result.append(element)
                }
            }
        }
        
        return result
    }
}

struct Changeset<T: Equatable> {
    
    var deletions: [IndexPath]
    var modifications: [IndexPath]
    var insertions: [IndexPath]
    
    typealias ContentMatches = (T, T) -> Bool
    
    init(oldItems: [T], newItems: [T], contentMatches: ContentMatches) {
        
        deletions = oldItems.difference(newItems).map { item in
            return Changeset.indexPathForIndex(oldItems.index(of: item)!)
        }
        
        modifications = oldItems.intersection(newItems)
            .filter({ item in
                let newItem = newItems[newItems.index(of: item)!]
                return !contentMatches(item, newItem)
            })
            .map({ item in
                return Changeset.indexPathForIndex(oldItems.index(of: item)!)
            })
        
        insertions = newItems.difference(oldItems).map { item in
            return IndexPath(row: newItems.index(of: item)!, section: 0)
        }
    }
    
    fileprivate static func indexPathForIndex(_ index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }
}
