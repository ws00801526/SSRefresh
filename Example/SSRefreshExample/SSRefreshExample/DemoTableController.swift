//  DemoTableController.swift
//  SSRefresh
//
//  Created by  XMFraker on 2019/4/19
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      DemoTableController

import UIKit
import SSRefresh

class DemoTableController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    var tableView: UITableView = UITableView(frame: .zero)
    var headerView: UIView = UIView(frame: .zero)
    
    var originContentInset: UIEdgeInsets = .zero {
        didSet { print("originContentInset Changed \(originContentInset)") }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "TableController"

        // using to make adjustedContentInset == contentInset
//        if #available(iOS 11.0, *) { tableView.contentInsetAdjustmentBehavior = .never }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        tableView.contentInset = UIEdgeInsets.init(top: 100, left: 0, bottom: 0, right: 0)
        headerView.frame = CGRect(x: 0, y: -100, width: view.frame.width, height: 100)
        headerView.backgroundColor = .green
        tableView.insertSubview(headerView, at: 0)
        
//        tableView.sr_header = RefreshComponent(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        
        
        let gifHeader = GifRefreshHeader(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        var images = [UIImage]()
        for i in 0...3 {
            guard let image = UIImage(named: "dropdown_loading_0\(i)") else { continue }
            images.append(image)
        }
//        gifHeader.setAnimationInfo((images, 0.3), for: .pulling)
        gifHeader.setAnimationInfo((images, 0.3), for: .refreshing)

        images.removeAll()
        for i in 0...60 {
            guard let image = UIImage(named: "dropdown_anim__000\(i)") else { continue }
            images.append(image)
        }
        gifHeader.setAnimationInfo((images, 6), for: .idle)
        tableView.sr_header = gifHeader
        
        
//        let header = StateRefreshHeader(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
//        tableView.sr_header = header
        tableView.sr_header?.backgroundColor = .red
        tableView.sr_header?.margin = 100
        tableView.sr_header?.refreshHandler = { header in
            print("header refreshing")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                header.endRefresh({ _ in
                    print("end header refresh")
                })
            })
        }
        
        let footer = StateRefreshFooter { footer in
            print("footer refreshing")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                footer.endRefresh({ _ in
                    print("end footer refresh")
                })
            })
        }
//        footer.refreshHandler = { _ in
//            print("footer refreshing")
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
//                self.tableView.sr_footer?.endRefresh({ _ in
//                    print("end footer refresh")
//                })
//            })
//        }
        tableView.sr_footer = footer
        tableView.sr_footer?.backgroundColor = .yellow
    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("content offset \(scrollView.contentOffset)")
//
//        if #available(iOS 11.0, *) {
//            headerView.frame.origin.y = (scrollView.contentOffset.y + (scrollView.adjustedContentInset.top - scrollView.contentInset.top))
//        } else {
//            // Fallback on earlier versions
//        }
////        headerView.frame.origin.y = -100 - scrollView.contentOffset.y
//    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "row \(indexPath.row)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row % 2 == 0 {
            let controller = DemoCollectionController(nibName: nil, bundle: nil)
            navigationController?.pushViewController(controller, animated: true)
        } else {
            let controller = DemoTableViewController(nibName: nil, bundle: nil)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}

private extension Double {
    static var duration: Double { return 0.25 }
}

//extension DemoTableController {
//
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//
//        switch keyPath {
//        case let path where path == "contentOffset":
//            guard let _ = object as? UIScrollView else { return }
//
//            let new = change?[.newKey] as? CGPoint
//            let old = change?[.oldKey] as? CGPoint
//
//            if let chane = change as? [NSKeyValueChangeKey : CGPoint] {
//                print("transform CGPoint success \(chane)")
//            }
//        case let path where path == "state":
//
//            guard let pan = object as? UIGestureRecognizer else { return }
//            guard let scrollView = pan.view as? UIScrollView else { return }
//            if let rawValue = change?[NSKeyValueChangeKey.newKey] as? Int {
//                if let state = UIGestureRecognizer.State(rawValue: rawValue) {
//                    if case .cancelled = state {
//                        scrollView.contentInset = originContentInset
//                    } else if case .failed = state {
//                        scrollView.contentInset = originContentInset
//                    } else if case .ended = state {
//                        var contentInset = originContentInset
//                        contentInset.top += 50.0
//                        UIView.animate(withDuration: 0.25, animations: { scrollView.contentInset = contentInset })
//
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
//                            guard let self = self else { return }
//                            UIView.animate(withDuration: 0.25, animations: { scrollView.contentInset = self.originContentInset })
//                        }
//                    }
//                }
//            }
//            print("state changed \(change ?? [:])")
//        default: break
//        }
//    }
//}
