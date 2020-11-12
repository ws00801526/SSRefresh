//
//  SSRefresh.swift
//  SSRefresh
//
//  Created by XMFraker on 2020/10/13.
//

#if canImport(UIKit)

import UIKit

public final class RefreshWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
    
    public var left: RefreshControl? = nil
    public var right: RefreshControl? = nil
    public var top: RefreshControl? = nil
    public var bottom: RefreshControl? = nil
    
    public var header: RefreshControl? { return top ?? left }
    public var footer: RefreshControl? { return bottom ?? right }
}

extension UIScrollView {
    
    fileprivate func addRefresh(_ refresh: RefreshControl, on position: RefreshControl.Position) {
        switch position {
        case .top: sr.top = refresh
        case .bottom: sr.bottom = refresh
        case .left: sr.left = refresh
        case .right: sr.right = refresh
        }
        addSubview(refresh)
    }
    
   public var sr: RefreshWrapper<UIScrollView> {
        if let sr = objc_getAssociatedObject(self, &RefreshControl.Keys.sr) as? RefreshWrapper<UIScrollView> { return sr }
        let sr = RefreshWrapper(self)
        objc_setAssociatedObject(self, &RefreshControl.Keys.sr, sr, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return sr
   }
}

public final class RefreshControl: UIView {
    
    public typealias Action = ((RefreshControl) -> Void)
    public var config: Config {
        didSet {
            contentView.show(state, config: config, animated: false)
        }
    }
    public private(set) var state: State = .idle
    public private(set) var contentView: RefreshContentView!
    public var isRefreshing: Bool { return state == .refreshing }
    public var position: Position { return contentView.position }
    public var refreshAction: Action? = nil
    public var completion: Action? = nil

    final public private(set) weak var scrollView: UIScrollView? {
        didSet {
            guard let scrollView = scrollView else { return }
            switch position {
            case .top, .bottom: scrollView.alwaysBounceVertical = true
            case .left, .right: scrollView.alwaysBounceHorizontal = true
            }
        }
    }
    
    private var observers: [AnyObject] = []
    private var isKVOObservered: Bool = false
    
    init(_ contentView: RefreshContentView, config: Config = .default(), action: Action? = nil) {
        self.config = config
        self.contentView = contentView
        self.refreshAction = action
        super.init(frame: self.contentView.contentView.bounds)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("using init(_:config:contentView:action:) insteaded")
    }
    
    private func setup() {
        addSubview(contentView.contentView)
        backgroundColor = contentView.contentView.backgroundColor
        contentView.show(.idle, config: config, animated: false)
        
        let name: Notification.Name = UIDevice.orientationDidChangeNotification
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            self?.setNeedsLayout()
        }
        observers.append(observer)
    }
}

extension RefreshControl {
    struct Keys {
        static var sr: UInt8 = 100
    }
    
    struct KVOs {
        static let contentSize  = "contentSize"
        static let contentOffset = "contentOffset"
    }
}


// MARK: - Override

extension RefreshControl {
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        removeKVOObserver()
        guard let superView = newSuperview as? UIScrollView else { return }
        scrollView = superView
        addKVOObserver()
    }
        
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let superView = superview, !superView.bounds.equalTo(bounds) else { return }
        frame = .init(origin: frame.origin, size: position.size(of: superView))
        contentView.contentView.setNeedsLayout()
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let scrollView = object as? UIScrollView, self.scrollView == scrollView else { return }
        
        switch keyPath {
        case let path where path == KVOs.contentSize:
            self.scrollView(scrollView, contentSizeDidChanged: change)
        case let path where path == KVOs.contentOffset:
            guard !isHidden else { return }
            self.scrollView(scrollView, contentOffsetDidChanged: change)
        default: break
        }
    }
}

// MARK: - KVO & Private

private extension RefreshControl {
    
