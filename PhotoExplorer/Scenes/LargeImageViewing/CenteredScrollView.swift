//
//  CenteredScrollView.swift
//  PhotoExplorer
//
//  Created by Mihai on 2/4/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit

class CenteredScrollView: UIScrollView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let boundsSize = self.bounds.size
        let centerView = self.subviews[0]
        var frameToCenter = centerView.frame
        if (frameToCenter.size.width < boundsSize.width) {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) * 0.5
        } else {
            frameToCenter.origin.x = 0
        }
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) * 0.5
        } else {
            frameToCenter.origin.y = 0
        }
        centerView.frame = frameToCenter
    }

}
