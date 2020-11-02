//  RefreshFooter.swift
//  Pods
//
//  Created by  XMFraker on 2019/4/22
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      RefreshFooter

#if canImport(UIKit)

import UIKit

open class RefreshFooter: RefreshComponent {
    
    private func adjustOrigin() {

        func adjustOriginX () {
            guard let scrollView = scrollView else { return }
            let sizeWidth = scrollView.contentSize.width
            let innerMargin = (scrollView.sr_contentInset.left - scrollView.contentInset.left) + margin
            let normalWidth = scrollView.frame.width - scrollView.sr_contentInset.left - scrollView.sr_contentInset.right
            frame.origin.x = max(sizeWidth, normalWidth) + innerMargin
        }
        
        func adjustOriginY() {
            guard let scrollView = scrollView else { return }
            let sizeHeight = scrollView.contentSize.height
            let bottomMargin = (scrollView.sr_contentInset.bottom - scrollView.contentInset.bottom) + margin
            let normalHeight = scrollView.frame.height - scrollView.sr_contentInset.top - scrollView.sr_contentInset.bottom
            frame.origin.y = max(sizeHeight, normalHeight) + bottomMargin
        }
        
        if case .horizontal = orientation { adjustOriginX() }
        else { adjustOriginY() }
    }
    
    /// update scrollView.contentInset base on orientation
    private func adjustContentInset(fixed: Bool) {

        let value = (self.orientation == .horizontal ? self.frame.width : self.frame.height)
        if case .horizontal = orientation {
            self.scrollView?.contentInset.right += (value * (fixed ? 1.0 : -1.0))
        } else {
            self.scrollView?.contentInset.bottom += (value * (fixed ? 1.0 : -1.0))
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        adjustOrigin()
    }
    
    open override func scrollView(_ scrollView: UIScrollView, contentSizeDidChange change: [NSKeyValueChangeKey : CGSize]) {
        super.scrollView(scrollView, contentSizeDidChange: change)
        adjustOrigin()
    }
    
    open override func scrollView(_ scrollView: UIScrollView, contentOffsetDidChange change: [NSKeyValueChangeKey : CGPoint]) {
        super.scrollView(scrollView, contentOffsetDidChange: change)
        
        guard state != .refreshing     else { return }
        
        let offset = orientation == .horizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y
        let happenOffset = orientation == .horizontal ? (frame.origin.x - scrollView.frame.width) : (frame.origin.y - scrollView.frame.height)
        guard offset >= happenOffset else { return }
        
        let criticalOffset = happenOffset + (orientation == .horizontal ? frame.width : frame.height)
        let percent = (offset - happenOffset) / (orientation == .horizontal ? frame.width : frame.height)
        if scrollView.isDragging {
            self.setPullingPercent(Float(percent))
            if case .idle = state, offset > criticalOffset {
                self.setState(.pulling)
            } else if case .pulling = state, offset <= criticalOffset {
                self.setState(.idle)
            }
        } else if percent > 1.0, case .pulling = state {
            self.beginRefreshing()
        } else if percent <= 1.0 {
            self.setPullingPercent(Float(percent))
        }
    }
    
    open override func setState(_ state: RefreshComponent.State, animated: Bool = true) {
        
        // check if the state has changed
        let oldstate = self.state
        guard oldstate != state else { return }
        super.setState(state, animated: animated)
        
        guard let scrollView = self.scrollView else { return }
        let duration = animated ? RefreshComponent.animationDuration : TimeInterval.leastNormalMagnitude

        if case .idle = state, case .refreshing = oldstate {
            // restore contentInset while state change to .idle from refreshing
            UIView.animate(withDuration: duration, animations: {
                self.adjustContentInset(fixed: false)
            }) { _ in
                self.setPullingPercent()
                if let handler = self.endHandler { handler(self) }
            }
        } else if case .refreshing = state, scrollView.panGestureRecognizer.state != .cancelled {
            // set contentInset to display header
            DispatchQueue.main.async {
                UIView.animate(withDuration: duration, animations: {
                    self.adjustContentInset(fixed: true)
                }) { _ in
                    self.executeRefreshHandler()
                }
            }
        }
    }
}

public extension RefreshFooter {
    
    func endRefreshWithEmptyData() {
        DispatchQueue.main.async { self.setState(.empty) }
    }
    
    func resetEmptyData() {
        DispatchQueue.main.async { self.setState(.idle) }
    }
}

#endif
