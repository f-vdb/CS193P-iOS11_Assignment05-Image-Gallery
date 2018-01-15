//
//  ImageGalleryCollectionViewController.swift
//  Programming_Project05-Image Gallery
//
//  Created by Michel Deiman on 13/01/2018.
//  Copyright © 2018 Michel Deiman. All rights reserved.
//

import UIKit

private let reuseIdentifier = "ImageCell"

class ImageGalleryCollectionViewController: UIViewController, DataForImageGallery, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UICollectionViewDelegateFlowLayout
{
    weak var imageGallery: ImageGallery! {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource  = self
            collectionView.delegate = self
            collectionView.dropDelegate = self
            collectionView.dragDelegate = self
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.minimumInteritemSpacing = 1
                layout.minimumLineSpacing = 1
            }
            collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(scaleCollectionViewCells(with:))))
        }
    }
    
    private var scaleForCollectionViewCell: CGFloat = 1.0
    @objc func scaleCollectionViewCells(with recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .changed, .ended:
            scaleForCollectionViewCell *= recognizer.scale
            recognizer.scale = 1
            collectionView.collectionViewLayout.invalidateLayout()
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        navigationItem.title = "Image Gallery: " + (imageGallery?.name ?? " undefined")
    }
    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? ImageCollectionViewCell {
            return cell.imageView != nil
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination.contents as? ImageViewController else { return }
        if let cell = sender as? ImageCollectionViewCell, let indexPath = collectionView.indexPath(for: cell) {
            vc.transferedImage = imageGallery.images[indexPath.item].image
        }
    }

    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return imageGallery != nil ? imageGallery.images.count : 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let cell = cell as? ImageCollectionViewCell {
            cell.imageView.image = imageGallery.images[indexPath.item].image
        }
        return cell
    }

    // UICollectionViewLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let aspectRatio = imageGallery.images[indexPath.item].aspectRatio
        let cellHeigth: CGFloat = 200 * scaleForCollectionViewCell / aspectRatio
        return CGSize(width: 200 * scaleForCollectionViewCell, height: cellHeigth)
    }
    
    // MARK: - Drag ('n Drop) for CollectionView...
    // MARK: - UICollectionViewDragDelegate methods
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if let image = imageGallery.images[indexPath.item].image {
            let dragItemImage = UIDragItem(itemProvider: NSItemProvider(object: image))
            dragItemImage.localObject = image
            return [dragItemImage]
        }
        return []
    }

    // MARK: - UICollectionViewDropDelegate methods
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        let localSession = session.localDragSession != nil
        return session.canLoadObjects(ofClass: UIImage.self) && (localSession || session.canLoadObjects(ofClass: NSURL.self))
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal
    {   let localSession = session.localDragSession != nil
        return UICollectionViewDropProposal(operation: localSession ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator)
    {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                collectionView.performBatchUpdates({
                    let imageData = imageGallery.images[sourceIndexPath.item]
                    imageGallery.images.remove(at: sourceIndexPath.item)
                    imageGallery.images.insert(imageData, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                })
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            } else {
                // no sourceIndexPath, so not local
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceHolderCell")
                )
                var imageDataForCell = ImageGallery.ImageData()
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (provider, error) in
                    DispatchQueue.main.async {
                        if let image = provider as? UIImage {
                            imageDataForCell.aspectRatio = image.size.width / image.size.height

                        } else {
                            return
                        }
                    }
                })
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self, completionHandler: { (provider, error) in
                    if let imageURL = (provider as? URL)?.imageURL {
                        let urlContents = try? Data(contentsOf: imageURL)
                        DispatchQueue.main.async {
                            if let imageData = urlContents, let image = UIImage(data: imageData) {
                                placeholderContext.commitInsertion(dataSourceUpdates: { (insertionIndexPath) in
                                    imageDataForCell.image = image
                                    imageDataForCell.url = imageURL
                                    self.imageGallery?.images.insert(imageDataForCell, at: insertionIndexPath.item)
                                })
                            } else {
                                placeholderContext.deletePlaceholder()
                            }
                        }
                    }
                })
            }
        }
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