    func addKVOObserver() {
        
        guard !isKVOObservered            else { return }
        guard let scrollView = scrollView else { return }
        isKVOObservered = true
        let options: NSKeyValueObservingOptions = [.new, .old]
        scrollView.addObserver(self, forKeyPath: KVOs.contentSize, options: options, context: nil)
        scrollView.addObserver(self, forKeyPath: KVOs.contentOffset, options: options, context: nil)
    }
    
    func removeKVOObserver() {
        
        guard isKVOObservered             else { return }
        guard let scrollView = scrollView else { return }
        isKVOObservered = false
        scrollView.removeObserver(self, forKeyPath: KVOs.contentSize)
        scrollView.removeObserver(self, forKeyPath: KVOs.contentOffset)
    }
    
    func adjustContentInset(_ isHovering: Bool = false) {
        
        guard config.isHoveringEnabled    else { return }
        guard let scrollView = scrollView else { return }
        let multiple: CGFloat = isHovering ? 1.0 : -1.0
        switch position {
        case .top: scrollView.contentInset.top += ((bounds.height + config.contentInsetMargin) * multiple)
        case .left: scrollView.contentInset.left += ((bounds.width + config.contentInsetMargin) * multiple)
        case .right: scrollView.contentInset.right += ((bounds.width + config.contentInsetMargin) * multiple)
        case .bottom: scrollView.contentInset.bottom += ((bounds.height + config.contentInsetMargin) * multiple)
        }
    }
    
    func scrollView(_ scrollView: UIScrollView, contentSizeDidChanged change: [NSKeyValueChangeKey : Any]?) {
        
        guard let old = change?[.oldKey] as? CGSize else { return }
        guard let new = change?[.newKey] as? CGSize else { return }
        guard old != new                            else { return }
        
        // update origin after content size changed
        switch position {
        case .top: frame.origin = .init(x: 0.0, y: -bounds.height - config.contentInsetMargin)
        case .left: frame.origin = .init(x: -bounds.width - config.contentInsetMargin, y: 0.0)
        case .right: frame.origin = .init(x: new.width + config.contentInsetMargin, y: 0.0)
        case .bottom: frame.origin = .init(x: 0.0, y: new.height + scrollView.sr_contentInset.bottom + config.contentInsetMargin)
        }
        
        // auto hidden if content frame is insufficient
        guard config.automaticHiddenWhileContentFrameInsufficient else { return }
        if case .bottom = position { isHidden = scrollView.contentSize.height < scrollView.bounds.inset(by: scrollView.sr_contentInset).height }
        else if case .right = position { isHidden = scrollView.contentSize.width < scrollView.bounds.width }
    }

    /// Calculate offSet\happenOffset\criticalOffset from scrollView
    /// - Parameter scrollView: the scrollView is scrolling
    /// - Returns: offset: the offset of scrollView, happenOffset: the offset of initial & the refresh will be visible, criticalOffset: the offset will be triggered
    func calculateOffset(of scrollView: UIScrollView) -> (offset: CGFloat, happenOffset: CGFloat, criticalOffset: CGFloat) {
        let isHorizontal = position.isHorizontal
        let offset = isHorizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y
        let originalContentInset = scrollView.sr_contentInset
        switch position {
        case .top, .left:
            var happenOffset = isHorizontal ? -originalContentInset.left : -originalContentInset.top
            // minus the config.contentInsetMargin
            happenOffset -= config.contentInsetMargin
            let criticalOffset = happenOffset - (isHorizontal ? frame.width : frame.height) - config.readyOffset
            return (offset, happenOffset, criticalOffset)
        case .bottom, .right:
            var happenOffset = (isHorizontal ? scrollView.contentSize.width : scrollView.contentSize.height)
            // minus the height or width of scrollView
            happenOffset -= (isHorizontal ? scrollView.frame.width : scrollView.frame.height)
            // plus the originalContentInset
            happenOffset += (isHorizontal ? originalContentInset.right : originalContentInset.bottom)
            // plus the config.contentInsetMargin
            happenOffset += config.contentInsetMargin
            let criticalOffset = happenOffset + (isHorizontal ? frame.width : frame.height) + config.readyOffset
            return (-offset, -happenOffset, -criticalOffset)
        }
    }
    
