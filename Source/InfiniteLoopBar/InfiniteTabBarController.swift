//
//  InfiniteTabBarController.swift
//  Swift Infinite Loop Bar
//
//  Created by Huy Duong on 3/17/19.
//  Copyright © 2019 Huy Duong. All rights reserved.
//

import UIKit

//* Delegate to respond to changes occuring in `InfiniteTabBarController`
protocol InfiniteTabBarControllerDelegate: class {
    func infiniteTabBarControllerRequestingViewControllers(toDisplay tabBarController: InfiniteTabBarController?) -> [Any]?
    func infiniteTabBarController(_ tabBarController: InfiniteTabBarController?, shouldSelectViewContoller viewController: UIViewController?) -> Bool
    func infiniteTabBarController(_ tabBarController: InfiniteTabBarController?, didSelect viewController: UIViewController?)
}

class InfiniteTabBarController: UIViewController, InfiniteTabBarDelegate {
    
    // MARK: - Public Properties
    enum InfiniteTabBarPosition : Int {
        case bottom
        case top
    }
    
    //* Responds to `InfiniteTabBarController`'s delegate methods.
    weak var delegate: InfiniteTabBarControllerDelegate?
    //* The `InfiniteTabBar` instance the controller is controlling. This property is accessable to allow apperance customization.
    private(set) var infiniteTabBar: InfiniteTabBar?
    //* The view controller list that the infinite tab bar displays.
    var viewControllers: [InfiniteTabBarController] = []
    //* If set to YES, and the number of tabs is greater than minimumNumberOfTabsForScrolling, the tab bar will scroll infinitly. If set to no, the tab bar will still scroll, but not scroll infinitly.
    var enableInfiniteScrolling = false
    //*The location that the tab bar is pinned. The bar can be pinned to the top or bottom. Default is the bottom.
    var tabBarPosition: InfiniteTabBarPosition?
    //* The selected `UIViewController` instance.
    var selectedViewController: InfiniteTabBarController? {
        get {
            return self.selectedViewController
        }
        set(selectedViewController) {
            if let selectedViewController = self.selectedViewController,
                let index = viewControllers.index(of: selectedViewController) {
                selectedIndex = index
            }
        }
    }
    //* The index of the selected `UIViewController
    var selectedIndex: Int {
        get {
            return self.selectedIndex
        }
        set(selectedIndex) {
            infiniteTabBar?.selectItem(at: selectedIndex)
            infiniteTabBar?.item(tabBarItems[selectedIndex], requiresUserAttention: false)
        }
    }

    
    //*Wether or not the tab bar controller automatically sets the selected tab's importance level to 0.
    var automaticallySetsSelectedTabImportanceLevelToZero = false
    //* The background color of the tab bar
    var tabBarBackgroundColor: UIColor?
    //* The background that notifies the user that an off screen tab requires user attention.
    var requiresAttentionBackgroundView: InfiniteTabBarRequiresAttentionBackgroundView? {
        get {
            return self.requiresAttentionBackgroundView
        }
        set(newValue) {
            self.requiresAttentionBackgroundView = newValue
        }
    }

    
    
    // MARK: - Private Properties
    private var isCentralViewControllerOpen = false
    private var maskView: UIView?
    private var contentView: UIView?
    private var tabBarItems: [InfiniteTabBarItem] = []
    private var borderLayer: CAShapeLayer?
    private var indiciesRequiringAttention: [AnyHashable : Any] = [:]
    private var viewDidLoadOccur = false
    private var numberOfItemsForScrolling: Int = 0
    
    
    // MARK: - Initialize
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        enableInfiniteScrolling = true
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init?(viewControllers: [InfiniteTabBarController]?, pairedWithInfiniteTabBarItems items: [InfiniteTabBarItem]?) {
        self.init()
        tabBarItems = items ?? []
        self.viewControllers = viewControllers ?? []
        enableInfiniteScrolling = true
    }

