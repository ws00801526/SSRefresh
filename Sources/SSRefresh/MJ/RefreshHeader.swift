//  RefreshHeader.swift
//  Pods
//
//  Created by  XMFraker on 2019/4/19
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      RefreshHeader

#if canImport(UIKit)

import UIKit

open class RefreshHeader: RefreshComponent {
    
    /// update frame.origin base on orientation
    private func adjustOrigin() {
        if case .horizontal = orientation { frame.origin.x = -frame.width - margin }
        else { frame.origin.y = -frame.height - margin }
    }
    
    /// update scrollView.contentInset base on orientation
    private func adjustContentInset(fixed: Bool) {

        let value = (self.orientation == .horizontal ? self.frame.width : self.frame.height)
        if case .horizontal = orientation {
            self.scrollView?.contentInset.left += (value * (fixed ? 1.0 : -1.0))
        } else {
            self.scrollView?.contentInset.top += (value * (fixed ? 1.0 : -1.0))
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        adjustOrigin()
    }
    
    open override func setState(_ state: State, animated: Bool = true) {
        
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
                    // display header if its invisiable after call beginRefresh(:)
                    let offset = self.orientation == .horizontal ? -scrollView.sr_contentInset.left : -scrollView.sr_contentInset.top
                    let contentOffset = (self.orientation == .horizontal ? CGPoint(x: offset, y: 0) :  CGPoint(x: 0, y: offset))
                    scrollView.setContentOffset(contentOffset, animated: false)
                }) { _ in
                    self.executeRefreshHandler()
                }
            }
        }
    }
    
    open override func scrollView(_ scrollView: UIScrollView, contentOffsetDidChange change: [NSKeyValueChangeKey : CGPoint]) {
        
        super.scrollView(scrollView, contentOffsetDidChange: change)
        
        guard state != .refreshing    else { return }

        let offset = orientation == .horizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y
        let happenOffset = orientation == .horizontal ? -scrollView.sr_contentInset.left : -scrollView.sr_contentInset.top
        guard offset <= happenOffset else { return }

        let criticalOffset = happenOffset - (orientation == .horizontal ? frame.width : frame.height)
        let percent = (happenOffset - offset) / (orientation == .horizontal ? frame.width : frame.height)
        
        if scrollView.isDragging {
            self.setPullingPercent(Float(percent))
            if case .idle = state, offset < criticalOffset {
                self.setState(.pulling)
            } else if case .pulling = state, offset >= criticalOffset {
                self.setState(.idle)
            }
        } else if percent > 1.0, case .pulling = state {
            self.beginRefreshing()
        } else if percent <= 1.0 {
            self.setPullingPercent(Float(percent))
        }
    }
}

#endif
