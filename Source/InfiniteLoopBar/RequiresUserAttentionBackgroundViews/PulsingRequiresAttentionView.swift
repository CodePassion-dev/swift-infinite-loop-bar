//
//  PulsingRequiresAttentionView.swift
//  Swift Infinite Loop Bar
//
//  Created by Huy Duong on 3/17/19.
//  Copyright © 2019 Huy Duong. All rights reserved.
//

import UIKit

class PulsingRequiresAttentionView: InfiniteTabBarRequiresAttentionBackgroundView {
    
    // MARK: - Public Properties
    
    var pulseColor: UIColor? // The color of the pulses.
    var pulseDuration: CGFloat = 0.0 // The duration of a pulse.
    var thickness: CGFloat = 0.0 // The thickness of the chevron.
    var distance: CGFloat = 0.0 // The distance between chevrons.
    
    
    // MARK: - Private Properties
    
    private var leftImportanceLevel: Int = 0
    private var rightImportanceLevel: Int = 0
    private var leftShapeLayer: CAShapeLayer?
    private var rightShapeLayer: CAShapeLayer?
    private var leftMaskView: UIView?
    private var rightMaskView: UIView?
    

    // MARK: - Initialize
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        leftMaskView?.frame = CGRect(x: 0, y: 0, width: frame.size.width / 2.0, height: frame.size.height)
        rightMaskView?.frame = CGRect(x: frame.size.width / 2.0, y: 0, width: frame.size.width / 2.0, height: frame.size.height)
        //Need to recreate the animation with the correct float values.
        createAnimation()
    }
    
    override func showAnimationOnLeftEdge(withImportanceLevel importanceLevel: Int) {
        leftImportanceLevel = importanceLevel
        createAnimation()
    }
    
    override func showAnimationOnRightEdge(withImportanceLevel importanceLevel: Int) {
        rightImportanceLevel = importanceLevel
        createAnimation()
    }
    
    
    // MARK: - Private Methods
    
    func setup() {
        backgroundColor = UIColor.clear
        
        leftMaskView = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width / 2.0, height: frame.size.height))
        rightMaskView = UIView(frame: CGRect(x: frame.size.width / 2.0, y: 0, width: frame.size.width / 2.0, height: frame.size.height))
        leftMaskView?.clipsToBounds = true
        rightMaskView?.clipsToBounds = true
        leftMaskView?.backgroundColor = UIColor.clear
        rightMaskView?.backgroundColor = UIColor.clear
        if let leftMaskView = leftMaskView {
            addSubview(leftMaskView)
        }
        if let rightMaskView = rightMaskView {
            addSubview(rightMaskView)
        }

        leftShapeLayer = CAShapeLayer()
        rightShapeLayer = CAShapeLayer()
        leftShapeLayer?.fillColor = UIColor(red: 0.75, green: 0.24, blue: 0.15, alpha: 0.5).cgColor
        rightShapeLayer?.fillColor = UIColor(red: 0.75, green: 0.24, blue: 0.15, alpha: 0.5).cgColor
        
        if let leftShapeLayer = leftShapeLayer {
            leftMaskView?.layer.addSublayer(leftShapeLayer)
        }
        if let rightShapeLayer = rightShapeLayer {
            rightMaskView?.layer.addSublayer(rightShapeLayer)
        }

        thickness = 1.0
        distance = 5.0

    }

    func setPulseColor(_ pulseColor: UIColor?) {
        leftShapeLayer?.fillColor = pulseColor?.cgColor
        rightShapeLayer?.fillColor = pulseColor?.cgColor
        createAnimation()
    }
    
    func setPulseDuration(_ pulseDuration: CGFloat) {
        self.pulseDuration = pulseDuration
        createAnimation()
    }

    
    func createAnimation() {
        
        //Animation key
        let pulseAnimationKey = "pulseAnimation"
        //Create the new paths
        if leftImportanceLevel == 0 {
            leftShapeLayer?.path = nil
            //Remove the animation if it exists
            if leftShapeLayer?.animation(forKey: pulseAnimationKey) != nil {
                leftShapeLayer?.removeAnimation(forKey: pulseAnimationKey)
            }
        } else {
            //// Bezier Drawing
            var initialX: CGFloat = 0.0
            let pathRef = CGMutablePath()
            
            for _ in 0..<leftImportanceLevel {
                let bezierPath = UIBezierPath()
                bezierPath.move(to: CGPoint(x: initialX + (frame.size.height / 2.0), y: frame.size.height))
                bezierPath.addLine(to: CGPoint(x: initialX, y: frame.size.height / 2.0))
                bezierPath.addLine(to: CGPoint(x: initialX + (frame.size.height / 2.0), y: 0))
                bezierPath.addLine(to: CGPoint(x: initialX + (frame.size.height / 2.0) + thickness, y: 0))
                bezierPath.addLine(to: CGPoint(x: initialX + thickness, y: frame.size.height / 2.0))
                bezierPath.addLine(to: CGPoint(x: initialX + (frame.size.height / 2.0) + thickness, y: frame.size.height))
                bezierPath.addLine(to: CGPoint(x: initialX + (frame.size.height / 2.0), y: frame.size.height))
                bezierPath.close()
                
                pathRef.addPath(bezierPath.cgPath, transform: .identity)
                initialX += distance + thickness
            }
            
            leftShapeLayer?.frame = CGRect(x: 0, y: 0, width: initialX + (frame.size.height / 2.0) + thickness, height: frame.size.height)
            leftShapeLayer?.path = pathRef
            if leftShapeLayer?.animation(forKey: pulseAnimationKey) != nil {
                leftShapeLayer?.removeAnimation(forKey: pulseAnimationKey)
            }
            
            let opacityAnimation = CABasicAnimation()
            opacityAnimation.keyPath = "opacity"
            opacityAnimation.isRemovedOnCompletion = false
            opacityAnimation.duration = 0.3
            opacityAnimation.repeatCount = 1.0
            opacityAnimation.fromValue = NSNumber(value: 0.0)
            opacityAnimation.toValue = NSNumber(value: 1.0)
            
            let postitionAnimation = CABasicAnimation()
            postitionAnimation.keyPath = "position"
            postitionAnimation.isRemovedOnCompletion = false
            postitionAnimation.duration = 1.0
            postitionAnimation.repeatCount = 1.0
            postitionAnimation.fromValue = NSValue(cgPoint: CGPoint(x: leftMaskView?.frame.size.width ?? 0.0, y: frame.size.height / 2.0))
            postitionAnimation.toValue = NSValue(cgPoint: CGPoint(x: -(leftShapeLayer?.frame.size.width ?? 0.0), y: frame.size.height / 2.0))
            postitionAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [opacityAnimation, postitionAnimation]
            animationGroup.duration = 1.0
            animationGroup.repeatCount = MAXFLOAT
            
            leftShapeLayer?.add(animationGroup, forKey: pulseAnimationKey)
        }
        
        if rightImportanceLevel == 0 {
            rightShapeLayer?.path = nil
            
            //Remove the animation if it exists
            if rightShapeLayer?.animation(forKey: pulseAnimationKey) != nil {
                rightShapeLayer?.removeAnimation(forKey: pulseAnimationKey)
            }
        } else {
            
            //// Bezier Drawing
            var initialX: CGFloat = 0.0
            let pathRef = CGMutablePath()
            
            for _ in 0..<rightImportanceLevel {
                let bezierPath = UIBezierPath()
                bezierPath.move(to: CGPoint(x: initialX + thickness, y: frame.size.height))
                bezierPath.addLine(to: CGPoint(x: initialX + (frame.size.height / 2.0) + thickness, y: frame.size.height / 2.0))
                bezierPath.addLine(to: CGPoint(x: initialX + thickness, y: 0))
                bezierPath.addLine(to: CGPoint(x: initialX, y: 0))
                bezierPath.addLine(to: CGPoint(x: initialX + (frame.size.height / 2.0), y: frame.size.height / 2.0))
                bezierPath.addLine(to: CGPoint(x: initialX, y: frame.size.height))
                bezierPath.addLine(to: CGPoint(x: initialX + thickness, y: frame.size.height))
                bezierPath.close()
                
                pathRef.addPath(bezierPath.cgPath, transform: .identity)
                initialX += distance + thickness
            }
            
            rightShapeLayer?.frame = CGRect(x: 0, y: 0, width: initialX + (frame.size.height / 2.0) + thickness, height: frame.size.height)
            rightShapeLayer?.path = pathRef
            
            if rightShapeLayer?.animation(forKey: pulseAnimationKey) != nil {
                rightShapeLayer?.removeAnimation(forKey: pulseAnimationKey)
            }
            
            let opacityAnimation = CABasicAnimation()
            opacityAnimation.keyPath = "opacity"
            opacityAnimation.isRemovedOnCompletion = false
            opacityAnimation.duration = 0.3
            opacityAnimation.repeatCount = 1.0
            opacityAnimation.fromValue = NSNumber(value: 0.0)
            opacityAnimation.toValue = NSNumber(value: 1.0)
            
            let postitionAnimation = CABasicAnimation()
            postitionAnimation.keyPath = "position"
            postitionAnimation.isRemovedOnCompletion = false
            postitionAnimation.duration = 1.0
            postitionAnimation.repeatCount = 1.0
            postitionAnimation.fromValue = NSValue(cgPoint: CGPoint(x: -(rightShapeLayer?.frame.size.width ?? 0.0), y: frame.size.height / 2.0))
            let rightMaskViewX: CGFloat = (rightMaskView?.frame.size.width ?? 0.0) + (rightShapeLayer?.frame.size.width ?? 0.0)
            postitionAnimation.toValue = NSValue(cgPoint: CGPoint(x: rightMaskViewX, y: frame.size.height / 2.0))
            postitionAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [opacityAnimation, postitionAnimation]
            animationGroup.duration = 1.0
            animationGroup.repeatCount = MAXFLOAT
            
            rightShapeLayer?.add(animationGroup, forKey: pulseAnimationKey)
        }
        
    }

}