    convenience init?(viewControllers: [InfiniteTabBarController]?) {
        self.init()
        self.viewControllers = viewControllers ?? []
        enableInfiniteScrolling = true
        var array: [InfiniteTabBarItem] = []
        for vc in (viewControllers ?? []) {
            if let infiniteTabBarItem = vc.infiniteTabBarItem {
                array.append(infiniteTabBarItem)
            }
        }
        tabBarItems = array
    }
    

    func setDelegate(_ delegate: InfiniteTabBarControllerDelegate?) {
        self.delegate = delegate
        //Only update view controllers on initial delegate setting.
        if viewControllers.count == 0 {
            if let tabViewControllers = self.delegate?.infiniteTabBarControllerRequestingViewControllers(toDisplay: self) as? [InfiniteTabBarController] {
                //Get the view controllers
                viewControllers = tabViewControllers
                //Get the tab bar items
                var tempTabBarItems: [InfiniteTabBarItem] = []
                for vc in viewControllers {
                    if let infiniteTabBarItem = vc.infiniteTabBarItem {
                        tempTabBarItems.append(infiniteTabBarItem)
                    }
                }
                tabBarItems = tempTabBarItems
            }
            setup()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewDidLoadOccur = true
        
        if (viewControllers.count == 0) && (delegate != nil) {
            
            if let tabViewControllers = delegate?.infiniteTabBarControllerRequestingViewControllers(toDisplay: self) as? [InfiniteTabBarController] {
                
                //Get the view controllers
                viewControllers = tabViewControllers
                //Get the tab bar items
                var tempTabBarItems: [InfiniteTabBarItem] = []
                for vc in viewControllers {
                    if let infiniteTabBarItem = vc.infiniteTabBarItem {
                        tempTabBarItems.append(infiniteTabBarItem)
                    }
                }
                tabBarItems = tempTabBarItems
            }
        }
        
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedViewController?.viewWillAppear(animated)
        
        //Update mask
        handleInterfaceChange(nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedViewController?.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectedViewController?.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        selectedViewController?.viewDidDisappear(animated)
    }
    
    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Public Methods

    /**Set that the `UIViewController` at the given index requires or does not require user attention.
     @param index The index that requires user attention.
     @param importanceLevel The level of attention the `UIViewController` at the given index requires*/
    func viewController(at index: Int, requiresUserAttentionWithImportanceLevel importanceLevel: Int) {
        infiniteTabBar?.item(tabBarItems[index], requiresUserAttention: (importanceLevel > 0))
        
        if importanceLevel > 0 {
            indiciesRequiringAttention[NSNumber(value: UInt(index))] = NSNumber(value: importanceLevel)
        } else {
            indiciesRequiringAttention.removeValue(forKey: NSNumber(value: UInt(index)))

        }
        
        resetRequiresAttentionBackgroundView()
    }

    
    /**Set that the given `UIViewController` requires or does not require user attention.
     @param viewController The view controller that requires user attention.
     @param importanceLevel The level of attention the given `UIViewController`requires*/
    func viewController(_ viewController: UIViewController?, requiresUserAttentionWithImportanceLevel importanceLevel: Int) {
        if let viewController = viewController as? InfiniteTabBarController,
            let index = viewControllers.index(of: viewController) {
            self.viewController(at: index, requiresUserAttentionWithImportanceLevel: importanceLevel)
        }
    }
    
    
    // MARK: - Actions
    
    
    // MARK: - Private Methods
    
    func setup() {
        
        //All the frames here are temporary. They will be layed out during handleInterfaceChange:
        if viewDidLoadOccur && viewControllers.count > 0 {
            view.backgroundColor = UIColor.white
            
            //create content view to hold view controllers
            
            //create content view to hold view controllers
            contentView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height - 50.0))
            contentView?.backgroundColor = UIColor.white
            contentView?.clipsToBounds = true
            
            //Determine if we have scrolling
            numberOfItemsForScrolling = (UIDevice.current.userInterfaceIdiom == .phone) ? 2 : 15
            
            //Set up the selection
            selectedIndex = (UIDevice.current.userInterfaceIdiom == .phone) ? 2 : 5
            
            //No Scrolling, select first item.
            if viewControllers.count < numberOfItemsForScrolling {
                selectedIndex = 0
            } else {
                //Rotate the view controllers and tab bar items, so the center tab is the first one
                var tempViewControllers: [InfiniteTabBarController] = []
                var tempTabBarItems: [InfiniteTabBarItem] = []
                for i in Int(viewControllers.count) - Int(selectedIndex)..<viewControllers.count - selectedIndex + viewControllers.count {
                    let j: Int = i % viewControllers.count
                    tempViewControllers.append(viewControllers[j])
                    tempTabBarItems.append(tabBarItems[j])
                }
                tabBarItems = tempTabBarItems
                viewControllers = tempViewControllers
            }
            
            //Set selected view controller
            selectedViewController = viewControllers[selectedIndex]
            
            //initalize the tab bar
            infiniteTabBar = InfiniteTabBar(infiniteTabBarItems: tabBarItems)
            infiniteTabBar?.minimumNumberOfTabsForScrolling = numberOfItemsForScrolling
            infiniteTabBar?.tabBarDelegate = self
            infiniteTabBar?.enableInfiniteScrolling = enableInfiniteScrolling
            indiciesRequiringAttention = [AnyHashable : Any]()
            
            //Create mask for tab bar
            maskView = UIView(frame: CGRect(x: 0, y: view.frame.size.height - 60.0, width: view.frame.size.width, height: 80.0))

            //Apply iOS 7 style border
            borderLayer = CAShapeLayer()
            borderLayer?.lineWidth = 1.0
            borderLayer?.strokeColor = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1).cgColor
            
            //Combine views
            if tabBarBackgroundColor == nil {
                tabBarBackgroundColor = UIColor.white
            }
            maskView?.backgroundColor = tabBarBackgroundColor
            
            if let maskView = maskView {
                view.addSubview(maskView)
            }
            if let infiniteTabBar = infiniteTabBar {
                maskView?.addSubview(infiniteTabBar)
            }
            if let contentView = contentView {
                view.addSubview(contentView)
            }
            if let borderLayer = borderLayer {
                view.layer.addSublayer(borderLayer)
            }

            //Add user interaction view if not added to superview. This is for when the attention view is set before the view appears.
//            if (requiresAttentionBackgroundView != nil) && requiresAttentionBackgroundView?.superview == nil {
//                self.requiresAttentionBackgroundView = requiresAttentionBackgroundView
//            }
            automaticallySetsSelectedTabImportanceLevelToZero = true
            
            //Catch rotation changes for tabs
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleInterfaceChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)

