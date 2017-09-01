//
//  ThumbsCollectionViewController.swift
//  PhotoExplorer
//
//  Created by Mihai on 1/23/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

private let photoCell = "imageItem"

class FlickrCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    fileprivate var searchController: UISearchController!
    private let bag = DisposeBag()
    private var viewAppears = PublishSubject<Void>()
    private let scrollSubject = PublishSubject<Void>()
    
    @IBOutlet var searchBarButton: UIBarButtonItem!
    @IBOutlet var clearButton: UIBarButtonItem!

    var viewModel: FlickrPhotosViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.setup(scrollNearEnd: scrollSubject.asObservable())
        let lay = GalleryLayout()
        lay.photoCollectionViewModel = viewModel!
        collectionView?.collectionViewLayout = lay
        collectionView?.indicatorStyle = .white
        navigationItem.title = "Flickr"
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        clearButton.rx.tap.asObservable().map {(_) -> String in return ""}.bind(to: viewModel.searchTerm).addDisposableTo(bag)
        viewModel.newPhotosIndexes.asObservable().subscribe(onNext: {newIndexes in
            if newIndexes.count > 0 {
                self.collectionView?.insertItems(at: newIndexes)
            } else {
                self.collectionView?.reloadData()
            }
        }).addDisposableTo(bag)
        viewModel.searchTerm.asObservable().subscribe(onNext:{ term in
            self.navigationItem.title = term
            self.navigationItem.rightBarButtonItems?.removeAll()
            if term.characters.count == 0 {
                self.navigationItem.rightBarButtonItems?.append(self.searchBarButton)
            } else {
                self.navigationItem.rightBarButtonItems?.append(self.clearButton)
                self.navigationItem.rightBarButtonItems?.append(self.searchBarButton)
            }
        }).addDisposableTo(bag)
        viewModel.currentPhotoIndex.asObservable().sample(viewAppears.asObservable()).subscribe(onNext:{ index in
            if index < self.viewModel.photos.count {
                self.collectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: UICollectionViewScrollPosition.centeredVertically, animated: false)
            }
        }).addDisposableTo(bag)
        viewModel.photosRetrieved.subscribe().addDisposableTo(bag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewAppears.onNext()
    }
    
    @IBAction func searchTapped(_ sender: AnyObject) {
        let searchResultsController = storyboard!.instantiateViewController(withIdentifier: PxSearchViewController.storyboardId)
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        // Present the view controller.
        present(searchController, animated: true, completion: nil)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        viewModel.searchTerm.value = searchController.searchBar.text!
        searchController.isActive = false
    }
    
    func displayError(_ description: String) {
        let ac = UIAlertController(title: "Error", message: description, preferredStyle: UIAlertControllerStyle.alert)
        ac.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(ac, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let index = sender as? IndexPath else {
            return
        }
        guard let destController = segue.destination as? ImagePageViewController else {
            return
        }
        viewModel.currentPhotoIndex.value = index.row
        destController.viewModel = viewModel
        destController.hidesBottomBarWhenPushed = true
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCell, for: indexPath)
        let imageView = cell.viewWithTag(100) as! UIImageView
        imageView.image = nil
        imageView.hnk_setImageFromURL(URL(string: viewModel.photos[indexPath.row].smallPhotoSrc)!)
        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height * 80 / 100 {
            scrollSubject.onNext()
        }
    }

    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var sz = collectionView.frame.size.width / 3
        
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft || UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            sz = collectionView.frame.size.width / 5
        }
        return CGSize(width: sz, height: sz)
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showLargeImageSegue", sender: indexPath)
    }

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
