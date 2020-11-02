//  StateRefresh.swift
//  Pods
//
//  Created by  XMFraker on 2019/4/23
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      StateRefresh

#if canImport(UIKit)

import UIKit

public struct ArrowDirection: RawRepresentable {
    public var rawValue: CGAffineTransform
    public typealias RawValue = CGAffineTransform
    public init(rawValue: ArrowDirection.RawValue) {
        self.rawValue = rawValue
    }
    
    static let up: ArrowDirection = .init(rawValue: .init(rotationAngle: 0.000001 - CGFloat.pi))
    static let down: ArrowDirection = .init(rawValue: .identity)
    static let left: ArrowDirection = .init(rawValue: .init(rotationAngle: 0.000001 - CGFloat.pi * 1.5))
    static let right: ArrowDirection = .init(rawValue: .init(rotationAngle: 0.000001 - CGFloat.pi * 0.5))
    
    public func toggled() -> ArrowDirection {
        if self == .up { return .down }
        else if self == .down { return .up }
        else if self == .left { return .right }
        else if self == .right { return .left }
        else { return self }
    }
}

public protocol ArrowRefresh: class {
    
    var arrowView: UIImageView { get }
    var indicatorView: UIActivityIndicatorView { get }

    func prepareArrowViews()
    func layoutArrowViews(_ center: CGPoint)
    func setArrowDirection(_ inverted: Bool)
    func updateArrowUIIfNeeded(_ state: RefreshComponent.State)
}

public extension ArrowRefresh where Self : RefreshComponent {

    func setArrowDirection(_ inverted: Bool = false) {
        let direction = orientation == .horizontal ? ArrowDirection.right : ArrowDirection.down
        let shouldInverted = (inverted && !(self is RefreshFooter)) || (!inverted && self is RefreshFooter)
        arrowView.transform = shouldInverted ? direction.toggled().rawValue : direction.rawValue
    }

    func prepareArrowViews() {
        
        arrowView.frame.size = CGSize(width: 40.0, height: 40.0)
        arrowView.contentMode = .center
        arrowView.image = UIImage(named: "arrow", in: Bundle(for: RefreshComponent.self), compatibleWith: nil)
        
        addSubview(arrowView)
        addSubview(indicatorView)
    }
    
    func layoutArrowViews(_ center: CGPoint = .zero) {
        arrowView.center = center
        indicatorView.center = center
    }
    
    func updateArrowUIIfNeeded(_ state: RefreshComponent.State) {
        if case .idle = state {
            indicatorView.stopAnimating()
            
            arrowView.isHidden = false
            UIView.animate(withDuration: RefreshComponent.animationDuration) {
                self.setArrowDirection()
            }
        } else if case .pulling = state {
            
            indicatorView.stopAnimating()
            
            arrowView.isHidden = false
            UIView.animate(withDuration: RefreshComponent.animationDuration) {
                self.setArrowDirection(true)
            }
        } else if case .refreshing = state {
            arrowView.isHidden = true
            setArrowDirection()
            indicatorView.startAnimating()
        }
    }
}

public protocol StateRefresh: class {
    
    var stateLabel: UILabel { get }
    var titles: [RefreshComponent.State : String] { get set }
    
    func prepareStateViews()
    func layoutStateViews()
    
    func updateStateUIIfNeeded(_ state: RefreshComponent.State)
    
    func setTitle(_ title: String, for state: RefreshComponent.State)
    func setTitle(_ key: Language.Key, for state: RefreshComponent.State)
}

public extension StateRefresh where Self : RefreshComponent {
    
    func updateStateUIIfNeeded(_ state: RefreshComponent.State) {
        guard let text = titles[state], text != stateLabel.text else { return }
        stateLabel.text = text
        stateLabel.sizeToFit()
        setNeedsLayout()
    }
    
    func prepareStateViews() {
        addSubview(stateLabel)
    }
    
    func layoutStateViews() {
        if case .horizontal = orientation {
            stateLabel.numberOfLines = 0
            stateLabel.frame.size = CGSize(width: (frame.width - 16), height: min(max(120.0, stateLabel.frame.height), (frame.height - 120.0)))
            stateLabel.center = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
        } else {
            stateLabel.numberOfLines = 1
            stateLabel.frame.size = CGSize(width: min(max(120.0, stateLabel.frame.width), (frame.width - 120.0)), height: (frame.height - 16))
            stateLabel.center = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
        }
    }
    
    func setTitle(_ key: Language.Key, for state: RefreshComponent.State) {
        setTitle(key.locaizedString, for: state)
    }
    
    func setTitle(_ title: String, for state: RefreshComponent.State) {
        titles[state] = title
        if state == self.state { updateStateUIIfNeeded(state) }
    }
}

public class StateRefreshHeader: RefreshHeader, StateRefresh, ArrowRefresh {

    public var titles: [RefreshComponent.State : String] = [:]
    public let stateLabel = RefreshComponent.createLabel()
    public let arrowView: UIImageView = UIImageView(frame: .zero)
    public let indicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)

    public override func prepare() {
        super.prepare()
        prepareStateViews()
        prepareArrowViews()
        setTitle(.HeaderIdleText, for: .idle)
        setTitle(.HeaderReadyText, for: .pulling)
        setTitle(.HeaderRefreshingText, for: .refreshing)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutStateViews()
        if case .horizontal = orientation {
            let y = stateLabel.center.y - stateLabel.frame.height * 0.5 - 30.0
            layoutArrowViews(CGPoint(x: stateLabel.center.x, y: y))
        } else {
            let x = stateLabel.center.x - stateLabel.frame.width * 0.5 - 30.0
            layoutArrowViews(CGPoint(x: x, y: stateLabel.center.y))
        }
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let _ = newSuperview else { return }
        updateArrowUIIfNeeded(.idle)
    }
    
    public override func setState(_ state: RefreshComponent.State, animated: Bool = true) {
        super.setState(state, animated: animated)
        updateStateUIIfNeeded(state)
        updateArrowUIIfNeeded(state)
    }
    
    public func setTitle(_ title: String, for state: RefreshComponent.State) {
        titles[state] = title
        if state == self.state { updateStateUIIfNeeded(state) }
    }
}

public class StateRefreshFooter: RefreshFooter, StateRefresh, ArrowRefresh {
    
    public var titles: [RefreshComponent.State : String] = [:]
    public let stateLabel = RefreshComponent.createLabel()
    public let arrowView: UIImageView = UIImageView(frame: .zero)
    public let indicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    public override func prepare() {
        super.prepare()
        prepareStateViews()
        prepareArrowViews()
        setTitle(.FooterIdleText, for: .idle)
        setTitle(.FooterReadyText, for: .pulling)
        setTitle(.FooterRefreshingText, for: .refreshing)
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let _ = newSuperview else { return }
        updateArrowUIIfNeeded(.idle)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutStateViews()
        if case .horizontal = orientation {
            let y = stateLabel.center.y - stateLabel.frame.height * 0.5 - 30.0
            layoutArrowViews(CGPoint(x: stateLabel.center.x, y: y))
        } else {
            let x = stateLabel.center.x - stateLabel.frame.width * 0.5 - 30.0
            layoutArrowViews(CGPoint(x: x, y: stateLabel.center.y))
        }
    }
    
    public override func setState(_ state: RefreshComponent.State, animated: Bool = true) {
        super.setState(state, animated: animated)
        updateStateUIIfNeeded(state)
        updateArrowUIIfNeeded(state)
    }
}

#endif
