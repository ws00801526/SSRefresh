//
//  SSRefresh+DefaultView.swift
//  SSRefresh
//
//  Created by XMFraker on 2020/10/14.
//

#if canImport(UIKit)

import UIKit

public protocol RefreshContentView: class {
    var contentView: UIView { get }
    var position: RefreshControl.Position { get }
    func show(_ state: RefreshControl.State, config: RefreshControl.Config, animated: Bool)
    init(position: RefreshControl.Position)
}

public extension RefreshContentView where Self : UIView {
    var contentView: UIView { self }
    func show(_ state: RefreshControl.State, config: RefreshControl.Config, animated: Bool) { }
}

extension RefreshControl {
    open class DefaultView: UIView {
        public var position: RefreshControl.Position = .top
        
        lazy var indicatorView: UIActivityIndicatorView = {
            if #available(iOS 13, *) { return UIActivityIndicatorView(style: .medium) }
            else { return UIActivityIndicatorView(style: .gray) }
        }()
        
        lazy var stateLabel: UILabel = {
            var label = UILabel(frame: CGRect.zero)
            label.font = UIFont.boldSystemFont(ofSize: 14)
            label.textColor = UIColor(white: 0.4, alpha: 1.0)
            label.textAlignment = .center
            label.backgroundColor = UIColor.clear
            label.numberOfLines = position.isHorizontal ? 0 : 1
            label.sizeToFit()
            return label
        }()
        
        lazy var arrowView: UIImageView = {
            var imageView = UIImageView(frame: .init(origin: .zero, size: .init(width: 40, height: 40)))
            imageView.contentMode = .scaleAspectFit
            imageView.image =  UIImage(named: "arrow_down", in: Bundle(for: RefreshControl.self), compatibleWith: nil)
            return imageView
        }()
        
        lazy var stackView: UIStackView = {
            indicatorView.hidesWhenStopped = true
            let stackView = UIStackView(arrangedSubviews: [indicatorView, arrowView, stateLabel])
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = position.isHorizontal ? .vertical : .horizontal
            stackView.distribution = .equalSpacing
            stackView.alignment = .center
            stackView.spacing = 10.0
            stackView.center = center
            return stackView
        }()
        
        required public init(position: RefreshControl.Position = .top) {
            self.position = position
            super.init(frame: .init(origin: .zero, size: position.size()))
            autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(stackView)
            if position.isHorizontal {
                addConstraint(.init(item: stackView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 20.0))
                addConstraint(.init(item: stackView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
                addConstraint(.init(item: stackView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            } else {
                addConstraint(.init(item: stackView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
                addConstraint(.init(item: stackView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            }
        }
        
        public override init(frame: CGRect) {
            fatalError("using init(position:) insteaded")
        }
        
        required public init?(coder: NSCoder) {
            fatalError("using init(position:) insteaded")
        }
    }
}

extension RefreshControl.DefaultView {
    
    /// Set the arrow of arrowView. Default is arrow_down.
    final public var arrow: UIImage? {
        set { arrowView.image = newValue }
        get { arrowView.image }
    }
    
    /// Set the spacing between arrow & state. Default is 10.0
    final public var spacing: CGFloat {
        set { stackView.spacing = newValue }
        get { stackView.spacing }
    }
    
    /// Set the font of stateLabel. Default is .system(14.0)
    final public var font: UIFont {
        set { stateLabel.font = newValue }
        get { stateLabel.font }
    }
    
    /// Set the textColor of stateLabel. Default is .(white: 0.4, alpha: 1.0)
    final public var textColor: UIColor {
        set { stateLabel.textColor = newValue }
        get { stateLabel.textColor }
    }
}

extension RefreshControl.DefaultView : RefreshContentView {

    public func show(_ state: RefreshControl.State, config: RefreshControl.Config, animated: Bool) {

        var newTitle: String? = nil
        var transform: CGAffineTransform? = nil
        switch state {
        case .ready:
            newTitle = config.text.ready
            transform = self.position.toggled().transform
        case .refreshing:
            newTitle = config.text.refreshing
            transform = self.position.transform
        case .idle, .pulling(percent: _):
            newTitle = config.text.idle
            transform = self.position.transform
        case .emptyData:
            newTitle = config.text.emptyData
            transform = self.position.transform
        }
        
        let values = newTitle?.map { String($0) } ?? []
        let title = position.isHorizontal ? values.joined(separator: "\n") : newTitle
        let newInfo = (title: newTitle, isTitleHidden: title?.isEmpty ?? true, isAnimating: state == .refreshing)
        
        // FIXME: do nothing if title is unchanged. it's necessary.
        guard newInfo.title != stateLabel.text else { return }

        (stateLabel.text, stateLabel.isHidden, _) = newInfo
        arrowView.isHidden = newInfo.isAnimating || state == .emptyData

        if newInfo.isAnimating { indicatorView.startAnimating() }
        else { indicatorView.stopAnimating() }

        guard let toTransform = transform else { return }
        if animated { UIView.animate(withDuration: config.animationDuration, animations: { self.arrowView.transform = toTransform  }) }
        else { arrowView.transform = toTransform }
    }
}

private extension RefreshControl.Position {
    var transform: CGAffineTransform {
        switch self {
        case .top: return .identity
        case .left: return .init(rotationAngle: 0.000001 - CGFloat.pi * 1.5)
        case .right: return .init(rotationAngle: 0.000001 - CGFloat.pi * 0.5)
        case .bottom: return .init(rotationAngle: 0.000001 - CGFloat.pi)
        }
    }
    
    func toggled() -> RefreshControl.Position {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .left: return .right
        case .right: return .left
        }
    }
}

#endif
