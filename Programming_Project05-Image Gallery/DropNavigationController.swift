//
//  DropNavigationController.swift
//  Programming_Project05-Image Gallery
//
//  Created by Michel Deiman on 19/01/2018.
//  Copyright © 2018 Michel Deiman. All rights reserved.
//

import UIKit

class DropNavigationController: UINavigationController, UIDropInteractionDelegate {

    override func viewDidLoad() {
//        navigationBar.addInteraction(UIDropInteraction(delegate: self))
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .move)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: UIImage.self) { (providers) in
            let dropPoint = session.location(in: self.navigationBar)
//            for attributedString in providers as? [NSAttributedString] ?? [] {
//                self.addLabel(with: attributedString, centeredAt: dropPoint)
//            }
        }
    }
    
    
    

}
