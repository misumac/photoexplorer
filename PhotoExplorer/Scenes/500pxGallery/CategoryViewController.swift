//
//  CategoryViewController.swift
//  PhotoExplorer
//
//  Created by Mihai on 2/18/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import UIKit


protocol CategoryControllerDelegate {
    var selectedCategory:PxCategory {get set}
}

class CategoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    fileprivate let cellId = "categoryCell"
    fileprivate static let selectedImageName = "ic_check_box_white"
    fileprivate static let unselectedImageName = "ic_check_box_outline_blank_white"
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgroundView: UIView!
    var selectedCategory = PxCategory.all
    var delegate: CategoryControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        let gr = UITapGestureRecognizer(target: self, action: #selector(CategoryViewController.backgroundClicked(_:)))
        self.backgroundView.addGestureRecognizer(gr)
        self.selectedCategory = delegate!.selectedCategory
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if selectedCategory != delegate!.selectedCategory {
            delegate?.selectedCategory = self.selectedCategory
        }
    }
    
    func backgroundClicked(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PxCategory.count()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellId, for: indexPath)
        if let catLabel = cell.viewWithTag(101) as? UILabel {
            catLabel.text = PxCategory(rawValue: (indexPath as NSIndexPath).row)?.categoryName()
        }
        if let catImage = cell.viewWithTag(100) as? UIImageView {
            let imageName = ((indexPath as NSIndexPath).row == self.selectedCategory.rawValue) ? CategoryViewController.selectedImageName : CategoryViewController.unselectedImageName
            catImage.image = UIImage(named: imageName)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == self.selectedCategory.rawValue {
            return
        }
        let indexes = [ IndexPath(row: self.selectedCategory.rawValue, section: 0), indexPath ]
        
        self.selectedCategory = PxCategory(rawValue: (indexPath as NSIndexPath).row)!
        tableView.reloadRows(at: indexes, with: .none)
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
