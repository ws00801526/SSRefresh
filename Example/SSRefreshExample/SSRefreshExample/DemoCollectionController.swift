//  DemoCollectionController.swift
//  SSRefresh
//
//  Created by  XMFraker on 2019/4/23
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      DemoCollectionController

import UIKit
import SSRefresh

private let reuseIdentifier = "Cell"

class DemoCollectionController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    let colors: [UIColor] = [.red,.blue,.purple,.green,.magenta]
    
    deinit {
        print("collection controller deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: view.frame.width, height: 300)
        let frame = CGRect(x: 0, y: 100, width: view.frame.width, height: 300)
        let collectionView: UICollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        view.addSubview(collectionView)
        
        let header = StateRefreshHeader(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        header.refreshHandler = { header in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                header.endRefresh({ _ in
                    print("end footer refresh")
                })
            })
        }
        header.frame = CGRect(x: 0, y: 0, width: 50.0, height: collectionView.frame.height)
        header.orientation = .horizontal
        collectionView.sr_header = header
        header.backgroundColor = .green

        let footer = RefreshFooter(frame:  CGRect(x: 0, y: 0, width: 50.0, height: collectionView.frame.height))
        footer.refreshHandler = { footer in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                footer.endRefresh({ _ in
                    print("end footer refresh")
                })
            })
        }
        footer.orientation = .horizontal
        collectionView.sr_footer = footer
        footer.backgroundColor = .green
        
        view.backgroundColor  = .white
        collectionView.backgroundColor = .white
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
            collectionView.sr_header?.beginRefreshing()
        })
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        cell.backgroundColor = colors[indexPath.item % colors.count]
        return cell
    }
}
