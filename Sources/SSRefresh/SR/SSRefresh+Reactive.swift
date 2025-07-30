//
//  SSRefresh+Reactive.swift
//  SSRefresh
//
//  Created by XMFraker on 2020/11/13.
//

import RxSwift
import RxCocoa
import Foundation

private final class RefreshTarget: Disposable {
    
    weak var component: RefreshControl?
    init(_ component: RefreshControl) {
        self.component = component
    }
    
    func dispose() {
        self.component?.completion = nil
        self.component?.refreshAction = nil
        self.component?.endRefresh()
    }
}

public extension Reactive where Base : RefreshControl {

    var state: ControlEvent<RefreshControl.State> {
        
        let source: Observable<RefreshControl.State> = Observable.create { [weak control = self.base] observer -> Disposable in
            guard let control = control else {
                return Disposables.create()
            }

            observer.onNext(.idle)
            control.completion = { observer.onNext($0.state) }
            control.refreshAction = { observer.onNext($0.state) }
            
            return RefreshTarget(control)
        }.takeUntil(deallocated)
        
        return ControlEvent.init(events: source)
    }
}