    func scrollView(_ scrollView: UIScrollView, contentOffsetDidChanged change: [NSKeyValueChangeKey : Any]?) {
        
        guard state != .refreshing, state != .emptyData else { return }
        let (offset, happenOffset, criticalOffset) = calculateOffset(of: scrollView)
        if scrollView.isDragging {
            if offset > happenOffset {
                setState(.idle)
            } else if offset < criticalOffset {
                setState(.ready)
            } else {
                let percent = Float((offset - happenOffset) / (criticalOffset - happenOffset)).rounded(numberOfDecimalPlaces: 2)
                guard percent >= 0.0 else { return }
                setState(.pulling(percent: percent))
            }
        } else {
            if case .ready = state {
                setState(.refreshing)
            } else if state != .idle {
                setState(.idle)
            }
        }
    }
}
 

public extension RefreshControl {
        
    enum Position { case top, left, right, bottom }
    
    enum State {
        case idle
        case ready
        case pulling(percent: Float)
        case refreshing
        case emptyData
    }
    
    struct Config {
        public struct Text {
            public var idle: String? = Language.Key.HeaderIdleText.locaizedString
            public var ready: String? = Language.Key.HeaderReadyText.locaizedString
            public var pulling: String? = Language.Key.HeaderIdleText.locaizedString
            public var refreshing: String? = Language.Key.HeaderRefreshingText.locaizedString
            public var emptyData: String? = Language.Key.FooterEmptyText.locaizedString
            
            public static func header() -> Text {
                return .init(idle: Language.Key.HeaderIdleText.locaizedString,
                             ready: Language.Key.HeaderReadyText.locaizedString,
                             pulling: Language.Key.HeaderIdleText.locaizedString,
                             refreshing: Language.Key.HeaderRefreshingText.locaizedString)
            }

            public static func footer() -> Text {
                return .init(idle: Language.Key.FooterIdleText.locaizedString,
                             ready: Language.Key.FooterReadyText.locaizedString,
                             pulling: Language.Key.FooterIdleText.locaizedString,
                             refreshing: Language.Key.FooterRefreshingText.locaizedString,
                             emptyData: Language.Key.FooterEmptyText.locaizedString)
            }
        }
        
        public var text: Text = .header()
        /// The refresh should be hover while it's refreshing
        public var isHoveringEnabled = true
        /// The refresh should be auto hidden while content frame is insufficient
        public var automaticHiddenWhileContentFrameInsufficient = true
        /// The refresh offset of
        public var readyOffset: CGFloat = 5.0
        /// The refresh content view margin with scrollView.
        public var contentInsetMargin: CGFloat = .zero
        /// The animation duration while refresh becoming hovering
        public var animationDuration: TimeInterval = 0.3

        public static func `default`(of position: Position = .top) -> Config {
            if position.isHeader { return .init(text: .header()) }
            return .init(text: .footer())
        }
    }
}

public extension RefreshControl {

    /// Begin refresh manually
    ///
    /// This method should be call in main thread, otherwise it's will do nothing
    func beginRefresh() {
        guard Thread.isMainThread else { return }
        if let _ = superview, let _ = scrollView {
            setState(.refreshing)
        } else {
            setState(.ready)
        }
    }
    
    /// End refresh manually
    func endRefresh() {
        setState(.idle)
    }

    func endRefreshWithEmptyData() {
        setState(.emptyData)
    }
    
    func resetEmptyData() {
        setState(.idle)
    }