            //Set the inifinite tab bar controller for each view controller.
            for vc in viewControllers {
                vc.infiniteTabBarController = self
            }
            
            selectedViewController?.view.frame = CGRect(x: 0, y: 0, width: contentView?.frame.size.width ?? 0.0, height: contentView?.frame.size.height ?? 0.0)
            selectedViewController?.view.contentScaleFactor = UIScreen.main.scale
            if let view = selectedViewController?.view {
                contentView?.addSubview(view)
            }

            //Update mask
            handleInterfaceChange(nil)

        }
        
    }
    
    
    //Handle rotating all view controllers
    @objc func handleInterfaceChange(_ notification: Notification?) {
        //If notification is nil, we manually called for a redraw
        guard selectedViewController?.shouldAutorotate == true || notification == nil else {
            return
        }
        
        var orientation: UIDeviceOrientation = UIDevice.current.orientation
        
        //If face down, face up, or unknow, force portrait, otherwise no triangle will be drawn
        if !orientation.isPortrait && !orientation.isLandscape {
            orientation = .portrait
        }
        
        //check to see if we should rotate, and set proper rotation values for animation
        var angle: CGFloat = 0.0
        var interfaceOrientation: UIInterfaceOrientation = .portrait
        var go: Bool = false
        if let mask: UIInterfaceOrientationMask = selectedViewController?.supportedInterfaceOrientations {
            if ((mask == .portrait || mask == .allButUpsideDown || mask == .all) && orientation == .portrait) {
                go = true
            } else if ((mask == .landscape || mask == .landscapeLeft || mask == .allButUpsideDown || mask == .all) && orientation == .landscapeLeft) {
                go = true
                angle = (CGFloat.pi/2)
                interfaceOrientation = UIInterfaceOrientation.landscapeRight
            } else if ((mask == .portraitUpsideDown || mask == .allButUpsideDown || mask == .all) && orientation == .portraitUpsideDown) {
                go = true
                angle = CGFloat.pi
                interfaceOrientation = UIInterfaceOrientation.portraitUpsideDown
            } else if ((mask == .landscape || mask == .landscapeRight || mask == .allButUpsideDown || mask == .all) && orientation == .landscapeRight) {
                go = true
                angle = -(CGFloat.pi/2)
                interfaceOrientation = UIInterfaceOrientation.landscapeLeft
            }
        }
        
        //Update frames
        if go == true {
            //Start Animation
            UIView.beginAnimations("HandleInterfaceChange", context: nil)
            UIView.setAnimationDuration(0.5)
            UIView.setAnimationDelegate(self)
            
            let totalSize: CGSize = UIScreen.main.bounds.size
            
            //Selection line indicator
            let lineIndicatorView: UIView? = UIImageView(frame: CGRect.zero)
            lineIndicatorView?.backgroundColor = UIColor(red: 3.0 / 255.0, green: 207.0 / 255.0, blue: 91.0 / 255.0, alpha: 1.0)
            lineIndicatorView?.translatesAutoresizingMaskIntoConstraints = false
            if let lineIndicatorView = lineIndicatorView {
                maskView?.addSubview(lineIndicatorView)
            }
            if let lineIndicatorView = lineIndicatorView {
                view.bringSubviewToFront(lineIndicatorView)
            }
            
            lineIndicatorView?.widthAnchor.constraint(equalToConstant: totalSize.width / 5).isActive = true
            lineIndicatorView?.heightAnchor.constraint(equalToConstant: 3).isActive = true
            lineIndicatorView?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            if maskView != nil {
                lineIndicatorView?.bottomAnchor.constraint(equalTo: maskView!.bottomAnchor, constant: -20).isActive = true
            }
            
            //Rotate tab bar items
            infiniteTabBar?.rotateItems(to: orientation)
            let triangleDepth: CGFloat = 0.0
            
            //Global values
            var tempFrame = CGRect.zero
            
            if interfaceOrientation == .portrait {
                //Code that needs to be separate based on top or bottom
                if tabBarPosition == .bottom {
                    tempFrame = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 50.0)
                    maskView?.frame = CGRect(x: 0, y: totalSize.height - 50.0 - triangleDepth, width: maskView?.frame.size.width ?? 0, height: maskView?.frame.size.height ?? 0)
                } else {
                    tempFrame = CGRect(x: 0, y: 65, width: totalSize.width, height: totalSize.height - 65.0)
                    maskView?.frame = CGRect(x: 0, y: 5, width: maskView?.frame.size.width ?? 0, height: maskView?.frame.size.height ?? 0)
                }
                
                contentView?.frame = tempFrame
                selectedViewController?.view.frame = CGRect(x: 0, y: 0, width: tempFrame.size.width, height: tempFrame.size.height)
                infiniteTabBar?.frame = CGRect(x: 0, y: 0, width: infiniteTabBar?.frame.size.width ?? 0, height: infiniteTabBar?.frame.size.height ?? 0)
                
                //Rotate the child view controller if it supports the orientation
                if selectedViewController?.supportedInterfaceOrientations == .all || selectedViewController?.supportedInterfaceOrientations == .allButUpsideDown || selectedViewController?.supportedInterfaceOrientations == .portrait {
                    //Rotate View Bounds
                    selectedViewController?.view.transform = CGAffineTransform(rotationAngle: angle)
                    selectedViewController?.view.bounds = CGRect(x: 0, y: 0, width: tempFrame.size.width, height: tempFrame.size.height)
                }
            } else if interfaceOrientation == .portraitUpsideDown {
                if tabBarPosition == .bottom {
                    tempFrame = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 70.0)
                    maskView?.frame = CGRect(x: 0, y: totalSize.height - 70.0 - triangleDepth, width: maskView?.frame.size.width ?? 0, height: maskView?.frame.size.height ?? 0)
                } else {
                    tempFrame = CGRect(x: 0, y: 50, width: totalSize.width, height: totalSize.height - 50.0)
                    maskView?.frame = CGRect(x: 0, y: -10, width: maskView?.frame.size.width ?? 0, height: maskView?.frame.size.height ?? 0)
                }
                
                contentView?.frame = tempFrame
                selectedViewController?.view.frame = CGRect(x: 0, y: 0, width: tempFrame.size.width, height: tempFrame.size.height)
                infiniteTabBar?.frame = CGRect(x: 0, y: 0, width: infiniteTabBar?.frame.size.width ?? 0, height: infiniteTabBar?.frame.size.height ?? 0)
                
                //If the child view controller supports this interface orientation.
                if selectedViewController?.supportedInterfaceOrientations == .all || selectedViewController?.supportedInterfaceOrientations == .portraitUpsideDown {
                    //Rotate View Bounds
                    selectedViewController?.view.transform = CGAffineTransform(rotationAngle: angle)
                    selectedViewController?.view.bounds = CGRect(x: 0, y: 0, width: tempFrame.size.width, height: tempFrame.size.height)
                }
                
            } else if interfaceOrientation == .landscapeLeft {
                if tabBarPosition == .bottom {
                    tempFrame = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 50.0)
                    maskView?.frame = CGRect(x: 0, y: totalSize.height - 50.0 - triangleDepth, width: maskView?.frame.size.width ?? 0, height: maskView?.frame.size.height ?? 0)
                } else {
                    tempFrame = CGRect(x: 0, y: 50.0, width: totalSize.width, height: totalSize.height - 50.0)
                    maskView?.frame = CGRect(x: 0, y: -10, width: maskView?.frame.size.width ?? 0, height: maskView?.frame.size.height ?? 0)
                }
                
                contentView?.frame = tempFrame
                selectedViewController?.view.frame = CGRect(x: 0, y: 0, width: tempFrame.size.width, height: tempFrame.size.height)
                infiniteTabBar?.frame = CGRect(x: 0, y: 0, width: infiniteTabBar?.frame.size.width ?? 0, height: infiniteTabBar?.frame.size.height ?? 0)
                
                //If the child view controller supports this interface orientation
                if selectedViewController?.supportedInterfaceOrientations == .all || selectedViewController?.supportedInterfaceOrientations == .allButUpsideDown || selectedViewController?.supportedInterfaceOrientations == .landscape || selectedViewController?.supportedInterfaceOrientations == .landscapeRight {
                    //Rotate View Bounds
                    selectedViewController?.view.transform = CGAffineTransform(rotationAngle: angle)
                    selectedViewController?.view.bounds = CGRect(x: 0, y: 0, width: tempFrame.size.height, height: tempFrame.size.width)
                }
            } else if interfaceOrientation == .landscapeRight {
                if tabBarPosition == .bottom {
                    tempFrame = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 50.0)
                    maskView?.frame = CGRect(x: 0, y: totalSize.height - 50.0 - triangleDepth, width: maskView?.frame.size.width ?? 0, height: maskView?.frame.size.height ?? 0)
                } else {
                    tempFrame = CGRect(x: 0, y: 50, width: totalSize.width, height: totalSize.height - 50.0)
                    maskView?.frame = CGRect(x: 0, y: -10, width: maskView?.frame.size.width ?? 0, height: maskView?.frame.size.height ?? 0)
                }
                
                contentView?.frame = tempFrame
                infiniteTabBar?.frame = CGRect(x: 0, y: 0, width: infiniteTabBar?.frame.size.width ?? 0, height: infiniteTabBar?.frame.size.height ?? 0)
                selectedViewController?.view.frame = CGRect(x: 0, y: 0, width: tempFrame.size.width, height: tempFrame.size.height)
                
                //If the child view controller supports this interface orientation
                if selectedViewController?.supportedInterfaceOrientations == .all || selectedViewController?.supportedInterfaceOrientations == .allButUpsideDown || selectedViewController?.supportedInterfaceOrientations == .landscape || selectedViewController?.supportedInterfaceOrientations == .landscapeLeft {
                    //Rotate View Bounds
                    selectedViewController?.view.transform = CGAffineTransform(rotationAngle: angle)
                    selectedViewController?.view.bounds = CGRect(x: 0, y: 0, width: tempFrame.size.height, height: tempFrame.size.width)
                }
            }
            
            //Create the mask for the content view
            let maskLayer = CAShapeLayer()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0), transform: .identity) //Top left
            if tabBarPosition == .top && viewControllers.count >= numberOfItemsForScrolling {
                //Add the triangle
                path.addLine(to: CGPoint(x: (tempFrame.size.width / 2.0) - triangleDepth, y: 0), transform: .identity)
                path.addLine(to: CGPoint(x: tempFrame.size.width / 2.0, y: triangleDepth), transform: .identity)
                path.addLine(to: CGPoint(x: (tempFrame.size.width / 2.0) + triangleDepth, y: 0), transform: .identity)
            }
            path.addLine(to: CGPoint(x: tempFrame.size.width, y: 0), transform: .identity) //Top Right
            path.addLine(to: CGPoint(x: tempFrame.size.width, y: tempFrame.size.height), transform: .identity) //Bottom Right
            if tabBarPosition == .bottom && viewControllers.count >= numberOfItemsForScrolling {
                //Add the triangle
                path.addLine(to: CGPoint(x: (tempFrame.size.width / 2.0) + triangleDepth, y: tempFrame.size.height), transform: .identity)
                path.addLine(to: CGPoint(x: tempFrame.size.width / 2.0, y: tempFrame.size.height - triangleDepth), transform: .identity)
                path.addLine(to: CGPoint(x: (tempFrame.size.width / 2.0) - triangleDepth, y: tempFrame.size.height), transform: .identity)
            }
            path.addLine(to: CGPoint(x: 0, y: tempFrame.size.height), transform: .identity) //Bottom LEft
            path.closeSubpath() //Close
            maskLayer.path = path
            contentView?.layer.mask = maskLayer
            
            //Complete animations
            UIView.commitAnimations()
        }
        
    }
    
    func setTabBarBackgroundColor(_ tabBarBackgroundColor: UIColor?) {
        maskView?.backgroundColor = tabBarBackgroundColor
        self.tabBarBackgroundColor = tabBarBackgroundColor
    }
    
    func setRequiresAttentionBackgroundView(_ requiresAttentionBackgroundView: InfiniteTabBarRequiresAttentionBackgroundView?) {
        if requiresAttentionBackgroundView == nil {
            self.requiresAttentionBackgroundView?.removeFromSuperview()
        } else {
            requiresAttentionBackgroundView?.frame = CGRect(x: 0, y: 10, width: UIScreen.main.bounds.size.width, height: 50)
            if let requiresAttentionBackgroundView = requiresAttentionBackgroundView,
                infiniteTabBar != nil {
                maskView?.insertSubview(requiresAttentionBackgroundView, belowSubview: infiniteTabBar!)
            }
        }
        self.requiresAttentionBackgroundView = requiresAttentionBackgroundView
    }
    
    
    func resetRequiresAttentionBackgroundView() {
        
        guard requiresAttentionBackgroundView == nil else {
            return
        }
        //Create the search array
        var searchArray: [Int] = []
        for i in Int(selectedIndex) + 1...Int(viewControllers.count) + Int(selectedIndex) - 1 {
            searchArray.append(i % viewControllers.count)
        }
        
        //Figure out the maximum importance level for each side
        var leftImportanceLevel: Int = 0
        var rightImportanceLevel: Int = 0
        
        
        
        for index in indiciesRequiringAttention.keys {
            //The selected index will return NSNotFound
            if let indexInt = index.base as? Int,
                !(indexInt == selectedIndex) {
                //Find the indesx in the search array
//                var indexSearchArray: Int = searchArray.index(of: indexInt, in: NSRange(location: 0, length: viewControllers.count - 1))
                let indexSearchArray: Int = searchArray.firstIndex(of: indexInt) ?? 0
                let leftDistance: Int = searchArray.count - indexSearchArray
                let rightDistance: Int = indexSearchArray + 1
                let minDistance: Int = (UIDevice.current.userInterfaceIdiom == .phone) ? 2 : 5
                if leftDistance < rightDistance && leftDistance > minDistance {
                    let tempImportanceLevel: Int = (indiciesRequiringAttention[index] as? NSNumber)?.intValue ?? 0
                    if tempImportanceLevel > leftImportanceLevel {
                        leftImportanceLevel = tempImportanceLevel
                    }
                } else if rightDistance < leftDistance && rightDistance > minDistance {
                    let tempImportanceLevel: Int = (indiciesRequiringAttention[index] as? NSNumber)?.intValue ?? 0
                    if tempImportanceLevel > rightImportanceLevel {
                        rightImportanceLevel = tempImportanceLevel
                    }
                }
            }
        }
        
        requiresAttentionBackgroundView?.showAnimationOnLeftEdge(withImportanceLevel: leftImportanceLevel)
        requiresAttentionBackgroundView?.showAnimationOnRightEdge(withImportanceLevel: rightImportanceLevel)

    }
    
    func setEnableInfiniteScrolling(_ enableInfiniteScrolling: Bool) {
        self.enableInfiniteScrolling = enableInfiniteScrolling
        infiniteTabBar?.enableInfiniteScrolling = self.enableInfiniteScrolling
    }
    
    func setTabBarPosition(_ tabBarPosition: InfiniteTabBarPosition) {
        self.tabBarPosition = tabBarPosition
        if viewControllers.count > 0 {
            handleInterfaceChange(nil)
        }
    }

    
    // MARK: - Delegate
    
    //Tab bar delegate
    func infiniteTabBar(_ tabBar: InfiniteTabBar?, shouldSelect item: InfiniteTabBarItem?) -> Bool {
        var should = true
        if let shouldValue = delegate?.infiniteTabBarController(self, shouldSelectViewContoller: viewControllers[item?.tag ?? 0]) {
            should = shouldValue
        }
        return should
    }

    func infiniteTabBar(_ tabBar: InfiniteTabBar?, didSelect item: InfiniteTabBarItem?) {
        //Clean up animation
        if (contentView?.subviews.count ?? 0) > 1 {
            let aView = contentView?.subviews[0]
            aView?.layer.opacity = 0.0
            aView?.removeFromSuperview()
        }
        
        delegate?.infiniteTabBarController(self, didSelect: viewControllers[item?.tag ?? 0])
        
        //Reset importance level if needed
        if automaticallySetsSelectedTabImportanceLevelToZero {
            //Remove the item for the selected tab, and redraw
            viewController(at: item?.tag ?? 0, requiresUserAttentionWithImportanceLevel: 0)
        } else {
            //Redo animation based off of what tabs are on screen.
            resetRequiresAttentionBackgroundView()
        }
    }
    
    func infiniteTabBar(_ tabBar: InfiniteTabBar?, willAnimateInViewControllerFor item: InfiniteTabBarItem?) {
        
        let newController = viewControllers[item?.tag ?? 0]
        
        //Return if its the selected view controller
        if newController == selectedViewController {
            return
        }
        
        //check to see if we should rotate, and set proper rotation values
        var angle: CGFloat = 0.0
        let interfaceOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        if let mask: UIInterfaceOrientationMask = selectedViewController?.supportedInterfaceOrientations {
            if ((mask == .portrait || mask == .allButUpsideDown || mask == .all) && interfaceOrientation == .portrait) {
            } else if ((mask == .landscape || mask == .landscapeLeft || mask == .allButUpsideDown || mask == .all) && interfaceOrientation == .landscapeLeft) {
                angle = -(CGFloat.pi/2)
            } else if ((mask == .portraitUpsideDown || mask == .all) && interfaceOrientation == .portraitUpsideDown) {
                angle = -(CGFloat.pi)
            } else if ((mask == .landscape || mask == .landscapeRight || mask == .allButUpsideDown || mask == .all) && interfaceOrientation == .landscapeRight) {
                angle = CGFloat.pi/2
            }
        }
        
        let totalSize: CGSize = UIScreen.main.bounds.size
        
        //Rotate Status Bar
        UIApplication.shared.statusBarOrientation = interfaceOrientation
        
        //Rotate tab bar items
        //Recreate mask and adjust frames to make room for status bar.
        if interfaceOrientation == .portrait {
            //Resize View
            newController.view.frame = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 50.0)
            
            //If the child view controller supports this orientation
            if newController.supportedInterfaceOrientations == .all || newController.supportedInterfaceOrientations == .allButUpsideDown || newController.supportedInterfaceOrientations == .portrait {
                //Rotate View Bounds
                newController.view.bounds = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 50.0)
                newController.view.transform = CGAffineTransform(rotationAngle: angle)
            }
        } else if interfaceOrientation == .portraitUpsideDown {
            //Resize View
            newController.view.frame = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 50)
            
            //If the child view controller supports this interface orientation.
            if newController.supportedInterfaceOrientations == .all || newController.supportedInterfaceOrientations == .portraitUpsideDown {
                //Rotate View Bounds
                newController.view.bounds = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 50.0)
                newController.view.transform = CGAffineTransform(rotationAngle: angle)
            }
        } else if interfaceOrientation == .landscapeLeft {
            //Resize View
            newController.view.frame = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 50.0)
            
            //If the child view controller supports this interface orientation
            if newController.supportedInterfaceOrientations == .all || newController.supportedInterfaceOrientations == .allButUpsideDown || newController.supportedInterfaceOrientations == .landscape || newController.supportedInterfaceOrientations == .landscapeLeft {
                //Rotate View Bounds
                newController.view.bounds = CGRect(x: 0, y: 0, width: totalSize.height - 50.0, height: totalSize.width)
                newController.view.transform = CGAffineTransform(rotationAngle: angle)
            }
        } else if interfaceOrientation == .landscapeRight {
            //Resize View
            newController.view.frame = CGRect(x: 0, y: 0, width: totalSize.width, height: totalSize.height - 50.0)
            
            //If the child view controller supports this interface orientation
            if newController.supportedInterfaceOrientations == .all || newController.supportedInterfaceOrientations == .allButUpsideDown || newController.supportedInterfaceOrientations == .landscape || newController.supportedInterfaceOrientations == .landscapeRight {
                //Rotate View Bounds
                newController.view.bounds = CGRect(x: 0, y: 0, width: totalSize.height - 50.0, height: totalSize.width)
                newController.view.transform = CGAffineTransform(rotationAngle: angle)
            }
        }
        
        //Set up for transition
        newController.view.layer.opacity = 0

    }
    
    func infiniteTabBar(_ tabBar: InfiniteTabBar?, animateInViewControllerFor item: InfiniteTabBarItem?) {
        if (viewControllers[item?.tag ?? 0] is UINavigationController) && item?.tag == selectedIndex {
            //Pop to root controller when tapped
            let controller = viewControllers[item?.tag ?? 0] as? UINavigationController
            controller?.popToRootViewController(animated: true)
        } else {
            let newController: InfiniteTabBarController = viewControllers[item?.tag ?? 0]
            if let view = newController.view {
                contentView?.addSubview(view)
            }
            newController.view.layer.opacity = 1.0
            selectedViewController = newController
            if let index = viewControllers.index(of: newController) {
                selectedIndex = index
            }
        }
    }
    
    
    
    
}
