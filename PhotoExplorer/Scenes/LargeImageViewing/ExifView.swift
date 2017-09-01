//
//  ExifView.swift
//
//
//  Created by Mihai on 2/13/16.
//
//

import UIKit

@IBDesignable class ExifView: UIView {
    var view: UIView!
    let nibName = "ExifView"
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var appertureImageView: UIImageView!
    @IBOutlet weak var appertureLabel: UILabel!
    @IBOutlet weak var fieldImageView: UIImageView!
    @IBOutlet weak var fieldLabel: UILabel!
    @IBOutlet weak var timeImage: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var modeImage: UIImageView!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var isoImageView: UIImageView!
    @IBOutlet weak var isoLabel: UILabel!
    @IBOutlet weak var wbImageView: UIImageView!
    @IBOutlet weak var wbLabel: UILabel!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    func setup() {
        //self.translatesAutoresizingMaskIntoConstraints = false
        view = loadViewFromNib()
        view.translatesAutoresizingMaskIntoConstraints = false
        /*
        view.frame = bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        */
        addSubview(view)
        //return
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0))
        
        self.colorizeImageView(self.cameraImageView)
        self.colorizeImageView(self.isoImageView)
        self.colorizeImageView(self.appertureImageView)
        self.colorizeImageView(self.modeImage)
        self.colorizeImageView(self.fieldImageView)
        self.colorizeImageView(self.wbImageView)
        self.colorizeImageView(self.timeImage)
    }
    
    func loadViewFromNib() -> UIView {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    fileprivate func colorizeImageView(_ img: UIImageView) {
        img.image = img.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        img.tintColor = UIColor.white
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    
}
