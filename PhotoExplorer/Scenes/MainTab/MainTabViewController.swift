//
//  MainTabViewController.swift
//  PhotoExplorer
//
//  Created by Mihai on 2/28/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit
import RxSwift

protocol MainTabDelegate {
    func setVisibility(_ visible: Bool)
}

class MainTabViewController: UIViewController, MainTabDelegate {
    @IBOutlet weak var pxItemView: TabBarItemView!
    @IBOutlet weak var flickrItemView: TabBarItemView!
    @IBOutlet weak var stalkingItemView: TabBarItemView!
    @IBOutlet weak var barHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabbarView: UIView!
    private let bag = DisposeBag()
    var controllers: [UIViewController] = []
    var pager: UIPageViewController?
    var selectedItem: TabBarItemView!
    var badgeGenerator: BadgeGeneratorProtocol!

    override func viewDidLoad() {
        super.viewDidLoad()
        pxItemView.itemSelected = true
        selectedItem = pxItemView
        flickrItemView.itemSelected = false
        stalkingItemView.itemSelected = false
        let c = self.storyboard?.instantiateViewController(withIdentifier: "pxNavController")
        controllers.append(c!)
        let fl = self.storyboard?.instantiateViewController(withIdentifier: "flickrNavController")
        controllers.append(fl!)
        let st = self.storyboard?.instantiateViewController(withIdentifier: "stalkNavController")
        controllers.append(st!)
        pager?.setViewControllers([controllers[0]], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        AppDelegate.sharedContainer().register(MainTabDelegate.self) { _ in
            return self
        }
        badgeGenerator.badgeNumber.observeOn(MainScheduler.instance).bind { count in
            self.stalkingItemView.badgeNumber = count
        }.addDisposableTo(bag)
}
    
    func setVisibility(_ visible: Bool) {
        if visible {
            barHeightConstraint.constant = 49
            tabbarView.isHidden = false
        } else {
            barHeightConstraint.constant = 0
            tabbarView.isHidden = true
        }
        view.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func flickrSelected(_ sender: AnyObject) {
        if flickrItemView.itemSelected {
            return
        }
        selectedItem.itemSelected = false
        flickrItemView.itemSelected = true
        selectedItem = flickrItemView
        pager?.setViewControllers([controllers[1]], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
    }
    
    @IBAction func pxSelected(_ sender: AnyObject) {
        if pxItemView.itemSelected {
            return
        }
        selectedItem.itemSelected = false
        pxItemView.itemSelected = true
        selectedItem = pxItemView
        pager?.setViewControllers([controllers[0]], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
    }

    @IBAction func stalkingSelected(_ sender: AnyObject) {
        if stalkingItemView.itemSelected {
            return
        }
        selectedItem.itemSelected = false
        stalkingItemView.itemSelected = true
        selectedItem = stalkingItemView
        pager?.setViewControllers([controllers[2]], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pagerEmbedSegue" {
            pager = segue.destination as? UIPageViewController
          //  pager?.dataSource = self
           // pager?.delegate = self
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
