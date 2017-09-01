//
//  SizeableImageView.swift
//  PhotoExplorer
//
//  Created by Mihai on 2/28/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit
@IBDesignable
class TabBarItemView: UIControl {
    static let selectionBarHeight: CGFloat = 3
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    var selectionBar: UIView!
    var imageView: UIImageView!
    fileprivate var internalImage: UIImage?
    var badgeLabel: UILabel!
    @IBInspectable var image: UIImage?
    @IBInspectable var imageMargin: CGFloat = 0
    @IBInspectable var imageTint: UIColor?
    @IBInspectable var badgeNumber: Int = 0 {
        didSet {
            self.layoutSubviews()
        }
    }
    @IBInspectable var itemSelected: Bool = false {
        didSet {
            self.layoutSubviews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    fileprivate func setup() {
        let barFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: 2)
        self.backgroundColor = UIColor.black
        selectionBar = UIView(frame: barFrame)
        selectionBar.backgroundColor = UIColor.white
        self.addSubview(selectionBar)
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        self.addSubview(imageView)
        badgeLabel = UILabel()
        let f = badgeLabel.font
        badgeLabel.font = f?.withSize(13.0)
        badgeLabel.textColor = UIColor.red
        badgeLabel.textAlignment = NSTextAlignment.right
        self.addSubview(badgeLabel)
    }
    
    override func layoutSubviews() {
        if itemSelected {
            let pos = self.frame.height > TabBarItemView.selectionBarHeight ? self.frame.height - TabBarItemView.selectionBarHeight : 0
            let barFrame = CGRect(x: 0, y: pos, width: self.frame.width, height: TabBarItemView.selectionBarHeight)
            selectionBar.frame = barFrame
            selectionBar.isHidden = false
        } else {
            selectionBar.isHidden = true
        }
        let imgHeight = self.frame.height - 2 * imageMargin - TabBarItemView.selectionBarHeight
        imageView.frame = CGRect(x: imageMargin, y: imageMargin, width: imgHeight, height: imgHeight)
        if let color = imageTint {
            imageView.image = image?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = color
        } else {
            imageView.image = image
        }
        if badgeNumber > 0 {
            badgeLabel.isHidden = false
            let frame = CGRect(x: self.frame.width - 30, y: 0, width: 30, height: 20)
            badgeLabel.text = String(format:"%d", badgeNumber)
            badgeLabel.frame = frame
        } else {
            badgeLabel.isHidden = true
        }
    }
}
