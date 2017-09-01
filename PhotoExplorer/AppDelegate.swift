//
//  AppDelegate.swift
//  PhotoExplorer
//
//  Created by Mihai on 1/23/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit
import Foundation
import Swinject
import SwinjectStoryboard
import AlamofireNetworkActivityIndicator
import RealmSwift
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let container = Container()
    let bag = DisposeBag()
    
    static func sharedContainer() -> Container {
        return (UIApplication.shared.delegate as! AppDelegate).container
    }
    
    fileprivate func setupContainer() {
        //Services
        container.register(Networking.self) { _ in NetworkClient() }
        container.register(PxStore.self) { r in PxStore(network: r.resolve(Networking.self)!) }
        container.register(FlickrPhotosStore.self) {r in FlickrPhotosStore(network: r.resolve(Networking.self)!) }
        container.register(SyncStore.self) { (r) -> SyncStore in
            return SyncStore()
        }.inObjectScope(.container)
        
        //named services
        container.register(UserNetworking.self, name: "500px") { r in r.resolve(PxStore.self)! }
        container.register(UserNetworking.self, name: "flickr") { r in r.resolve(FlickrPhotosStore.self)! }
        // Viewmodels
        container.register(PxMainPhotosViewModel.self) { r in PxMainPhotosViewModel(pxStore: r.resolve(PxStore.self)!) }.inObjectScope(.container)
        container.register(FlickrPhotosViewModel.self) { r in
            FlickrPhotosViewModel(store: r.resolve(FlickrPhotosStore.self)!)
        }.inObjectScope(.container)
        container.register(CategoryControllerDelegate.self) { r in
            r.resolve(PxMainPhotosViewModel.self)!
        }
        container.register(LargePxImageViewModel.self) { r in LargePxImageViewModel(pxStore: r.resolve(PxStore.self)!) }
        container.register(LargeFlickrImageViewModel.self) { r in LargeFlickrImageViewModel(store: r.resolve(FlickrPhotosStore.self)!) }
        container.register(PxUserPhotosViewModel.self) { r in PxUserPhotosViewModel(pxStore: r.resolve(PxStore.self)!) }
        container.register(FlickrUserPhotosViewModel.self) { r in
            FlickrUserPhotosViewModel(store: r.resolve(FlickrPhotosStore.self)!)
        }
        container.register(StalkingViewModel.self) { r in StalkingViewModel(syncStore: r.resolve(SyncStore.self)!) }.inObjectScope(.container)
        
        container.register(PanelStateViewModel.self) { _ in PanelStateViewModel() }.inObjectScope(.container)
        //named user models
        container.register(UserCollectionViewModeling.self, name: "500px") { r in PxUserPhotosViewModel(pxStore: r.resolve(PxStore.self)!) }
        container.register(UserCollectionViewModeling.self, name: "flickr") { r in FlickrUserPhotosViewModel(store: r.resolve(FlickrPhotosStore.self)!) }
        // Views
        container.storyboardInitCompleted(MainTabViewController.self) { (r, controller) in
            controller.badgeGenerator = r.resolve(StalkingViewModel.self)!
        }
        container.storyboardInitCompleted(PxCollectionViewController.self) { r, controller in
            controller.viewModel = r.resolve(PxMainPhotosViewModel.self)!
        }
        container.storyboardInitCompleted(CategoryViewController.self) { r, controller in
            controller.delegate = r.resolve(CategoryControllerDelegate.self)!
        }
        container.storyboardInitCompleted(LargeImageViewController.self) { r, controller in
            controller.panelViewModel = r.resolve(PanelStateViewModel.self)
        }
        container.storyboardInitCompleted(FlickrCollectionViewController.self) { (resolver, controller) -> () in
            controller.viewModel = resolver.resolve(FlickrPhotosViewModel.self)!
        }
        container.storyboardInitCompleted(StalkingViewController.self) { (r, controller) in
            controller.viewModel = r.resolve(StalkingViewModel.self)!
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let config = Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion == 3) {
                    migration.renameProperty(onType: StalkedUser.className(), from: "newPhotos", to: "unseenPhotos")
                    migration.renameProperty(onType: StalkerOverview.className(), from: "newPhotosCount", to: "unseenPhotosCount")
                }
                // Nothing to do!
                // Realm will automatically detect new properties and removed properties
                // And will update the schema on disk automatically
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        let urlCache = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024, diskPath: "cachedResponse")
        URLCache.shared = urlCache
        
        self.setupContainer()
        NetworkActivityIndicatorManager.shared.isEnabled = true
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = UIColor.white
        window.makeKeyAndVisible()
        self.window = window
        
        let bundle = Bundle(for: MainTabViewController.self)
        let storyboard = SwinjectStoryboard.create(name: "Main", bundle: bundle, container: container)
        window.rootViewController = storyboard.instantiateInitialViewController()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

