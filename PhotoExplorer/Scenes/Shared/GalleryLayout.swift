//
//  GalleryLayout.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/11/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit

class GalleryLayout: UICollectionViewLayout {
    fileprivate var contentSize: CGSize
    fileprivate var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    fileprivate var headerlayoutAttributes: [UICollectionViewLayoutAttributes] = []
    
    var columnSeparatorSize: CGFloat = 5
    var rowSeparatorSize: CGFloat = 5
    var headerViewHeight: CGFloat?
    var photoCollectionViewModel: PhotoCollectionViewModeling!
    
    override init() {
        contentSize = CGSize(width: 0, height: 0)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        contentSize = CGSize(width: 0, height: 0)
        super.init(coder: aDecoder)
    }
    
    override var collectionViewContentSize : CGSize {
        return contentSize
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributes[(indexPath as NSIndexPath).row]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var array = layoutAttributes.filter { (attribute) -> Bool in
            return rect.intersects(attribute.frame)
        }
        if headerlayoutAttributes.count > 0 && rect.intersects(headerlayoutAttributes[0].frame) {
            array.append(headerlayoutAttributes[0])
        }
        return array
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if headerlayoutAttributes.count > 0 {
            return headerlayoutAttributes[0]
        }
        return nil
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return !newBounds.size.equalTo(self.collectionView!.frame.size)
    }
    
    override func prepare() {
        super.prepare()
        
        layoutAttributes.removeAll()
        headerlayoutAttributes.removeAll()
        
        var yOffset: CGFloat = 0
        
        if let headerViewHeight = headerViewHeight {
            let path = IndexPath(item: 0, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: path)
            attributes.frame = CGRect(x: 0, y: 0, width: self.collectionView!.frame.size.width, height: headerViewHeight)
            headerlayoutAttributes.append(attributes)
            yOffset += headerViewHeight
        }
        
        let maxWidth = self.collectionView!.frame.width * 1.8
        let frameWidth = self.collectionView!.frame.width
        
        let numberOfSections = self.collectionView!.numberOfSections // 3
        var rowHeight: CGFloat = 0
        
        for section in 0 ..< numberOfSections {
            
            let numberOfItems = self.collectionView!.numberOfItems(inSection: section) // 3
            var xOffset: CGFloat = 0
            var item = 0
            while item < numberOfItems {
  //              let indexPath = NSIndexPath(forItem: item, inSection: section)
//                let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath) // 4
                var chosenPhotos: [AbstractPhoto] = []
                let ph = photoCollectionViewModel.photos[item]
                var aheadItem = item + 1
                var itemSize = CGSize(width: CGFloat(ph.thumbWidth), height: CGFloat(ph.thumbHeight))
                rowHeight = itemSize.height
                chosenPhotos.append(ph)
                var chosenFactors = [CGFloat(1.0)]
                var usedwidth = CGFloat(ph.thumbWidth)
                while usedwidth < maxWidth && aheadItem < numberOfItems {
                    let p = photoCollectionViewModel.photos[aheadItem]
                    var height = rowHeight
                    var tempWidth = usedwidth
                    if aheadItem - item == 1 {
                        height = (rowHeight + CGFloat(p.thumbHeight)) / 2
                        tempWidth = itemSize.width * height / itemSize.height
                    }
                    
                    let f = CGFloat(p.thumbHeight) / height
                    let w = CGFloat(p.thumbWidth) / f
                    if tempWidth + w < maxWidth {
                        if aheadItem - item == 1 {
                            rowHeight = height
                            chosenFactors[0] = itemSize.height / rowHeight
                            
                        }
                        chosenPhotos.append(p)
                        chosenFactors.append(f)
                        usedwidth = tempWidth + w
                        usedwidth += columnSeparatorSize
                        aheadItem += 1
                    } else {
                        break
                    }
                }
                let overallF = usedwidth / frameWidth
                for i in item ..< item + chosenPhotos.count {
                    let p = chosenPhotos[i-item]
                    let indexPath = IndexPath(item: i, section: section)
                    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath) // 4
                    itemSize = CGSize(width: CGFloat(p.thumbWidth) / chosenFactors[i-item] / overallF, height: CGFloat(p.thumbHeight) / chosenFactors[i-item] / overallF)
                    attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemSize.width, height: itemSize.height).integral
                    layoutAttributes.append(attributes)
                    xOffset += itemSize.width
                    xOffset += columnSeparatorSize
                }
                xOffset = 0
                yOffset += itemSize.height
                yOffset += rowSeparatorSize
                item += chosenFactors.count
            }
            
        }
        
        //yOffset += rowHeight
        
        contentSize = CGSize(width: self.collectionView!.frame.size.width, height: yOffset) // 11
        

    }
}
