//
//  InfiniteTabBar.swift
//  Swift Infinite Loop Bar
//
//  Created by Huy Duong on 3/17/19.
//  Copyright © 2019 Huy Duong. All rights reserved.
//

import UIKit

protocol InfiniteTabBarDelegate: class {
    func infiniteTabBar(_ tabBar: InfiniteTabBar?, didSelect item: InfiniteTabBarItem?)
    func infiniteTabBar(_ tabBar: InfiniteTabBar?, shouldSelect item: InfiniteTabBarItem?) -> Bool
    func infiniteTabBar(_ tabBar: InfiniteTabBar?, animateInViewControllerFor item: InfiniteTabBarItem?)
    func infiniteTabBar(_ tabBar: InfiniteTabBar?, willAnimateInViewControllerFor item: InfiniteTabBarItem?)
}

class InfiniteTabBar: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Public Properties
    
    var minimumNumberOfTabsForScrolling: Int = 0
    var enableInfiniteScrolling = false
    weak var tabBarDelegate: InfiniteTabBarDelegate?
    var selectedItem: InfiniteTabBarItem? {
        get {
            return self.selectedItem
        }
        set {
            if items.count >= minimumNumberOfTabsForScrolling {
                //Convert the item's frame to self
                var itemFrameInSelf: CGRect? = newValue?.frame
                itemFrameInSelf?.origin.x += (tabContainerView?.frame.origin.x ?? 0.0)
                
                //Check to see if it is the center item
                let itemFrameInSelfX = (itemFrameInSelf?.origin.x ?? 0.0)
                let frameWidth = (frame.size.width / 2.0)
                let itemFrameInSelfWidth = ((itemFrameInSelf?.size.width ?? 0.0) / 2.0)
                if contentOffset.x == itemFrameInSelfX - frameWidth + itemFrameInSelfWidth {
                    //Center tab tapped
                    scrollViewDidEndScrollingAnimation(self)
                } else {
                    //Other tab tapped
                    setContentOffset(CGPoint(x: itemFrameInSelfX + itemFrameInSelfWidth - frameWidth, y: 0), animated: true)
                }
            } else {
                //Regular tab bar
                select(selectedItem)
            }
        }
    }
    
    
    
    // MARK: - Private Properties
    
    private var singleTapGesture: UITapGestureRecognizer?
    private var tabContainerView: UIView?
    private var previousSelectedIndex: Int = 0
    private var visibleIcons: [InfiniteTabBarItem] = [] //Icons in the scrollview
    private var items: [InfiniteTabBarItem] = []
    private var scrollAnimationCheck = false
    
    
    // MARK: - Initialize
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init?(infiniteTabBarItems items: [Any]?) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 60))
        // Initialization code
        delegate = self
        contentSize = frame.size
        backgroundColor = UIColor.clear
        clipsToBounds = false
        enableInfiniteScrolling = true
        
        //Content size
        let itemsCount: CGFloat = CGFloat(items?.count ?? 0)
        let lastItemWidth: CGFloat = (items?.last as? InfiniteTabBarItem)?.frame.size.width ?? 0
        let width: CGFloat = CGFloat(itemsCount * lastItemWidth * 4) //Need to iterate 4 times for infinite animation
        contentSize = CGSize(width: width, height: frame.size.height)
        tabContainerView = UIView(frame: CGRect(x: 0, y: 10, width: contentSize.width, height: contentSize.height))
        tabContainerView?.backgroundColor = UIColor.clear
        tabContainerView?.isUserInteractionEnabled = false
        if let tabContainerView = tabContainerView {
            addSubview(tabContainerView)
        }

        //hide horizontal indicator so the recentering trick is not revealed
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        isUserInteractionEnabled = true
        
        //Add gesture for taps
        singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.singleTapGestureCaptured(_:)))
        singleTapGesture?.cancelsTouchesInView = false
        singleTapGesture?.delegate = self
        singleTapGesture?.delaysTouchesBegan = false
        if let singleTapGesture = singleTapGesture {
            addGestureRecognizer(singleTapGesture)
        }

        if let visibleIcons = [AnyHashable](repeating: 0, count: items?.count ?? 0) as? [InfiniteTabBarItem] {
            self.visibleIcons = visibleIcons
        }
        
        if let items = items as? [InfiniteTabBarItem] {
            self.items = items
        }
        
        //Reindex
        var tag: Int = 0
        for item in items as? [InfiniteTabBarItem] ?? [] {
            item.frame = CGRect(x: 2000.0, y: 10.0, width: item.frame.size.width, height: item.frame.size.height)
            item.tag = tag
            tag += 1
        }
        
        //Set Previous Index
        previousSelectedIndex = (UIDevice.current.userInterfaceIdiom == .phone) ? 2 : 5
        //Determine if we have scrolling
        let numberOfItemsForScrolling: Int = (UIDevice.current.userInterfaceIdiom == .phone) ? 2 : 15
        if self.items.count < numberOfItemsForScrolling {
            previousSelectedIndex = 0
        }
        selectedItem = self.items[previousSelectedIndex]
        (self.items[previousSelectedIndex]).selected = true
        
        //Setup tabs, if less than the scrolling amount
        if self.items.count < numberOfItemsForScrolling {
            visibleIcons = [InfiniteTabBarItem]()
            var tag: Int = 0
            for anItem in self.items {
                let item: InfiniteTabBarItem? = anItem.copy()
                item?.tag = tag
                anItem.tag = tag
                if let item = item {
                    visibleIcons.append(item)
                }
                tag += 1
            }
        }
        
        rotateItems(to: UIDevice.current.orientation)
    }
    
    
    //Retile content
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if items.count >= minimumNumberOfTabsForScrolling && enableInfiniteScrolling {
            //Infinite Scrolling
            recenterIfNecessary()
            
            // tile content in visible bounds
            let visibleBounds: CGRect = convert(bounds, to: tabContainerView)
            let minimumVisibleX = visibleBounds.minX
            let maximumVisibleX = visibleBounds.maxX
            
            tileLabels(fromMinX: minimumVisibleX, toMaxX: maximumVisibleX)
            
        } else if items.count >= minimumNumberOfTabsForScrolling && !enableInfiniteScrolling {
            //Infinte scrolling disabled.
            //Set the new content size, this should be the width of all the tab bar items, plus the width of the frame, so that we have width/2 padding on each side. So that the left and right most items can still reach the center.
            let itemWidth: CGFloat = (items.last)?.frame.size.width ?? 0.0
            contentSize = CGSize(width: (CGFloat(items.count) * itemWidth) + frame.size.width, height: frame.size.height)
            tabContainerView?.frame = CGRect(x: frame.size.width / 2.0, y: 10, width: contentSize.width, height: contentSize.height)
            var origin: CGFloat = 0.0
            for item in visibleIcons {
                item.frame = CGRect(x: origin, y: 0, width: itemWidth, height: item.frame.size.height)
                origin += itemWidth
                tabContainerView?.addSubview(item)
            }
        } else {
            //Scrolling Disabled
            //Basic Tab Bar
            //Reset content size of scroll view
            contentSize = frame.size
            tabContainerView?.frame = CGRect(x: 0, y: -10, width: frame.size.width, height: frame.size.height)
            //Manually lay out the tabs, no scrolling occuring
            let width: CGFloat = frame.size.width / CGFloat(items.count)
            var origin: CGFloat = 0
            for item in visibleIcons {
                item.frame = CGRect(x: origin, y: 0, width: width, height: item.frame.size.height)
                origin += width
                tabContainerView?.addSubview(item)
            }
        }
        
    }
    
    // MARK: - Public Methods
    
    func selectItem(at index: Int) {
        
        if index >= items.count {
            //Whoops, item doesn't exist.
            return
        }
        
        /*
         TODO: Fix selected item
         //Select the current item
         if index == selectedItem?.tag {
         selectedItem = selectedItem
         }
         */
        
        //Get the item at the given position in the tab bar. We will iterate from the left to the right, and look for the item with the same tag. Where will start depends on if we are infinite scrolling.
        let itemWidth = (items.last)?.frame.size.width
        //Calculate the offset of the number of tabs
        let offset = (itemWidth ?? 0.0) * CGFloat(index - (selectedItem?.tag ?? 0))
        //Scroll that amount, Auto selects item.
        setContentOffset(CGPoint(x: contentOffset.x + offset, y: contentOffset.y), animated: true)
    }

    
    func item(_ item: InfiniteTabBarItem?, requiresUserAttention requiresAttention: Bool) {
        for anItem in visibleIcons {
            if anItem.tag == item?.tag {
                anItem.setRequiresUserAttention(requiresAttention)
            }
        }
        
        for anItem in items {
            if anItem.tag == item?.tag {
                anItem.setRequiresUserAttention(requiresAttention)
            }
        }
    }
    
    //Handle icon rotation on device rotation
    func rotateItems(to orientation: UIDeviceOrientation) {
        var angle: CGFloat = 0
        if orientation == .landscapeRight {
            angle = -(CGFloat.pi/2)
        } else if orientation == .landscapeLeft {
            angle = CGFloat.pi/2
        } else if orientation == .portraitUpsideDown {
            angle = CGFloat.pi
        }
        for item in visibleIcons {
            item.rotate(toAngle: angle)
        }
        for item in items {
            item.rotate(toAngle: angle)
        }
    }
    
    
    // MARK: - Actions
    
    @objc func singleTapGestureCaptured(_ gesture: UITapGestureRecognizer?) {
        //Calculate the location in _tabBarContainer Coordinates
        var location: CGPoint = gesture?.location(in: nil) ?? CGPoint.zero
        location.x += contentOffset.x - (tabContainerView?.frame.origin.x ?? 0.0)
        
        if let item = self.item(atLocation: location) {
           selectedItem = item
        }
    }
    
    
    // MARK: - Private Methods
    
    //recenter peridocially to acheive the impression of infinite scrolling
    func recenterIfNecessary() {
        let currentOffset: CGPoint = contentOffset
        let contentWidth: CGFloat = contentSize.width
        let centerOffsetX: CGFloat = (contentWidth - bounds.size.width) / 2.0
        let distanceFromCenter = CGFloat(abs(Float(currentOffset.x - centerOffsetX)))
        
        if distanceFromCenter > (contentWidth / 4.0) {
            contentOffset = CGPoint(x: centerOffsetX, y: 0)
            
            // move content by the same amount so it appears to stay still
            for view in visibleIcons {
                if var center: CGPoint = tabContainerView?.convert(view.center, to: self) {
                    center.x += centerOffsetX - currentOffset.x
                    view.center = convert(center, to: tabContainerView)
                }
            }
        }
    }

    //Set wether or not we should scroll.
    func setEnableInfiniteScrolling(_ enableInfiniteScrolling: Bool) {
        self.enableInfiniteScrolling = enableInfiniteScrolling
        
        if self.enableInfiniteScrolling {
            //Enable infinite
            layoutSubviews()
        } else {
            //Disable infinite
            visibleIcons = [InfiniteTabBarItem]()
            var tag: Int = 0
            for anItem in items {
                let item: InfiniteTabBarItem? = anItem.copy()
                item?.tag = tag
                anItem.tag = tag
                if let item = item {
                    visibleIcons.append(item)
                }
                tag += 1
            }
            layoutSubviews()
            //center scroll view
            //Need to find the item that is shown, since that has the proper frame.
            if let tabContainerView = tabContainerView {
                var item: InfiniteTabBarItem? = nil
                for anItem in tabContainerView.subviews {
                    if let anItem = anItem as? InfiniteTabBarItem, anItem.tag == selectedItem?.tag {
                        item = anItem
                        break
                    }
                }
                selectedItem = item
            }
            
        }
        
    }
    
    
    //Tiling labels
    func placeNewLabel(onRight rightEdge: CGFloat) -> CGFloat {
        //Get item of next index
        let rightMostItem = visibleIcons.last
        let rightMostIndex = Int(rightMostItem?.tag ?? 0)
        var indexToInsert: Int = rightMostIndex + 1
        //Loop back if next index is past end of availableIcons
        if indexToInsert == items.count {
            indexToInsert = 0
        }
        let itemToInsert: InfiniteTabBarItem? = (items[indexToInsert]).copy()
        itemToInsert?.tag = indexToInsert
        if let itemToInsert = itemToInsert {
            visibleIcons.append(itemToInsert)
        }
        
        var frame: CGRect? = itemToInsert?.frame
        frame?.origin.x = rightEdge
        frame?.origin.y = 0
        itemToInsert?.frame = frame ?? CGRect.zero
        
        if let itemToInsert = itemToInsert {
            tabContainerView?.addSubview(itemToInsert)
        }
        
        return frame?.maxX ?? 0.0
    }

    
    func placeNewLabel(onLeft leftEdge: CGFloat) -> CGFloat {
        //Get item of next index
        let leftMostItem = visibleIcons[0]
        let leftMostIndex = Int(leftMostItem.tag)
        var indexToInsert: Int = leftMostIndex - 1
        //Loop back if next index is past end of availableIcons
        if indexToInsert == -1 {
            indexToInsert = Int(items.count) - 1
        }
        let itemToInsert: InfiniteTabBarItem? = (items[indexToInsert]).copy()
        itemToInsert?.tag = indexToInsert
        if let itemToInsert = itemToInsert {
            visibleIcons.insert(itemToInsert, at: 0)
        } // add leftmost label at the beginning of the array
        
        var frame: CGRect? = itemToInsert?.frame
        let frameWidth = frame?.size.width ?? 0.0
        frame?.origin.x = leftEdge - frameWidth
        frame?.origin.y = 0
        itemToInsert?.frame = frame ?? CGRect.zero
        
        if let itemToInsert = itemToInsert {
            tabContainerView?.addSubview(itemToInsert)
        }
        
        return frame?.minX ?? 0.0
    }
    
    
    func tileLabels(fromMinX minimumVisibleX: CGFloat, toMaxX maximumVisibleX: CGFloat) {
        // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
        // to kick off the tiling we need to make sure there's at least one label
        if visibleIcons.count == 0 {
            let itemToInsert: InfiniteTabBarItem? = (items[0]).copy()
            itemToInsert?.tag = 0
            if let itemToInsert = itemToInsert {
                visibleIcons.append(itemToInsert)
            }
            
            var frame: CGRect? = itemToInsert?.frame
            frame?.origin.x = minimumVisibleX
            frame?.origin.y = 0
            itemToInsert?.frame = frame ?? CGRect.zero
            
            if let itemToInsert = itemToInsert {
                tabContainerView?.addSubview(itemToInsert)
            }
        }
        
        // add labels that are missing on right side
        var lastItem = visibleIcons.last
        var rightEdge: CGFloat = lastItem?.frame.maxX ?? 0.0
        while rightEdge < maximumVisibleX {
            rightEdge = placeNewLabel(onRight: rightEdge)
        }
        
        // add labels that are missing on left side
        var firstItem = visibleIcons[0]
        var leftEdge: CGFloat = firstItem.frame.minX
        while leftEdge > minimumVisibleX {
            leftEdge = placeNewLabel(onLeft: leftEdge)
        }
        
        // remove labels that have fallen off right edge
        lastItem = visibleIcons.last
        while (lastItem?.frame.origin.x ?? 0) > maximumVisibleX {
            lastItem?.removeFromSuperview()
            visibleIcons.removeLast()
            lastItem = visibleIcons.last
        }
        
        // remove labels that have fallen off left edge
        firstItem = visibleIcons[0]
        while firstItem.frame.maxX < minimumVisibleX {
            firstItem.removeFromSuperview()
            visibleIcons.remove(at: 0)
            firstItem = visibleIcons[0]
        }
    }
    
    
    func item(atLocation theLocation: CGPoint) -> InfiniteTabBarItem? {
        //Get the subview at the location given
        if let subViews = tabContainerView?.subviews as? [InfiniteTabBarItem] {
            for subView in subViews {
                if subView.frame.contains(theLocation) {
                    return subView
                }
            }
        }
        
        //Since we didn't tap a view, find the closest tab to the selection point (we need to do this since if we rotate the tabs, there is empty space. Performing this calculation is simpler than changing the frame of every tab.
        var distance = CGFloat.greatestFiniteMagnitude
        var closestView: InfiniteTabBarItem?
        if let subViews = tabContainerView?.subviews as? [InfiniteTabBarItem] {
            for subView in subViews {
                if distance > distanceBetweenRect(subView.frame, andPoint: theLocation) {
                    distance = distanceBetweenRect(subView.frame, andPoint: theLocation)
                    closestView = subView
                }
            }
        }
        return closestView
    }
    
    func distanceBetweenRect(_ rect: CGRect, andPoint point: CGPoint) -> CGFloat {
        // first of all, we check if point is inside rect. If it is, distance is zero
        if rect.contains(point) {
            return 0.0
        }
        
        // next we see which point in rect is closest to point
        var closest: CGPoint = rect.origin
        if rect.origin.x + rect.size.width < point.x {
            closest.x += rect.size.width // point is far right of us
        } else if point.x > rect.origin.x {
            closest.x = point.x // point above or below us
        }
        if rect.origin.y + rect.size.height < point.y {
            closest.y += rect.size.height // point is far below us
        } else if point.y > rect.origin.y {
            closest.y = point.y // point is straight left or right
        }
        
        // we've got a closest point; now pythagorean theorem
        // distance^2 = [closest.x,y - closest.x,point.y]^2 + [closest.x,point.y - point.x,y]^2
        // i.e. [closest.y-point.y]^2 + [closest.x-point.x]^2
        let a: Float = powf(Float(closest.y - point.y), 2.0)
        let b: Float = powf(Float(closest.x - point.x), 2.0)
        return CGFloat(sqrtf(a + b))
    }
    
    
    func select(_ item: InfiniteTabBarItem?) {
        
        var shouldUpdate = true
        if let shouldUpdateValue = tabBarDelegate?.infiniteTabBar(self, shouldSelect: item) {
            shouldUpdate = shouldUpdateValue
        }
        
        if shouldUpdate {
            //Set the opacity of the new view controller to 0 before the animation starts
            tabBarDelegate?.infiniteTabBar(self, willAnimateInViewControllerFor: item)
            
            UIView.beginAnimations("TabChangedAnimation", context: nil)
            UIView.setAnimationDuration(0.5)
            UIView.setAnimationDelegate(self)
            
            //Swap Nav controllers
            tabBarDelegate?.infiniteTabBar(self, animateInViewControllerFor: item)
            
            //Change Tabs
            //Set selected highlight tab on every visible tab with tag, and the one in the available array to highlight all icons while scrolling
            item?.selected = true
            let hiddenItem = items[item?.tag ?? 0]
            hiddenItem.selected = true
            //Remove highlight on every other tab
            for temp in items {
                if temp.tag != item?.tag {
                    temp.selected = false
                }
            }
            for temp in visibleIcons {
                if temp.tag != item?.tag {
                    temp.selected = false
                }
            }
            
            previousSelectedIndex = item?.tag ?? 0
            selectedItem = item
            
            UIView.setAnimationDidStop(#selector(self.didSelectItem))
            UIView.commitAnimations()
            
        } else {
            
            if items.count >= minimumNumberOfTabsForScrolling {
                //Scroll Back to nearest tab with previous index
                var oldItem: InfiniteTabBarItem? = nil
                for temp in visibleIcons {
                    if temp.tag == previousSelectedIndex {
                        oldItem = temp
                    }
                }
                
                if oldItem == nil {
                    //calculate offset between current center view origin and next previous view origin.
                    var offsetX: Float = (Float(previousSelectedIndex) - Float(item?.tag ?? 0)) * Float(item?.frame.size.width ?? 0.0)
                    //add this to the current offset
                    offsetX += Float(contentOffset.x + (tabContainerView?.frame.origin.x ?? 0.0))
                    setContentOffset(CGPoint(x: CGFloat(offsetX), y: 0), animated: true)
                } else {
                    //Use that view if exists
                    var oldX: CGFloat = oldItem?.frame.origin.x ?? 0.0
                    oldX += (tabContainerView?.frame.origin.x ?? 0.0)
                    
                    
                    setContentOffset(CGPoint(x: oldX + ((oldItem?.frame.size.width ?? 0) / 2.0) - (frame.size.width / 2.0), y: 0), animated: true)
                }
                scrollAnimationCheck = true
            }
            //Else, we don't need to scroll, since we are a basic tab bar.
        }
    }
    
    
    //Finished tab change animation
    @objc func didSelectItem() {
        tabBarDelegate?.infiniteTabBar(self, didSelect: selectedItem)
    }

    
  
    // MARK: - Delegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        //Allow the scroll view to work simintaniously with the tap gesture and pull view gesture
        if (gestureRecognizer == panGestureRecognizer || otherGestureRecognizer == panGestureRecognizer) || (gestureRecognizer == singleTapGesture || otherGestureRecognizer == singleTapGesture) {
            return true
        } else {
            return false
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            //Get the item
            //Convert Superview points, to _tabContainerView points. (want the view in the center
            var location = CGPoint(x: frame.size.width / 2.0, y: (frame.size.height / 2.0) + contentOffset.y)
            location.x += contentOffset.x - (tabContainerView?.frame.origin.x ?? 0.0)
            
            let item: InfiniteTabBarItem? = self.item(atLocation: location)
            
            //Convert the item's frame to self
            var itemFrameInSelf: CGRect = item?.frame ?? CGRect.zero
            itemFrameInSelf.origin.x = (item?.frame.origin.x ?? 0.0) + (tabContainerView?.frame.origin.x ?? 0.0)
            
            if contentOffset.x != itemFrameInSelf.origin.x - (frame.size.width / 2.0) + (itemFrameInSelf.size.width / 2.0) {
                setContentOffset(CGPoint(x: itemFrameInSelf.origin.x - (frame.size.width / 2.0) + (itemFrameInSelf.size.width / 2.0), y: 0), animated: true)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //Convert Superview points, to _tabContainerView points. (want the view in the center
        var location = CGPoint(x: frame.size.width / 2.0, y: (frame.size.height / 2.0) + contentOffset.y)
        location.x += contentOffset.x - (tabContainerView?.frame.origin.x ?? 0.0)
        
        let item: InfiniteTabBarItem? = self.item(atLocation: location)
        
        //Convert the item's frame to self
        var itemFrameInSelf: CGRect? = item?.frame
        itemFrameInSelf?.origin.x = (item?.frame.origin.x ?? 0.0) + (tabContainerView?.frame.origin.x ?? 0.0)
        
        let itemFrameInSelfX = itemFrameInSelf?.origin.x ?? 0.0
        let haftFrameWidth = frame.size.width / 2.0
        let itemFrameInSelfWidth = (itemFrameInSelf?.size.width ?? 0.0) / 2.0
        let contentOffsetX = itemFrameInSelfX - haftFrameWidth + itemFrameInSelfWidth
        if contentOffset.x != contentOffsetX {
            setContentOffset(CGPoint(x: contentOffsetX, y: 0), animated: true)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if !scrollAnimationCheck {
            //Update View Controllers
            //Convert Superview points, to _tabContainerView points. (want the view in the center
            var location = CGPoint(x: frame.size.width / 2.0, y: (frame.size.height / 2.0) + contentOffset.y)
            location.x += contentOffset.x - (tabContainerView?.frame.origin.x ?? 0.0)
            
            let item: InfiniteTabBarItem? = self.item(atLocation: location)
            select(item)
        } else {
            scrollAnimationCheck = false
        }
    }
    
}