    func setState(_ state: State, animated: Bool = true) {

        DispatchQueue.main.async { [weak self] in
            
            guard let `self` = self                else { return }
            guard self.state != state              else { return }
            guard let scrollView = self.scrollView else { return }
            
            var oldState: State = self.state
            (oldState, self.state) = (self.state, state)
//            debugPrint("will set new state \(state) from \(oldState)")
            let duration = animated ? self.config.animationDuration : TimeInterval.leastNormalMagnitude
            if [State.idle, .emptyData].contains(state), case .refreshing = oldState {
                // restore contentInset while state change to .idle from refreshing
                self.contentView.show(state, config: self.config, animated: animated)
                UIView.animate(withDuration: self.config.animationDuration, delay: duration, options: .curveEaseInOut) {
                    self.adjustContentInset(false)
                } completion: { _ in
                    if let completion = self.completion { completion(self) }
                }
            } else if case .refreshing = state, scrollView.panGestureRecognizer.state != .cancelled {
                self.contentView.show(state, config: self.config, animated: animated)
                UIView.animate(withDuration: duration, animations: {
                    self.adjustContentInset(true)
                    
                    // display header if invisiable after call beginRefresh(:), only available if it's a header refresh
                    guard [Position.top, .left].contains(self.position) else { return }
                    let offset = self.position.isHorizontal ? -scrollView.sr_contentInset.left : -scrollView.sr_contentInset.top
                    let contentOffset = (self.position.isHorizontal ? CGPoint(x: offset, y: 0) :  CGPoint(x: 0, y: offset))
                    scrollView.setContentOffset(contentOffset, animated: false)
                }) { _ in
                    if let action = self.refreshAction { action(self) }
                }
            } else {
                guard self.state != .emptyData else { return }
                self.contentView.show(state, config: self.config, animated: animated)
            }
        }
    }
}

extension RefreshControl.State : Equatable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.ready, .ready): return true
        case (.emptyData, .emptyData): return true
        case (.refreshing, .refreshing): return true
        case (.pulling(let lpercent), .pulling(percent: let rpercent)): return lpercent == rpercent
        default: return false
        }
    }
}

extension RefreshControl.Position {
        
    var isHorizontal: Bool {
        switch self {
        case .left, .right: return true
        case .top, .bottom: return false
        }
    }
    
    var isHeader: Bool {
        switch self {
        case .top, .left: return true
        case .bottom, .right: return false
        }
    }
    
    func size(of superView: UIView? = nil) -> CGSize {
        switch self {
        case .left, .right: return .init(width: 50.0, height: superView?.bounds.height ?? UIScreen.main.bounds.height)
        case .top, .bottom: return .init(width: superView?.bounds.width ?? UIScreen.main.bounds.width, height: 50.0)
        }
    }
}

extension RefreshWrapper where Base : UIScrollView {
    
    @discardableResult
    public func addRefresh(on position: RefreshControl.Position, config: RefreshControl.Config? = nil, contentView: RefreshContentView? = nil, action: RefreshControl.Action? = nil) -> RefreshControl {
        let contentView = contentView ?? RefreshControl.DefaultView.init(position: position)
        let control = RefreshControl(contentView, config: config ?? .default(of: position), action: action)
        base.addRefresh(control, on: position)
        return control
    }
}

private extension BinaryFloatingPoint {
    /// SwifterSwift: Returns a rounded value with the specified number of decimal places and rounding rule. If `numberOfDecimalPlaces` is negative, `0` will be used.
    ///
    ///     let num = 3.1415927
    ///     num.rounded(numberOfDecimalPlaces: 3, rule: .up) -> 3.142
    ///     num.rounded(numberOfDecimalPlaces: 3, rule: .down) -> 3.141
    ///     num.rounded(numberOfDecimalPlaces: 2, rule: .awayFromZero) -> 3.15
    ///     num.rounded(numberOfDecimalPlaces: 4, rule: .towardZero) -> 3.1415
    ///     num.rounded(numberOfDecimalPlaces: -1, rule: .toNearestOrEven) -> 3
    ///
    /// - Parameters:
    ///   - numberOfDecimalPlaces: The expected number of decimal places.
    ///   - rule: The rounding rule to use.
    /// - Returns: The rounded value.
    func rounded(numberOfDecimalPlaces: Int, rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> Self {
        let factor = Self(pow(10.0, Double(max(0, numberOfDecimalPlaces))))
        return (self * factor).rounded(rule) / factor
    }
}

#endif
