//  RefreshComponent.swift
//  Pods
//
//  Created by  XMFraker on 2019/4/19
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      RefreshComponent

#if canImport(UIKit)

import UIKit

open class RefreshComponent: UIView {

    public enum State {
        
        case idle
        case pulling
        case willRefresh
        case refreshing
        case empty
    }
    
    public enum Orientation {
        case vertical
        case horizontal
    }
    
    public typealias RefreshHandler = (RefreshComponent) -> Void

    private var isObserverRegistered: Bool = false

    /// Component State
    final public private(set) var state: State = .idle
    final public private(set) weak var scrollView: UIScrollView?
    final public var originalInsets: UIEdgeInsets = .zero
    /// Pulling percent of the component, should be [0...1]
    final public private(set) var pullingPercent: Float = .zero
    /// Component margin, Default is .zero
    final public var margin: CGFloat = .zero {
        didSet {
            guard let _ = self.scrollView else { return }
            DispatchQueue.main.async { self.setNeedsLayout() }
        }
    }
    
    /// Component direction, Default is .vertifcal
    final public var orientation: Orientation = .vertical {
        didSet {
            guard let _ = self.scrollView else { return }
            DispatchQueue.main.async { self.setNeedsLayout() }
        }
    }
    
    /// handler called when state changed to .refreshing
    final public var refreshHandler: RefreshHandler?
    /// handler called before refreshHandler
    final public var beginHandler: RefreshHandler?
    /// handler claled when state changed to .idle from .refreshing
    final public var endHandler: RefreshHandler?
    /// Determined is refreshing
    public var isRefreshing: Bool { return state == .refreshing || state == .willRefresh }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeObservers()
    }
    
    /// Subclass can override this to add subView
    open func prepare() {
        backgroundColor = .white
    }
    
    
    /// Update percent
    ///
    /// - Parameter percent: the percent
    open func setPullingPercent(_ percent: Float = 0.0) {
        self.pullingPercent = percent
    }
    
    /// Update state and called setNeedsLayout
    ///
    /// - Parameters:
    ///   - state: the state
    ///   - animated: Determind should be animated
    open func setState(_ state: State, animated: Bool = true) {
        self.state = state
        DispatchQueue.main.async { self.setNeedsLayout() }
    }

    /// Begin refreshing manually
    ///
    /// - Parameter handler: the begin handler
    final public func beginRefreshing(_ handler: RefreshHandler? = nil) {
        
        guard Thread.isMainThread else { return }
        
        UIView.animate(withDuration: 0.25, animations: { self.alpha = 1.0 })
        
        self.beginHandler = handler
        if let _ = self.window {
            self.setState(.refreshing)
        } else if self.state != .refreshing {
            self.setState(.willRefresh)
        }
    }
    
    
    /// End refreshing manually, call this method when you need to end the refresh
    ///
    /// - Parameter handler: the end handler
    final public func endRefresh(_ handler: RefreshHandler? = nil) {
        self.endHandler = handler
        DispatchQueue.main.async { self.setState(.idle) }
    }
    
    final internal func executeRefreshHandler(_ begin: Bool = true) {
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            if begin, let handler = self.beginHandler   { handler(self) }
            if begin, let handler = self.refreshHandler { handler(self) }
            if !begin, let handler = self.endHandler    { handler(self) }
        }
    }
    
    /// Rewrite the method when subclass need to cares about scrollView content size changes
    open func scrollView(_ scrollView: UIScrollView, contentSizeDidChange change: [NSKeyValueChangeKey : CGSize]) { }
    
    /// Rewrite the method when subclass need to cares about scrollView content offset changes
    open func scrollView(_ scrollView: UIScrollView, contentOffsetDidChange change: [NSKeyValueChangeKey : CGPoint]) { }
    
    /// Rewrite the method when subclass need to cares about scrollView.panGesture.state changes
    open func scrollView(_ scrollView: UIScrollView, panStateDidChange change: [NSKeyValueChangeKey : UIGestureRecognizer.State]) { }
}

public extension RefreshComponent {
    
    static let animationDuration: TimeInterval = 0.25
    static let size: CGSize = CGSize(width: UIScreen.main.bounds.width, height: 50.0)
    
    
    /// Convenience method
    ///
    /// - Parameter handler: the refresh handler
    convenience init(_ handler: @escaping RefreshHandler) {
        self.init(frame: CGRect(origin: .zero, size: RefreshComponent.size))
        self.refreshHandler = handler
    }
}

