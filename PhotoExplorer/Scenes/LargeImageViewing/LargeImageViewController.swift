//
//  LargeImageViewController.swift
//  PhotoExplorer
//
//  Created by Mihai on 1/31/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit
import RxSwift

enum InfoPanelState {
    case showingExif
    case showingUser
}

class LargeImageViewController: UIViewController, UIScrollViewDelegate {
    fileprivate var inits = 0
    fileprivate var doubleTapGR: UITapGestureRecognizer!
    fileprivate static let showUserGallerySegue = "showUserGallerySegue"
    private let imageZoomed = PublishSubject<Void>()
    private let disposeBag = DisposeBag()
    
    var panelViewModel: PanelStateViewModel?
    var viewModel: LargeImageViewModeling!
    
    @IBOutlet weak var containerInfoView: UIView!
    @IBOutlet weak var scrollView: CenteredScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var userView: UserDetailsView!
    @IBOutlet weak var exifView: ExifView!
    @IBOutlet weak var exifHolderViewHeight: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if panelViewModel!.panelHidden() {
            self.containerInfoView.isHidden = true
        } else {
            self.containerInfoView.isHidden = false
            self.applyInfoState(panelViewModel!.panelState())
        }
    }
    
    override func viewDidLoad() {
        self.scrollView.delegate = self
        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        doubleTapGR = UITapGestureRecognizer(target: self, action: #selector(LargeImageViewController.doubleTapped(_:)))
        doubleTapGR.numberOfTapsRequired = 2
        self.scrollView.addGestureRecognizer(doubleTapGR)
        let singleTapGR = UITapGestureRecognizer(target: self, action: #selector(LargeImageViewController.singleTapped(_:)))
        singleTapGR.numberOfTapsRequired = 1
        singleTapGR.require(toFail: doubleTapGR)
        self.scrollView.addGestureRecognizer(singleTapGR)
        viewModel.image.asObservable().subscribe(onNext:{[weak self] img in
            self?.imageView.contentMode = UIViewContentMode.scaleToFill
            self?.updateImage(img)
            self?.view.layoutIfNeeded()
            self?.view.layoutSubviews()
        }).addDisposableTo(disposeBag)
        viewModel.downloadImage().subscribe().addDisposableTo(disposeBag)
        viewModel.imageZoomed(trigger: imageZoomed.asObservable()).subscribe().addDisposableTo(disposeBag)
        self.setupData()
    }
    
    func setupData() {
        self.userView.userText = viewModel!.photo.ownerFullName
        self.userView.titleLabel.text = viewModel!.photo.title
        self.loadExif(viewModel!.photo.exif)
        if viewModel?.ownerId == nil {
            self.userView.userButton.addTarget(self, action: #selector(LargeImageViewController.userNameTapped(_:)), for: .touchUpInside)
        }
    }
    
    func saveButtonPushed(_ sender: AnyObject) {
        guard let image = imageView.image else {
            return
        }
        if Int(image.size.width) < viewModel!.photo.largeWidth {
            let ac = UIAlertController(title: "Warning", message: "Double tap or zoom in to load full res image first!", preferredStyle: UIAlertControllerStyle.alert)
            ac.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(ac, animated: true, completion: nil)
            return
        } else {
            UIImageWriteToSavedPhotosAlbum(imageView.image!, self, #selector(LargeImageViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        guard error == nil else {
            let ac = UIAlertController(title: "Error", message: "Did you allow access to photos?", preferredStyle: UIAlertControllerStyle.alert)
            ac.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(ac, animated: true, completion: nil)
            return
        }
        let ac = UIAlertController(title: "Done!", message: "Enjoy!", preferredStyle: UIAlertControllerStyle.alert)
        ac.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(ac, animated: true, completion: nil)
        //Image saved successfully
    }
    
    
    func doubleTapped(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if fabs(self.scrollView.zoomScale - self.scrollView.minimumZoomScale) < 0.1 {
                self.scrollView.setZoomScale(self.scrollView.maximumZoomScale, animated: true)
            } else {
                self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: true)
            }
            return
        }
    }
    
    func singleTapped(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if self.containerInfoView.isHidden {
                self.containerInfoView.isHidden = false
                self.navigationController?.isNavigationBarHidden = false
            } else {
                self.containerInfoView.isHidden = true
                self.navigationController?.isNavigationBarHidden = true
            }
            panelViewModel!.setPanelHidden(self.containerInfoView.isHidden)
        }
    }
    
    func userNameTapped(_ sender: AnyObject) {
        self.performSegue(withIdentifier: LargeImageViewController.showUserGallerySegue, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == LargeImageViewController.showUserGallerySegue {
            if let dc = segue.destination as? UserGalleryCollectionViewController {
                dc.viewModel = viewModel!.userViewModel()
            }
        }
    }
    
    @IBAction func showHideTapped(_ sender: AnyObject) {
        if self.exifHolderViewHeight.constant > 100 {
            panelViewModel!.setPanelState(.showingUser)
            self.applyInfoState(.showingUser)
        } else {
            panelViewModel!.setPanelState(.showingExif)
            self.applyInfoState(.showingExif)
        }
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.view.layoutSubviews()
        }) 
    }
    
    func applyInfoState(_ state: InfoPanelState) {
        if state == .showingUser {
            self.exifView.isHidden = true
            self.userView.isHidden = false
            self.exifHolderViewHeight.constant = 52
        } else {
            self.exifView.isHidden = false
            self.userView.isHidden = true
            self.exifHolderViewHeight.constant = 160
        }
        self.view.setNeedsUpdateConstraints()
    }
    
    func loadExif(_ exif: PhotoExif?) {
        guard let exif = exif else {
            return
        }
        exifView.cameraLabel.text = String(format: "%@ %@", exif.camera, exif.lens)
        exifView.isoLabel.text = exif.ISO
        exifView.appertureLabel.text = exif.apperture
        exifView.modeLabel.text = exif.mode
        exifView.fieldLabel.text = exif.focalLength
        exifView.wbLabel.text = exif.wb
        exifView.timeLabel.text = exif.exposureTime
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let doScale = scrollView.zoomScale == scrollView.minimumZoomScale
        guard let image = imageView.image else {
            return
        }
        let imageSize = image.size
        let widthScale = size.width / imageSize.width
        let heightScale = size.height / imageSize.height
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale
        if doScale {
            scrollView.setZoomScale(minScale, animated: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func updateImage(_ image: UIImage) {
        var replacingImage = false
        var pos = scrollView.contentOffset
        let maxZoomScale = scrollView.maximumZoomScale
        let zoomScale = scrollView.zoomScale
        pos.x = pos.x / zoomScale
        pos.y = pos.y / zoomScale
        
        if self.scrollView.minimumZoomScale < 1 {
            replacingImage = true
            let previousImageSize = imageView.image!.size
            pos.x = pos.x * image.size.width / previousImageSize.width
            pos.y = pos.y * image.size.height / previousImageSize.height
        }
        let photo = viewModel!.photo
        let imageSize = image.size
        imageView.image = image
        self.scrollView.maximumZoomScale =  !replacingImage ? CGFloat((photo?.largeWidth)!) / imageSize.width : 1
        let widthScale = self.scrollView.bounds.size.width / imageSize.width
        let heightScale = self.scrollView.bounds.size.height / imageSize.height
        let minScale = min(widthScale, heightScale)
        if minScale < 1  {
            self.scrollView.minimumZoomScale = minScale
            if replacingImage {
                scrollView.setZoomScale(zoomScale / maxZoomScale, animated: false)
                scrollView.contentOffset = CGPoint(x: pos.x * scrollView.zoomScale , y: pos.y * scrollView.zoomScale)
            } else {
                self.scrollView.setZoomScale(min(widthScale, heightScale), animated: false )
            }
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
           DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(NSEC_PER_MSEC) * 500) / Double(NSEC_PER_SEC), execute: { () -> Void in
                self.imageZoomed.onNext()
           })
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
