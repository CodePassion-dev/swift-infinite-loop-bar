//
//  InfiniteTabBarExtension.swift
//  Swift Infinite Loop Bar
//
//  Created by Huy Duong on 3/17/19.
//  Copyright © 2019 Huy Duong. All rights reserved.
//

import Foundation

// https://viblo.asia/p/associated-objects-trong-swift-maGK7LkBZj2

extension InfiniteTabBarController {
    
    var infiniteTabBarItem: InfiniteTabBarItem? {
        /**Get the infinite tab bar item for the view controller.
         @return The infinite tab bar item for the view controller.*/
        get {
            if let item = objc_getAssociatedObject(self, "infiniteTabBarItemObject") as? InfiniteTabBarItem {
                return item
            }
            return nil
        }
        
        /**Set the infinite tab bar item for the view controller.
         @param item The new tab bar item for the view controller.*/
        set {
            objc_setAssociatedObject(self, "infiniteTabBarItemObject", newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var infiniteTabBarController: InfiniteTabBarController? {
        /**Get the infinite tab bar controller for the view controller.
         @return The infinite tab bar controller for the view controller.*/
        get {
//            if let viewController = objc_getAssociatedObject(self, #selector(self.setInfiniteTabBarItem(_:))) {
//                return viewController
//            }
            if let viewController = objc_getAssociatedObject(self, "infiniteTabBarControllerObject") as? InfiniteTabBarController {
                return viewController
            }
            return nil
        }
        
        /**Set the infinite tab bar controller for the view controller.
         @param controller The new tab bar controller for the view controller.*/
        set {
//            objc_setAssociatedObject(self, #selector(self.setInfiniteTabBarItem(_:)), controller, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, "infiniteTabBarControllerObject", newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}




