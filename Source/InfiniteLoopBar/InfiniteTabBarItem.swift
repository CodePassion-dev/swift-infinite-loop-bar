//
//  InfiniteTabBarItem.swift
//  Swift Infinite Loop Bar
//
//  Created by Huy Duong on 3/17/19.
//  Copyright © 2019 Huy Duong. All rights reserved.
//

import UIKit

class InfiniteTabBarItem: UIView {
    
    // MARK: - Public Properties
    
    var backgroundImage: UIImage? {
        get {
            return self.backgroundImage
        }
        set(backgroundImage) {
            if backgroundImage != nil {
                backgroundImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
                if backgroundImageView != nil, containerView != nil {
                    insertSubview(backgroundImageView!, belowSubview: containerView!)
                }
                self.backgroundImage = backgroundImage
                backgroundImageView?.contentMode = .scaleAspectFill
                backgroundImageView?.image = self.backgroundImage
            } else {
                self.backgroundImage = nil
                backgroundImageView?.removeFromSuperview()
                backgroundImageView = nil
            }
        }
    }
    //* The font of the titles. When changing the font, the font size should be left at the default size (7.0)
    var titleFont: UIFont? {
        get {
            return self.titleFont
        }
        set(titleFont) {
            self.titleFont = titleFont
            titleLabel?.font = self.titleFont
        }
    }
    //* The image that is overlayed onto the icon when it is selected. This should be the same size as the icon.
    var selectedIconOverlayImage: UIImage?
    //* The tint color that is overlayed onto the icon when it is selected. This will show if the `selectedIconOverlayImage` is `nil`.
    var selectedIconTintColor: UIColor?
    //* The image that is overlayed onto the icon when it is unselected. This should be the same size as the icon.
    var unselectedIconOverlayImage: UIImage?
    //* The tint color that is overlayed onto the icon when it is unselected. This will show if the `unselectedIcoOverlayImage` is 'nil`.
    var unselectedIconTintColor: UIColor?
    //*The image that is overlayed onto the icon when the tab requires user attention.
    var attentionIconOverlayImage: UIImage?
    //*The tint color that is overlayed onto the icon the tab requires user attention.
    var attentionIconTintColor: UIColor?
    //* The color of the title text when the item is selected.
    var selectedTitleColor: UIColor?
    //* The color of the title text when the item is unselected.
    var unselectedTitleColor: UIColor?
    //* The color of the icon text when the tab requires user attention.
    var attentionTitleColor: UIColor?
    
    
    // MARK: - Private Properties
    
    var selected = false
    private let SCREEN_WIDTH = UIScreen.main.bounds.size.width
    private var containerView: UIView?
    private var titleLabel: UILabel?
    var requiresAttention: Bool = false
    private var backgroundImageView: UIImageView?
    

    // MARK: - Initialize
    
    init(title: String) {
        let frame = (UIDevice.current.userInterfaceIdiom == .phone) ? CGRect(x: 0, y: 10, width: SCREEN_WIDTH / 5, height: 50) : CGRect(x: 0, y: 10, width: 768.0 / 11.0, height: 50)
        super.init(frame: frame)
        //Container view to handle rotations
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        containerView?.backgroundColor = UIColor.clear
        
        //Set default properties
        let selectedColor = UIColor(red: 3.0 / 255.0, green: 207.0 / 255.0, blue: 91.0 / 255.0, alpha: 1.0)
        let unselectedColor = UIColor(red: 201.0 / 255.0, green: 201.0 / 255.0, blue: 201.0 / 255.0, alpha: 1.0)
        backgroundColor = UIColor.clear
        unselectedTitleColor = unselectedColor
        selectedTitleColor = selectedColor
        attentionTitleColor = selectedColor
        unselectedIconTintColor = unselectedColor
        selectedIconTintColor = selectedColor
        attentionIconTintColor = selectedColor
        
        //Create Text Label
        titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        titleLabel?.text = title
        titleLabel?.textColor = unselectedTitleColor
        titleLabel?.backgroundColor = UIColor.clear
        titleLabel?.textAlignment = .center
        titleFont = UIFont(name: "HelveticaNeue-Medium", size: 14.0)
        titleLabel?.font = titleFont
        if let titleLabel = titleLabel {
            containerView?.addSubview(titleLabel)
        }
        if let containerView = containerView {
           addSubview(containerView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //Only layout if we are the identity. Otherwise we get issues, espically when we are not scrolling.
        if containerView?.transform.isIdentity == true {
            containerView?.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            titleLabel?.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        }
    }
    
    
    // MARK: - Public Methods
    
    func setSelected(_ selected: Bool) {
        self.selected = selected
        if self.selected {
            titleLabel?.textColor = selectedTitleColor
            titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 14.0)
        } else {
            titleLabel?.textColor = unselectedTitleColor
            titleLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 14.0)
        }
    }

    
    /** Duplicate a `InfiniteTabBarItem`. */
    func copy() -> InfiniteTabBarItem? {
        
        let item = InfiniteTabBarItem(title: titleLabel?.text ?? "")
        item.backgroundImage = backgroundImage
        item.titleFont = titleFont
        item.selectedIconOverlayImage = selectedIconOverlayImage
        item.selectedIconTintColor = selectedIconTintColor
        item.unselectedIconOverlayImage = unselectedIconOverlayImage
        item.unselectedIconTintColor = unselectedIconTintColor
        item.attentionIconOverlayImage = attentionIconOverlayImage
        item.attentionIconTintColor = attentionIconTintColor
        item.selectedTitleColor = selectedTitleColor
        item.unselectedTitleColor = unselectedTitleColor
        item.attentionTitleColor = attentionTitleColor
        item.selected = selected
        item.setRequiresUserAttention(requiresAttention)
        if containerView != nil {
            let itemContainerView = item.subviews[0]
            itemContainerView.transform = containerView!.transform
        }

        return item
    }
    
    
    /** Rotate the item to the given angle.
     @warning This should only be used by `M13InfiniteTabBar`, using this method will result in unexpected behavior. Rotation of the items is handled by `M13InfiniteTabBar`.
     @param angle   The angle to rotate the item to. */
    func rotate(toAngle angle: CGFloat) {
        containerView?.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    
    /** Used to set wether the view controller the tab represents requires user attention.
     @warning This should only be used by `M13InfiniteTabBar`, using this method will result in unexpected behavior. If you want a tab to ask for user attention, go through `M13InfinteTabBar`.
     @param requiresAttention    Wether or not the tab should display that it requires user attention.*/
    func setRequiresUserAttention(_ requiresAttention: Bool) {
        self.requiresAttention = requiresAttention
    }

}
