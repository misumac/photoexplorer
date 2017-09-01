//
//  ImagePageViewController.swift
//  PhotoExplorer
//
//  Created by Mihai on 1/31/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit

class ImagePageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var viewModel: PhotoCollectionViewModeling?
    var currentImageController: LargeImageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        self.dataSource = self
        self.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false
        currentImageController = self.controllerForIndex(viewModel!.currentPhotoIndex.value)
        self.setViewControllers([currentImageController], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        let sg = UISwipeGestureRecognizer(target: self, action: #selector(ImagePageViewController.swipedDown))
        sg.direction = .down
        self.view.addGestureRecognizer(sg)
    }
    
    @IBAction func saveTapped(_ sender: AnyObject) {
        currentImageController.saveButtonPushed(self)
    }
    
    func swipedDown(_ gestureRecognizer : UISwipeGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func controllerForIndex(_ index:Int) -> LargeImageViewController {
        let imageController = self.storyboard!.instantiateViewController(withIdentifier: "ImageViewController") as! LargeImageViewController
        imageController.viewModel = viewModel?.childViewModel(forIndex: index)
        return imageController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let imageController = viewController as? LargeImageViewController else {
            return nil
        }
        if imageController.viewModel?.index == (viewModel?.photos.count)! - 1 {
            return nil
        }
        return self.controllerForIndex(imageController.viewModel!.index + 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageController = viewController as? LargeImageViewController else {
            return nil
        }
        if imageController.viewModel!.index == 0 {
            return nil
        }
        return self.controllerForIndex(imageController.viewModel!.index - 1)
    }
    // MARK: pageview controller delegate
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (completed) {
            currentImageController = pageViewController.viewControllers?.last as! LargeImageViewController
            let idx = currentImageController.viewModel!.index
            viewModel!.currentPhotoIndex.value = idx!
        }
    }
    
    // MARK: large image delegate
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.sharedContainer().resolve(MainTabDelegate.self)?.setVisibility(false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppDelegate.sharedContainer().resolve(MainTabDelegate.self)?.setVisibility(true)
    }

}
