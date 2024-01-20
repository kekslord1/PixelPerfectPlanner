//
//  extensions.swift
//  PixelPerfectPlanner
//
//  Created by Philipp Haug on 21.01.24.
//

import UIKit

extension UIResponder {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            } else {
                return nextResponder.findViewController()
            }
        }
        return nil
    }
}

