//
//  ImageViewController.swift
//  Programming_Project05-Image Gallery
//
//  Created by Michel Deiman on 13/01/2018.
//  Copyright © 2018 Michel Deiman. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    weak var transferedImage: UIImage?
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            scrollView?.zoomScale = 1
            imageView.image = newValue
            let size = newValue?.size ?? CGSize.zero
            imageView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeigth?.constant = size.height
            scrollViewWidth?.constant = size.width
            let safeZoneBounds = UIEdgeInsetsInsetRect(view.bounds, view.safeAreaInsets)
            if size.width >= 0, size.width >= 0 {
                scrollView?.zoomScale = max(safeZoneBounds.width/size.width, safeZoneBounds.height/size.height)
            }
        }
    }
    
    var imageView = UIImageView()
    
    override func viewDidLoad() {
        image = transferedImage
        navigationItem.rightBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
    }
    
    // MARK: - Outlets!! ScrollView Layout Constraints for width and heigth
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeigth: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(imageView)
        }
    }
    
    // MARK: - Scrollview delegate methods...
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeigth.constant = scrollView.contentSize.height
        scrollViewWidth.constant = scrollView.contentSize.width
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