internal struct ObserveredKeys {
    static let state         = "state"
    static let size          = "contentSize"
    static let offset        = "contentOffset"
}

internal struct AssociatedKeys {
    static var header: Int = 100
    static var footer: Int = 200
}

// MARK: add & remove observer of scrollView

internal extension RefreshComponent {
    
    func addObservers() {
        guard !isObserverRegistered            else { return }
        guard let scrollView = self.scrollView else { return }
        
        isObserverRegistered = true
        scrollView.addObserver(self, forKeyPath: ObserveredKeys.size, options: [.new, .old], context: nil)
        scrollView.addObserver(self, forKeyPath: ObserveredKeys.offset, options: [.new, .old], context: nil)
        scrollView.panGestureRecognizer.addObserver(self, forKeyPath: ObserveredKeys.state, options: [.new, .old], context: nil)
    }
    
    func removeObservers() {
        guard isObserverRegistered             else { return }
        guard let scrollView = self.scrollView else { return }
        
        isObserverRegistered = false
        scrollView.removeObserver(self, forKeyPath: ObserveredKeys.size)
        scrollView.removeObserver(self, forKeyPath: ObserveredKeys.offset)
        scrollView.panGestureRecognizer.removeObserver(self, forKeyPath: ObserveredKeys.state)
    }
}

// MARK: Override super view methods

extension RefreshComponent {
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if let _ = newSuperview {
            
            guard let scrollView = newSuperview as? UIScrollView else { return }
            
            removeObservers()

            self.scrollView  = scrollView
            
            // resize self.frame
            if case .horizontal = orientation {
                scrollView.alwaysBounceHorizontal = true
                frame.size.height = scrollView.frame.height
            } else {
                scrollView.alwaysBounceVertical = true
                frame.size.width = scrollView.frame.width
            }

            backgroundColor  = scrollView.backgroundColor
            originalInsets = scrollView.sr_contentInset
    
            addObservers()
        } else {
            removeObservers()
        }
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        guard isUserInteractionEnabled else { return }

        if let path = keyPath, path == ObserveredKeys.size {
            guard let scrollView = object as? UIScrollView else { return }
            let new = (change?[.newKey] as? CGSize) ?? .zero
            let old = (change?[.oldKey] as? CGSize) ?? .zero
            self.scrollView(scrollView, contentSizeDidChange: [NSKeyValueChangeKey.newKey : new, .oldKey : old])
        }
        
        guard !isHidden else { return }
        
        switch keyPath {
        case let path where path == ObserveredKeys.state:
            guard let scrollView = (object as? UIGestureRecognizer)?.view as? UIScrollView else { return }
            let new = UIGestureRecognizer.State(rawValue: ((change?[.newKey] as? Int) ?? 0)) ?? .possible
            let old = UIGestureRecognizer.State(rawValue: ((change?[.newKey] as? Int) ?? 0)) ?? .possible
            self.scrollView(scrollView, panStateDidChange: [NSKeyValueChangeKey.newKey : new, .oldKey : old])
        case let path where path == ObserveredKeys.offset:
            guard let scrollView = object as? UIScrollView else { return }
            let new = (change?[.newKey] as? CGPoint) ?? .zero
            let old = (change?[.oldKey] as? CGPoint) ?? .zero
            self.scrollView(scrollView, contentOffsetDidChange: [NSKeyValueChangeKey.newKey : new, .oldKey : old])
        default: break
        }
    }
}

public extension UIScrollView {
    
    var sr_header: RefreshComponent? {
    
        get { return objc_getAssociatedObject(self, &AssociatedKeys.header) as? RefreshComponent }
        
        set {
            if let old = sr_header { old.removeFromSuperview() }
            if let new = newValue { insertSubview(new, at: 0) }
            objc_setAssociatedObject(self, &AssociatedKeys.header, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var sr_footer: RefreshComponent? {
        
        get { return objc_getAssociatedObject(self, &AssociatedKeys.footer) as? RefreshComponent }
        
        set {
            if let old = sr_footer { old.removeFromSuperview() }
            if let new = newValue  { insertSubview(new, at: 0) }
            objc_setAssociatedObject(self, &AssociatedKeys.footer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension RefreshComponent {
    
    static func createLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.textColor = .darkText
        label.font = .systemFont(ofSize: 14.0)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = 200
        return label
    }
}

#endif
