//
//  PanGestureRecognizer.swift
//  Swift Infinite Loop Bar
//
//  Created by Huy Duong on 3/17/19.
//  Copyright © 2019 Huy Duong. All rights reserved.
//

import UIKit

class PanGestureRecognizer: UIPanGestureRecognizer {
    
    // MARK: - Public Properties
    
    enum PanGestureRecognizerDirection : Int {
        case vertical
        case horizontal
    }
    
    var panDirection: PanGestureRecognizerDirection?
    
    
    // MARK: - Private Properties
    
    // Minimum Deviation amount
    private let kPanDirectionThreshold: CGFloat = 10.0
    private var drag = false
    private var moveX: CGFloat = 0.0
    private var moveY: CGFloat = 0.0
    
    
    // MARK: - Initialize
    
    override func reset() {
        super.reset()
        drag = false
        moveX = 0.0
        moveY = 0.0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        if state == .failed {
            return
        }
        let nowPoint: CGPoint? = touches.first?.location(in: view)
        let prevPoint: CGPoint? = touches.first?.previousLocation(in: view)
        moveX += (prevPoint?.x ?? 0.0) - (nowPoint?.x ?? 0.0)
        moveY += (prevPoint?.y ?? 0.0) - (nowPoint?.y ?? 0.0)
        if !drag {
            if abs(moveX) > kPanDirectionThreshold {
                if panDirection == .vertical {
                    state = UIGestureRecognizer.State.failed
                } else {
                    drag = true
                }
            } else if abs(moveY) > kPanDirectionThreshold && moveY > moveX {
                if panDirection == .horizontal {
                    state = UIGestureRecognizer.State.failed
                } else {
                    drag = true
                }
            }
        }
    }

}
