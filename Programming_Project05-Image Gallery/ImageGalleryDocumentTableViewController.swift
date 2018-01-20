//
//  ImageGalleryDocumentTableViewController.swift
//  Programming_Project05-Image Gallery
//
//  Created by Michel Deiman on 13/01/2018.
//  Copyright © 2018 Michel Deiman. All rights reserved.
//

import UIKit

class ImageGallery {
    var name: String = ""
    
    struct ImageData: Equatable, Hashable {
        var url: URL?
        weak var image: UIImage?
        var aspectRatio: CGFloat {
            return image != nil ? image!.size.width / image!.size.height : 1
        }
        
        let hashValue: Int = {
            identifierFactory += 1
            return identifierFactory
        }()
        
        static func ==(lhs: ImageGallery.ImageData, rhs: ImageGallery.ImageData) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }
    var images: [ImageData] = []
    
    private static var identifierFactory = 0
}

protocol DataForImageGallery: class {
    weak var imageGallery: ImageGallery! { get  set }
}

class ImageGalleryDocumentTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    // MARK: - Model
    var activeImageGalleries: [ImageGallery] = {
        var imageGalleries: [ImageGallery] = []
        for name in ["1", "2", "3"] {
            let imageGallerie = ImageGallery()
            imageGallerie.name = name
            imageGalleries.append(imageGallerie)
        }
        return imageGalleries
    }()
    
    var recentlyDeletedImageGalleries: [ImageGallery] = []
    
    var imageGalleries: [[ImageGallery]]  {
        return [activeImageGalleries, recentlyDeletedImageGalleries]
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    @IBAction func addGallery(_ sender: UIBarButtonItem) {
        let newGallery = ImageGallery()
        let existingNamesForImageGalleries: [String] = activeImageGalleries.map { $0.name } + recentlyDeletedImageGalleries.map { $0.name }
        newGallery.name = "Untitled".madeUnique(withRespectTo: existingNamesForImageGalleries)
        activeImageGalleries.append(newGallery)
        let indexPath = IndexPath(row: activeImageGalleries.count-1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition(rawValue: 0)!)
        splitViewController?.delegate = self
        
        for vc in splitViewController?.viewControllers ?? [] {
            if let secondaryVC = vc.contents as? DataForImageGallery {
                secondaryVC.imageGallery = activeImageGalleries[0]
                break
            }
        }
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return imageGalleries.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageGalleries[section].count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "Recently Deleted" : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageGalleryNameCell", for: indexPath)
        if let cell = cell as? ImageGalleryDocumentTableViewCell {
            cell.textField.text = imageGalleries[indexPath.section][indexPath.row].name
        }
        return cell
    }
    
    // MARK: - Table View delegate methods
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if let cell = tableView.cellForRow(at: indexPath) as? ImageGalleryDocumentTableViewCell {
            cell.textField?.resignFirstResponder()
            cell.textField?.isUserInteractionEnabled = false
        }
        return indexPath
    }
  
    // MARK: Editing of TableView (rows) ...
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1 else { return nil }
        let restoreAction = UIContextualAction(style: .destructive, title: "Restore") { [weak self] (action: UIContextualAction, view: UIView, closure: (Bool)->Void) in
            if let imageGallery = self?.imageGalleries[indexPath.section][indexPath.row] {
                self?.recentlyDeletedImageGalleries.remove(at: indexPath.row)
                self?.activeImageGalleries.insert(imageGallery, at: 0)
                tableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 0))
                tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            }
        }
        restoreAction.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        return UISwipeActionsConfiguration(actions: [restoreAction])
    }

    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                let imageGallery = imageGalleries[indexPath.section][indexPath.row]
                activeImageGalleries.remove(at: indexPath.row)
                recentlyDeletedImageGalleries += [imageGallery]
                tableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 1))
            } else {
                recentlyDeletedImageGalleries.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    // TODO: - implement reordening of rows.
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
    }
    
    // Override to support conditional rearranging of the table view.
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
			if indexPath.section == 0 {
				indexPathRowForSegue = indexPath.row
				return true
			}
        }
        return false
    }
    
    private var indexPathRowForSegue: Int?
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dataForImageGalleryVC = segue.destination.contents as? DataForImageGallery {
            let index = indexPathRowForSegue ?? 0
            dataForImageGalleryVC.imageGallery = activeImageGalleries[index]
        }
        indexPathRowForSegue = nil
    }
}

extension ImageGalleryDocumentTableViewController: UISplitViewControllerDelegate {
//  iPhone??
    
//    func splitViewController(
//        _ splitViewController: UISplitViewController,
//        collapseSecondary secondaryViewController: UIViewController,
//        onto primaryViewController: UIViewController) -> Bool
//    {
//        return true
//    }
    
    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewControllerDisplayMode {
        switch svc.displayMode {
        case .allVisible: return .primaryHidden
        case .primaryHidden: return .allVisible
        default: return .primaryOverlay
        }
    }
    
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
        if let indexPath = tableView.indexPathForSelectedRow, let cell = tableView.cellForRow(at: indexPath) as? ImageGalleryDocumentTableViewCell {
            cell.textField?.resignFirstResponder()
            cell.textField?.isUserInteractionEnabled = false
        }
    }
}









