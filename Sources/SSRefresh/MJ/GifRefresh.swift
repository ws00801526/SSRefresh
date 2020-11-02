//  GifRefresh.swift
//  Pods
//
//  Created by  XMFraker on 2019/4/25
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      GifRefresh

#if canImport(UIKit)

import UIKit

public typealias AnimationInfo = ([UIImage], TimeInterval)
public protocol GifRefresh: StateRefresh {
 
    var gifView: UIImageView { get }
    var animationInfos: [RefreshComponent.State : AnimationInfo] { get }

    func prepareGifViews()
    func layoutGifViews()
    func updateUIIfNeededAfterPullingPercentChanged()
    func updateUIIfNeededAfterStateChanged(_ state: RefreshComponent.State)
    func setAnimationInfo(_ info: AnimationInfo, for state: RefreshComponent.State)
}

public extension GifRefresh where Self : RefreshComponent {
    
    func updateUIIfNeededAfterPullingPercentChanged() {
        
        guard state == .idle else { return }
        
        guard let animateInfo = animationInfos[state] else { return }
        guard animateInfo.0.count > 0 else { return }

        var index = Int(Float(animateInfo.0.count) * pullingPercent)
        if index >= animateInfo.0.count { index = animateInfo.0.count - 1 }
        gifView.image = animateInfo.0[index]
        gifView.sizeToFit()
        setNeedsLayout()
    }
    
    func updateUIIfNeededAfterStateChanged(_ state: RefreshComponent.State) {
        if state == .refreshing || state == .pulling {
            
            guard let animateInfo = animationInfos[state] else { return }
            guard animateInfo.0.count > 0 else { return }
            
            gifView.stopAnimating()
            if (animateInfo.0.count == 0) {
                gifView.image = animateInfo.0.first
            } else {
                gifView.animationImages = animateInfo.0
                gifView.animationDuration = animateInfo.1
                gifView.startAnimating()
            }
        } else {
            gifView.stopAnimating()
        }
        gifView.sizeToFit()
        setNeedsLayout()
    }
    
    
    func prepareGifViews() {
        prepareStateViews()
        addSubview(gifView)
    }
    
    func layoutGifViews() {
        
        layoutStateViews()

        if case .horizontal = orientation {
            let y = stateLabel.center.y - stateLabel.frame.height * 0.5 - 30.0
            if stateLabel.isHidden { gifView.frame = bounds }
            else { gifView.center = CGPoint(x: stateLabel.center.x, y: y) }
        } else {
            let x = stateLabel.center.x - stateLabel.frame.width * 0.5 - 30.0
            if stateLabel.isHidden { gifView.frame = bounds }
            else { gifView.center = CGPoint(x: x, y: stateLabel.center.y) }
        }
    }
}

public class GifRefreshHeader: RefreshHeader, GifRefresh {
    
    public let gifView: UIImageView = UIImageView(frame: .zero)
    public let stateLabel: UILabel = RefreshComponent.createLabel()
    public var animationInfos: [RefreshComponent.State: AnimationInfo] = [:]
    public var titles: [RefreshComponent.State: String] = [:]
    
    public override func prepare() {
        super.prepare()
        prepareGifViews()
        
        setTitle(.HeaderIdleText, for: .idle)
        setTitle(.HeaderReadyText, for: .pulling)
        setTitle(.HeaderRefreshingText, for: .refreshing)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutGifViews()
    }
    
    public override func setPullingPercent(_ percent: Float = 0.0) {
        super.setPullingPercent(percent)
        updateUIIfNeededAfterPullingPercentChanged()
    }
    
    public override func setState(_ state: RefreshComponent.State, animated: Bool = true) {
        super.setState(state, animated: animated)
        updateStateUIIfNeeded(state)
        updateUIIfNeededAfterStateChanged(state)
    }
    
    public func setAnimationInfo(_ info: AnimationInfo, for state: RefreshComponent.State) {
        animationInfos[state] = info
        if state == self.state { updateUIIfNeededAfterStateChanged(state) }
    }
    
    public func setTitle(_ title: String, for state: RefreshComponent.State) {
        titles[state] = title
        if state == self.state { updateStateUIIfNeeded(state) }
    }
}

public class GifRefreshFooter: RefreshFooter, GifRefresh {
    
    public let gifView: UIImageView = UIImageView(frame: .zero)
    public let stateLabel: UILabel = RefreshComponent.createLabel()
    public var animationInfos: [RefreshComponent.State: AnimationInfo] = [:]
    public var titles: [RefreshComponent.State: String] = [:]
    
    public override func prepare() {
        super.prepare()
        prepareGifViews()
        
        setTitle(.FooterIdleText, for: .idle)
        setTitle(.FooterReadyText, for: .pulling)
        setTitle(.FooterRefreshingText, for: .refreshing)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutGifViews()
    }
    
    public override func setPullingPercent(_ percent: Float = 0.0) {
        super.setPullingPercent(percent)
        updateUIIfNeededAfterPullingPercentChanged()
    }
    
    public override func setState(_ state: RefreshComponent.State, animated: Bool = true) {
        super.setState(state, animated: animated)
        updateStateUIIfNeeded(state)
        updateUIIfNeededAfterStateChanged(state)
    }
    
    public func setAnimationInfo(_ info: AnimationInfo, for state: RefreshComponent.State) {
        animationInfos[state] = info
        if state == self.state { updateUIIfNeededAfterPullingPercentChanged() }
    }
    
    public func setTitle(_ title: String, for state: RefreshComponent.State) {
        titles[state] = title
        if state == self.state { updateStateUIIfNeeded(state) }
    }
}

#endif
