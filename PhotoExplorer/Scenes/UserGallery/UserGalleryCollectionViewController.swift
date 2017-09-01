//
//  UserGalleryCollectionViewController.swift
//  PhotoExplorer
//
//  Created by Mihai on 2/21/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit
import RxSwift

private let reuseIdentifier = "imageCell"
private let bookmarkImage = "ic_bookmark_white"
private let unBookmarkImage = "ic_bookmark_border_white"

class UserGalleryCollectionViewController: UICollectionViewController {
    static let showPagerSegue = "showImagePagerSegue"
    var viewModel: PhotoCollectionViewModeling!
    var userViewModel: UserCollectionViewModeling!
    private let disposeBag = DisposeBag()
    private let viewAppears: Observable<Void> = PublishSubject<Void>()
    private let scrollNearEnd = PublishSubject<Void>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userViewModel = viewModel as? UserCollectionViewModeling
        navigationItem.title = userViewModel?.ownerName
        let bookmarkButton = UIBarButtonItem(image: UIImage(), style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = bookmarkButton
        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        self.bindViewModel()
        let lay = GalleryLayout()
        lay.photoCollectionViewModel = viewModel
        collectionView?.indicatorStyle = .white
        collectionView?.collectionViewLayout = lay
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func bindViewModel() {
        viewModel.setup(scrollNearEnd: scrollNearEnd.asObservable())
        let button = navigationItem.rightBarButtonItem!
        userViewModel.bindBookmarkAction(bookmarkAction: button.rx.tap.asObservable()).subscribe().addDisposableTo(disposeBag)
        viewModel.newPhotosIndexes.asObservable().subscribe(onNext: {[weak self] newIndexes in
            if newIndexes.count > 0 {
                self?.collectionView?.insertItems(at: newIndexes)
            } else {
                self?.collectionView?.reloadData()
            }
        }).addDisposableTo(disposeBag)
        viewModel.currentPhotoIndex.asObservable().sample(viewAppears)
            .subscribe(onNext: { [weak self] index in
                if let me = self {
                    if me.viewModel.photos.count > index {
                        me.collectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: UICollectionViewScrollPosition.centeredVertically, animated: false)
                    }
                }
                }).addDisposableTo(disposeBag)
        userViewModel.userIsBookmarked.asObservable().subscribe(onNext: { [weak self] bookmarked in
            self?.navigationItem.rightBarButtonItem?.image = UIImage(named: bookmarked ? unBookmarkImage : bookmarkImage)
        }).addDisposableTo(disposeBag)
        viewModel.photosRetrieved.subscribe().addDisposableTo(disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (viewAppears as! PublishSubject<Void>).onNext()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == UserGalleryCollectionViewController.showPagerSegue {
            let destController = segue.destination as! ImagePageViewController
            destController.viewModel = viewModel
            destController.hidesBottomBarWhenPushed = true
        }
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        let imageView = cell.viewWithTag(100) as! UIImageView
        imageView.image = nil
        imageView.hnk_setImageFromURL(URL(string: viewModel.photos[indexPath.row].smallPhotoSrc)!)
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.currentPhotoIndex.value = indexPath.row
        self.performSegue(withIdentifier: UserGalleryCollectionViewController.showPagerSegue, sender: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        var sz = collectionView.frame.size.width / 3
        
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft || UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            sz = collectionView.frame.size.width / 5
        }
        return CGSize(width: sz, height: sz)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height * 80 / 100 {
            scrollNearEnd.onNext()
        }
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
