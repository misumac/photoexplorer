//
//  StalkingViewController.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/18/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit
import RxSwift

private let userCell = "userCell"
private let selectionSeque = "showUserGallery"

class StalkingViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var viewModel: StalkingViewModel!
    let bag = DisposeBag()
    let viewAppears: Observable<Void> = PublishSubject<Void>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        navigationItem.title = "Stalking"
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 88
        tableView.dataSource = self
        tableView.delegate  = self

        viewAppears.bind(to: viewModel.viewAppears).addDisposableTo(bag)
        viewModel.usersChanged().subscribe(onNext: { [weak self] changes in
            guard let weakself = self else { return }
            guard let changeset = changes else { return }
            weakself.tableView.beginUpdates()
            let mapper: (Int) -> (IndexPath) = {IndexPath(row: $0, section: 0)}
            weakself.tableView.insertRows(at: changeset.inserted.map(mapper) , with: .none)
            weakself.tableView.deleteRows(at: changeset.deleted.map(mapper), with: .none)
            weakself.tableView.endUpdates()
            weakself.tableView.reloadRows(at: changeset.updated.map(mapper), with: .none)
            }).addDisposableTo(bag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == selectionSeque {
            guard let index = sender as? IndexPath else {
                return
            }
            guard let dc = segue.destination as? UserGalleryCollectionViewController else {
                return
            }
            let vm = viewModel.childViewModel(viewModel.user(index: (index as NSIndexPath).row))
            dc.viewModel = vm as! PhotoCollectionViewModeling
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (viewAppears as! PublishSubject<Void>).onNext()
    }
}

extension StalkingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: userCell, for: indexPath)
        let imageView = cell.viewWithTag(100) as! UIImageView
        let user = viewModel.user(index: (indexPath as NSIndexPath).row)
        if let imageData = user.userAvatar {
            imageView.image =  UIImage(data: imageData as Data)
        } else {
            imageView.image = nil
        }
        let serviceImage = cell.viewWithTag(103) as! UIImageView
        serviceImage.contentMode = .scaleAspectFit
        if user.service == "500px" {
            serviceImage.image = UIImage(named: "500px")?.withRenderingMode(.alwaysTemplate)
            serviceImage.tintColor = UIColor.white
        } else {
            serviceImage.image = UIImage(named: "Flickr")
        }
        let nameLabel = cell.viewWithTag(101) as! UILabel
        nameLabel.text = user.name
        let newLabel = cell.viewWithTag(102) as! UILabel
        newLabel.text = String(format: "New: %d, total: %d", user.unseenPhotos, user.photo_count)
        return cell
    }
}

extension StalkingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: selectionSeque, sender: indexPath)
    }
}
