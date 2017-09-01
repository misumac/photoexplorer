//
//  500pxCollectionViewController.swift
//  PhotoExplorer
//
//  Created by Mihai on 2/8/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import Haneke

private let reuseIdentifier = "cell"

class PxCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    var viewModel: PxMainPhotosViewModel!
    fileprivate var searchController: UISearchController!
    private let disposeBag = DisposeBag()
    private let scrollNearEnd: PublishSubject<Void> = PublishSubject()
    private let onViewAppears: Observable<Void> = PublishSubject()
    @IBOutlet var clearBarButton: UIBarButtonItem!
    @IBOutlet var searchBarButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let lay = GalleryLayout()
        lay.photoCollectionViewModel = viewModel
        lay.headerViewHeight = 90
        collectionView?.collectionViewLayout = lay
        collectionView?.indicatorStyle = .white
        navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        navigationItem.rightBarButtonItems?.removeAll()
        navigationItem.rightBarButtonItems?.append(self.searchBarButton)

        self.bindViewModel()
    }
    
    func bindViewModel() {
        viewModel.setup(scrollNearEnd: scrollNearEnd)
        clearBarButton.rx.tap.bind(to: viewModel.clearCommand).addDisposableTo(disposeBag)
        viewModel.newPhotosIndexes.asObservable().subscribe(onNext: { (newIndexes) in
            if newIndexes.count > 0 {
                self.collectionView?.insertItems(at: newIndexes)
            } else {
                self.collectionView?.reloadData()
            }
        }).addDisposableTo(disposeBag)
        viewModel.searchTerm.asObservable().subscribe(onNext: {
            self.navigationItem.title = $0
            self.navigationItem.rightBarButtonItems?.removeAll()
            self.navigationItem.rightBarButtonItems?.append( ($0.characters.count > 0) ? self.clearBarButton : self.searchBarButton)
        }).addDisposableTo(disposeBag)
        viewModel.errorMessage.asObservable().subscribe(onNext: { message in
            if let message = message {
                self.displayError(message)
            }
        }).addDisposableTo(disposeBag)
        viewModel.currentPhotoIndex.asObservable().sample(onViewAppears).subscribe(onNext: { index in
            if self.viewModel!.photos.count > index {
                let path = IndexPath(row: index, section: 0)
                self.collectionView?.scrollToItem(at: path, at: .centeredVertically, animated: false)
            }
        }).addDisposableTo(disposeBag)
        viewModel.photosRetrieved.observeOn(MainScheduler.instance).subscribe().addDisposableTo(disposeBag)
    }
    
    @IBAction func onSearch(_ sender: AnyObject) {
        let searchResultsController = storyboard!.instantiateViewController(withIdentifier: PxSearchViewController.storyboardId)
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        // Present the view controller.
        present(searchController, animated: true, completion: nil)
    }
    
    func displayError(_ description: String) {
        let ac = UIAlertController(title: "Error", message: description, preferredStyle: UIAlertControllerStyle.alert)
        ac.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(ac, animated: true, completion: nil)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        viewModel?.searchTerm.value = searchController.searchBar.text!
        searchController.isActive = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (onViewAppears as! PublishSubject<Void>).onNext()
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLargeImageSegue" {
            guard let index = sender as? IndexPath else {
                return
            }
            guard let destController = segue.destination as? ImagePageViewController else {
                return
            }
            viewModel?.currentPhotoIndex.value = index.row
            destController.viewModel = self.viewModel
            destController.hidesBottomBarWhenPushed = true
        }
    }
    
    func onFeatureSelection(_ sender: AnyObject) {
        if let segment = sender as? UISegmentedControl {
            switch segment.selectedSegmentIndex {
            case 0:
                viewModel!.selectedFeature.value = PxFeature.Popular
            case 1:
                viewModel!.selectedFeature.value = PxFeature.Upcoming
            case 2:
                viewModel!.selectedFeature.value = PxFeature.Editors
            default:
                viewModel!.selectedFeature.value = PxFeature.Fresh
            }
        }
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let viewModel = viewModel {
            return viewModel.photos.count
        }
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageItem", for: indexPath)
        let imgView = cell.viewWithTag(100) as! UIImageView
        imgView.image = nil
        if let viewModel = viewModel {
            imgView.hnk_setImageFromURL(URL(string: viewModel.photos[indexPath.row].smallPhotoSrc)!)
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard viewModel != nil else {
            return UICollectionReusableView()
        }
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "featureHeader", for: indexPath)
            if let segment = headerView.viewWithTag(100) as? UISegmentedControl {
                if viewModel!.searchTerm.value.characters.count > 0 {
                    segment.isEnabled = false
                    segment.selectedSegmentIndex = UISegmentedControlNoSegment
                } else {
                    segment.isEnabled = true
                    var selIdx = 0;
                    switch viewModel!.selectedFeature.value {
                    case PxFeature.Popular:
                        selIdx = 0
                    case PxFeature.Upcoming:
                        selIdx = 1
                    case PxFeature.Editors:
                        selIdx = 2
                    case PxFeature.Fresh:
                        selIdx = 3
                    }
                    segment.selectedSegmentIndex = selIdx
                }
                segment.addTarget(self, action: #selector(PxCollectionViewController.onFeatureSelection(_:)), for: UIControlEvents.valueChanged)
            }
            if let catButton = headerView.viewWithTag(102) as? UIButton {
                let img = catButton.image(for: UIControlState())?.withRenderingMode(.alwaysTemplate)
                catButton.setImage(img, for: UIControlState())
                catButton.imageView?.tintColor = UIColor.white
            }
            if let catLabel = headerView.viewWithTag(101) as? UILabel {
                catLabel.text = String(format: "Category: %@", viewModel!.selectedCategory.categoryName())
            }
            return headerView
        }
        return UICollectionReusableView()
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var sz = collectionView.frame.size.width / 3
        
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft || UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            sz = collectionView.frame.size.width / 5
        }
        let ph = viewModel!.photos[(indexPath as NSIndexPath).row]
        let factor = sz / (CGFloat)(ph.thumbHeight)
        return CGSize(width: CGFloat(ph.thumbWidth) * factor, height: CGFloat(ph.thumbHeight) * factor)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height * 80 / 100 {
            self.scrollNearEnd.onNext()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showLargeImageSegue", sender: indexPath)
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}
