/*
 RunnerLayer.swift
 UserInterface

 Created by Takuto Nakamura on 2026/05/08.
 Copyright 2026 Kyome22 (Takuto Nakamura)

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import AppKit

final class RunnerLayer: CALayer {
    private var gap: CGFloat
    private let maskLayer = CALayer()
    private let fillLayer = CALayer()
    private var keyFrameAnimation = CAKeyframeAnimation(keyPath: "contents")
    private var fillColor: CGColor?
    private var ramFillLevel = Int.zero

    init(gap: CGFloat) {
        self.gap = gap
        super.init()
        contentsGravity = CALayerContentsGravity.left
        masksToBounds = true
        contentsScale = 2.0
        maskLayer.frame = bounds
        fillLayer.isHidden = true
        addSublayer(fillLayer)
        keyFrameAnimation.calculationMode = .discrete
        keyFrameAnimation.repeatCount = .infinity
        keyFrameAnimation.isRemovedOnCompletion = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setFrames(_ frames: [NSImage], _ isTemplate: Bool) {
        let size = frames.first?.alignmentRect.size ?? .zero
        keyFrameAnimation.values = frames
        keyFrameAnimation.duration = Double(frames.count) / 2.0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        removeAllAnimations()
        maskLayer.removeAllAnimations()
        frame = CGRect(origin: CGPoint(x: gap, y: 2.0), size: size)
        maskLayer.frame = CGRect(origin: .zero, size: size)
        updateRamFill()
        if isTemplate {
            if mask == nil {
                maskLayer.speed = speed
            }
            timeOffset = .zero
            beginTime = .zero
            speed = 1.0
            mask = maskLayer
            maskLayer.add(keyFrameAnimation, forKey: "running")
        } else {
            if mask != nil {
                speed = maskLayer.speed
            }
            mask = nil
            add(keyFrameAnimation, forKey: "running")
        }
        CATransaction.commit()
    }

    func setColor(_ tintColor: CGColor, _ isTemplate: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundColor = isTemplate ? tintColor : nil
        CATransaction.commit()
    }

    func setSpeed(_ speed: Float) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if mask == nil {
            timeOffset = convertTime(CACurrentMediaTime(), from: nil)
            beginTime = CACurrentMediaTime()
            self.speed = speed
        } else {
            maskLayer.timeOffset = maskLayer.convertTime(CACurrentMediaTime(), from: nil)
            maskLayer.beginTime = CACurrentMediaTime()
            maskLayer.speed = speed
        }
        CATransaction.commit()
    }

    func setRamFillState(_ level: Int, _ color: CGColor?) {
        ramFillLevel = level
        fillColor = color
        updateRamFill()
    }

    private func updateRamFill() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let fillHeight = bounds.height * CGFloat(ramFillLevel) / 20.0
        fillLayer.backgroundColor = fillColor
        // Sublayers of the status bar button resolve y from the top, so the fill
        // rect is anchored to the visually bottom edge by offsetting its origin.
        fillLayer.frame = CGRect(
            origin: CGPoint(x: .zero, y: bounds.height - fillHeight),
            size: CGSize(width: bounds.width, height: fillHeight)
        )
        fillLayer.isHidden = fillColor == nil || ramFillLevel == .zero || mask == nil
        CATransaction.commit()
    }
}
